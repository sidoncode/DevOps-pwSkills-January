# Lab: Terraform Remote State & Locking with S3 + DynamoDB

A hands-on lab that walks you through storing Terraform state in an S3 bucket,
locking it with DynamoDB, **watching the lock work in real time**, recovering a
stuck lock, and (as a bonus) switching to native S3 locking.

You will deploy a single EC2 instance as the workload — small and cheap, so the
focus stays on state and locking.

---

## Learning objectives

By the end of this lab you will be able to:

- Bootstrap an S3 bucket (versioned, encrypted, private) to hold Terraform state
- Create a DynamoDB table that Terraform uses for state locking
- Wire up the `backend "s3"` block and migrate state to the remote backend
- Prove that state is stored remotely and that locking actually blocks concurrent runs
- Inspect a live lock item inside DynamoDB
- Recover from a stuck lock with `force-unlock`
- Switch from DynamoDB locking to native S3 locking (`use_lockfile`)
- Tear everything down cleanly

**Estimated time:** 30–45 minutes
**Estimated cost:** a few cents (t3.micro + pay-per-request DynamoDB), if you complete the teardown.

---

## Prerequisites

| Requirement | Check |
|---|---|
| AWS account with admin-ish permissions (S3, DynamoDB, EC2) | — |
| AWS CLI installed and configured | `aws sts get-caller-identity` |
| Terraform **1.10+** installed | `terraform version` |
| A terminal you can open **twice** (needed for the locking demo) | — |

> Pick a **globally unique** S3 bucket name. Throughout this lab replace
> `my-tf-state-sid-bucket` with your own name (S3 bucket names are unique across
> *all* AWS accounts).

Set a couple of shell variables so the commands are copy-paste friendly:

```bash
export TF_BUCKET="my-tf-state-sid-bucket"   # <-- change to your unique name
export TF_REGION="us-east-1"
export TF_LOCK_TABLE="terraform-locks"
```

---

## Architecture at a glance

```
            terraform apply
                  │
        ┌─────────┴──────────┐
        ▼                    ▼
  ┌───────────┐        ┌──────────────┐
  │  S3       │        │  DynamoDB    │
  │  bucket   │        │  terraform-  │
  │ (state +  │        │  locks       │
  │ versions) │        │ (LockID item)│
  └───────────┘        └──────────────┘
   stores the           prevents two
   state file           applies at once
```

- **S3** = *where the state lives* (durable, versioned, encrypted, shared).
- **DynamoDB** = *the lock* (its conditional writes guarantee only one apply runs at a time).

---

## Part A — Bootstrap the backend infrastructure

These resources must exist **before** Terraform can use them as a backend
(the classic chicken-and-egg problem), so we create them with the AWS CLI.

### A1. Create the S3 bucket

```bash
# us-east-1 is special: do NOT pass a LocationConstraint
aws s3api create-bucket \
  --bucket "$TF_BUCKET" \
  --region "$TF_REGION"
```

> For any other region, add:
> `--create-bucket-configuration LocationConstraint=$TF_REGION`

### A2. Harden the bucket (versioning, encryption, block public access)

```bash
# Versioning — lets you recover a corrupted state file
aws s3api put-bucket-versioning \
  --bucket "$TF_BUCKET" \
  --versioning-configuration Status=Enabled

# Encryption at rest
aws s3api put-bucket-encryption \
  --bucket "$TF_BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block ALL public access
aws s3api put-public-access-block \
  --bucket "$TF_BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### A3. Create the DynamoDB lock table

The partition key **must** be named exactly `LockID` — Terraform looks for that
specific attribute.

```bash
aws dynamodb create-table \
  --table-name "$TF_LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$TF_REGION"
```

Wait for it to become active:

```bash
aws dynamodb wait table-exists --table-name "$TF_LOCK_TABLE" --region "$TF_REGION"
echo "Table is ready."
```

### ✅ Checkpoint A

```bash
aws s3 ls | grep "$TF_BUCKET"
aws dynamodb describe-table --table-name "$TF_LOCK_TABLE" \
  --query "Table.TableStatus" --output text   # should print ACTIVE
