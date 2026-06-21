
# Configure AWS with Terraform and Create a Simple EC2 Instance

## Step 1: Install Terraform

Verify Terraform installation:

```bash
terraform --version
```

---

## Step 2: Install AWS CLI

Verify AWS CLI installation:

```bash
aws --version
```

---

## Create an IAM User for Terraform

Create a new IAM user named:

```text
terraform_user
```

Assign the following permissions:

1. AdministratorAccess
2. AmazonEC2FullAccess
3. AmazonS3FullAccess

> **Note:** In production environments, it is recommended to follow the principle of least privilege instead of assigning AdministratorAccess.

Generate an Access Key and Secret Access Key for this user.

---

## Step 3: Configure AWS Credentials

Configure AWS credentials using the IAM user's access keys:

```bash
aws configure
```

Example:

```text
AWS Access Key ID: XXXXXXXXXXXXXXXX
AWS Secret Access Key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Default region name: us-east-1
Default output format: json
```

---

## Step 4: Create Project Directory

```bash
mkdir terraform-ec2
cd terraform-ec2
```

---

## Step 5: Create `main.tf`

Create a file named `main.tf`:

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "webserver" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t2.micro"

  tags = {
    Name = "Terraform-Server"
  }
}
```

---

## Step 6: Initialize and Run Terraform

Execute the following commands:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

When prompted:

```text
Enter a value: yes
```

Terraform will create an EC2 instance in AWS.

---

# Using Variables in Terraform

## Create `variables.tf`

```hcl
variable "instance_type" {
  description = "Type of instance to be created"
  type        = string
  default     = "t2.micro"
}
```

---

## Update `main.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "webserver" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = var.instance_type

  tags = {
    Name = "Terraform-Server"
  }
}
```

---

## Run the Terraform Script

Initialize and validate:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Create an EC2 instance using a custom instance type:

```bash
terraform apply -var="instance_type=t3.micro"
```

---

## Destroy the Infrastructure

To remove the EC2 instance and all resources managed by Terraform:

```bash
terraform destroy
```

When prompted:

```text
Enter a value: yes
```

---

## Project Structure

```text
terraform-ec2/
│
├── main.tf
├── variables.tf
├── terraform.tfstate
├── terraform.tfstate.backup
└── .terraform/
```

---

## Common Terraform Commands

| Command                | Description                    |
| ---------------------- | ------------------------------ |
| `terraform init`       | Initialize Terraform project   |
| `terraform fmt`        | Format Terraform files         |
| `terraform validate`   | Validate Terraform syntax      |
| `terraform plan`       | Preview infrastructure changes |
| `terraform apply`      | Create/Update infrastructure   |
| `terraform destroy`    | Remove infrastructure          |
| `terraform show`       | Display Terraform state        |
| `terraform state list` | List managed resources         |

---

## Cleanup

Always destroy lab resources after testing to avoid AWS charges:

```bash
terraform destroy
```
