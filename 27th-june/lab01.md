# Simple S3 Bucket with Terraform + GitHub Actions (Beginner Guide)

A simple, beginner-friendly tutorial to create an AWS S3 bucket using Terraform, automated with GitHub Actions. **No remote state, no DynamoDB — just the basics.**

---

## What You'll Do

```
Push code to GitHub  →  GitHub Actions runs Terraform  →  S3 bucket created
```

---

## Prerequisites

1. An **AWS account**.
2. A **GitHub account** with a new empty repository.
3. That's it. (You don't even need Terraform installed locally — GitHub Actions does the work.)

---

## Step 1 — Create AWS Access Keys

GitHub needs permission to create things in AWS.

1. Go to **AWS Console → IAM → Users → Create user**.
2. Name it `github-actions`.
3. Attach the policy **`AmazonS3FullAccess`**.
4. Open the user → **Security credentials → Create access key** → choose **Application running outside AWS**.
5. Copy the **Access Key ID** and **Secret Access Key**. Keep them safe — you'll need them in Step 4.

---

## Step 2 — Your Project Files

You only need 3 files in your repository:

```
.
├── main.tf                          # The S3 bucket
└── .github/
    └── workflows/
        └── deploy.yml               # The CI/CD pipeline
```

---

## Step 3 — Write the Terraform File

Create a file called **`main.tf`**:

```hcl
# Tell Terraform to use AWS
provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-simple-bucket-12345"   # must be globally unique — change this!
}
```

> **Important:** S3 bucket names must be unique across all of AWS. Change `my-simple-bucket-12345` to something like `my-simple-bucket-yourname-2026`.

---

## Step 4 — Add Your AWS Keys to GitHub

1. In your GitHub repo, go to **Settings → Secrets and variables → Actions**.
2. Click **New repository secret** and add these two:

| Secret name             | Value                         |
|-------------------------|-------------------------------|
| `AWS_ACCESS_KEY_ID`     | Your access key ID from Step 1|
| `AWS_SECRET_ACCESS_KEY` | Your secret key from Step 1   |

---

## Step 5 — Create the GitHub Actions Workflow

Create the file **`.github/workflows/deploy.yml`**:

```yaml
name: Deploy S3 Bucket

# Run every time you push to the main branch
on:
  push:
    branches:
      - main

jobs:
  terraform:
    runs-on: ubuntu-latest

    # Give the job your AWS keys
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

    steps:
      # Get your code
      - name: Checkout code
        uses: actions/checkout@v4

      # Install Terraform
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      # Get Terraform ready
      - name: Terraform Init
        run: terraform init

      # Create the bucket
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

That's the whole pipeline. Each push to `main` will create (or update) your bucket.

---

## Step 6 — Push to GitHub

In your project folder, run:

```bash
git init
git add .
git commit -m "Create S3 bucket with Terraform"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

---

## Step 7 — Watch It Run

1. Go to your repo's **Actions** tab on GitHub.
2. Click the running workflow ("Deploy S3 Bucket").
3. Watch the steps complete. When **Terraform Apply** turns green, your bucket is created!

---

## Step 8 — Check Your Bucket

Go to the **AWS Console → S3**. You should see your new bucket listed.

---

## How to Delete the Bucket Later

When you're done, the easiest way is in the AWS Console: **S3 → select your bucket → Empty → then Delete**.

(Or, if you have Terraform installed locally, run `terraform destroy -auto-approve`.)

---

## Quick Troubleshooting

| Problem | Fix |
|---------|-----|
| `BucketAlreadyExists` | The name is taken. Change `bucket` in `main.tf` to something more unique. |
| `AccessDenied` | Check your GitHub secrets are correct and the IAM user has `AmazonS3FullAccess`. |
| Workflow doesn't run | Make sure the file is at `.github/workflows/deploy.yml` and you pushed to the `main` branch. |

---

*Done! You now have a simple CI/CD pipeline that creates an S3 bucket every time you push to GitHub.*