```

---

## Part B — Write the Terraform configuration

Create a project folder and three files.

```bash
mkdir tf-state-lab && cd tf-state-lab
```

### B1. `main.tf` — backend + provider

> Note the literal bucket name and table name — the `backend` block **cannot**
> use variables, so these must be hardcoded here.

```hcl
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-tf-state-sid-bucket"   # <-- your unique bucket
    key            = "ec2/terraform.tfstate"    # path of state inside the bucket
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"          # DynamoDB-based state locking
  }
}

provider "aws" {
  region = "us-east-1"
}
```

### B2. `ec2.tf` — the workload

```hcl
# Look up the latest Amazon Linux 2023 AMI instead of hardcoding an ID
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = {
    Name = "tf-state-lab-web"
  }
}
```

### B3. `outputs.tf`

```hcl
output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
```

---

## Part C — Initialize the backend

```bash
terraform init
```

**What you should see:** Terraform reports
`Successfully configured the backend "s3"!` and downloads the AWS provider.
If you had any prior local state it would offer to migrate it — answer `yes`.

### ✅ Checkpoint C

```bash
cat .terraform/terraform.tfstate    # backend pointer; look for "type": "s3"
```

---

## Part D — Apply and confirm remote state

```bash
terraform plan      # review: 1 resource to add
terraform apply     # type 'yes'
```

Now prove the state really lives in S3:

```bash
# State object exists in the bucket
aws s3 ls "s3://$TF_BUCKET/ec2/"

# Terraform reads it back from the remote backend
terraform state list
terraform output
```

### ✅ Checkpoint D

You should see `aws_instance.web` (and the AMI data source) in
`terraform state list`, and `s3 ls` should show `terraform.tfstate`.

---

## Part E — Watch the lock work (the main event)

This is the part that makes locking click. You need **two terminals** in the
same `tf-state-lab` folder.

### E1. Terminal 1 — start a long-running operation

`terraform plan` is too fast to catch the lock, so trigger an apply that pauses
at the approval prompt:

```bash
# Terminal 1 — leave this sitting at the "Do you want to perform..." prompt
terraform apply
```

**Do NOT type yes yet.** While it waits at the prompt, the lock is held.

### E2. Terminal 2 — try to run at the same time

```bash
# Terminal 2 — run while Terminal 1 is still waiting
terraform plan
```

**What you should see** — Terminal 2 refuses to run:

```
│ Error: Error acquiring the state lock
│
│ Lock Info:
│   ID:        a1b2c3d4-e5f6-...
│   Path:      my-tf-state-sid-bucket/ec2/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       you@your-machine
│   Created:   2026-...
```

That is the lock doing its job. The `Who`, `Operation`, and `Created` fields all
come from the lock item DynamoDB is holding for Terminal 1.

### E3. Release it

Go back to Terminal 1 and either type `yes` to apply or `no`/Ctrl-C to cancel.
Either way Terraform deletes the lock item. Re-run Terminal 2 and it works again.

---

## Part F — Inspect the live lock in DynamoDB

Repeat E1 (start an apply in Terminal 1 and pause at the prompt). While it's
paused, look at the table directly from Terminal 2:

```bash
aws dynamodb scan --table-name "$TF_LOCK_TABLE" --region "$TF_REGION"
```

**What you should see:** two items —

1. `LockID = <bucket>/ec2/terraform.tfstate` with an `Info` attribute containing
   the lock JSON (who/operation/created). **This one exists only while locked.**
2. `LockID = <bucket>/ec2/terraform.tfstate-md5` — a permanent checksum of your
   state, *not* a lock; it stays in the table all the time.

Finish or cancel Terminal 1, scan again, and the first item is gone — only the
`-md5` item remains. That disappearance **is** what "released" means.

---

## Part G — Recover a stuck lock

If Terraform crashes mid-apply, the lock item is never deleted and you're stuck.
Simulate and fix it.

1. Start an apply in Terminal 1, pause at the prompt, then **kill it hard**
   (`Ctrl-C` once, then close the terminal — don't let it clean up).
2. In a fresh terminal, any command now errors with a lock. Copy the `ID` from
   the error message.
3. Release it manually:

```bash
terraform force-unlock <LOCK_ID>
# type 'yes' to confirm
```

> ⚠️ Only force-unlock when you are certain no real apply is still running.
> Force-unlocking an active operation is how state gets corrupted.

Verify it's gone:

```bash
aws dynamodb scan --table-name "$TF_LOCK_TABLE" --region "$TF_REGION"
# only the -md5 item should remain
```

---

## Part H (Bonus) — Switch to native S3 locking

Terraform 1.10+ can lock using a file in the bucket itself, removing the need for
DynamoDB entirely.

### H1. Edit the backend block in `main.tf`

Replace the `dynamodb_table` line with `use_lockfile`:

```hcl
  backend "s3" {
    bucket       = "my-tf-state-sid-bucket"
    key          = "ec2/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true     # native S3 locking — no DynamoDB needed
  }
```

### H2. Re-initialize

```bash
terraform init -reconfigure
```

### H3. Observe the new lock mechanism

Repeat the Part E demo. This time, while an apply is paused, a `.tflock` object
appears in the bucket instead of a DynamoDB item:

```bash
aws s3 ls "s3://$TF_BUCKET/ec2/"
# you'll briefly see terraform.tfstate.tflock during the locked operation
```

Once you've confirmed it works, you could safely delete the DynamoDB table.

> Migration tip: to transition a *team* gradually, you can keep **both**
> `use_lockfile = true` and `dynamodb_table` set for a while (Terraform acquires
> both locks), then drop `dynamodb_table` once everyone has upgraded.

---

## Teardown (avoid ongoing charges)

```bash
# 1. Destroy the EC2 instance
terraform destroy        # type 'yes'

# 2. Delete the DynamoDB lock table
aws dynamodb delete-table --table-name "$TF_LOCK_TABLE" --region "$TF_REGION"

# 3. Empty the bucket (versioned buckets need all versions removed) then delete it
aws s3api delete-objects \
  --bucket "$TF_BUCKET" \
  --delete "$(aws s3api list-object-versions \
    --bucket "$TF_BUCKET" \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
    --output json)" 2>/dev/null

aws s3api delete-objects \
  --bucket "$TF_BUCKET" \
  --delete "$(aws s3api list-object-versions \
    --bucket "$TF_BUCKET" \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
    --output json)" 2>/dev/null

aws s3 rb "s3://$TF_BUCKET"
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `BucketAlreadyExists` | Bucket name not globally unique | Pick a more unique name (add account ID / date) |
| `Error acquiring the state lock` when nothing is running | Stuck lock from a crashed run | `terraform force-unlock <ID>` |
| `ResourceNotFoundException` on apply | `dynamodb_table` set but table doesn't exist | Create the table (Part A3) or remove the line |
| Lock table works but key errors | Partition key not named `LockID` | Recreate the table with key `LockID` |
| Backend won't init after editing block | Backend settings changed | `terraform init -reconfigure` (or `-migrate-state`) |
| `dynamodb_table` deprecation warning (TF 1.11+) | HashiCorp now prefers native locking | Harmless; switch to `use_lockfile` when ready |

---

## Summary

| Concept | Takeaway |
|---|---|
| **S3 backend** | Stores state durably; versioning + encryption + private access make it safe and recoverable |
| **DynamoDB locking** | A conditional write creates a `LockID` item; its existence = locked, its deletion = released |
| **Lock info** | The who/operation/created JSON is generated by Terraform and shown on lock conflicts |
| **`-md5` item** | A permanent state checksum, not a lock — don't confuse the two |
| **`force-unlock`** | Manually deletes a stuck lock item; use only when no apply is running |
| **Native S3 locking** | `use_lockfile = true` (TF 1.10+) replaces DynamoDB with a `.tflock` file in the bucket |

You now have a working remote-state setup and have *seen* locking prevent a
concurrent run, inspected the lock in DynamoDB, recovered a stuck lock, and
migrated to native locking. 🎉
