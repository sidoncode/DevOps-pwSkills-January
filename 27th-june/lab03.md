# Terraform Module for EC2 Creation

## Objective

Learn how to create an AWS EC2 instance using a reusable Terraform module.

---

# Prerequisites

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

## Step 3: Create an IAM User

Create a new IAM user named:

```text
terraform_user
```

Assign the following permissions:

- AdministratorAccess
- AmazonEC2FullAccess
- AmazonS3FullAccess

Generate:

- Access Key ID
- Secret Access Key

---

## Step 4: Configure AWS Credentials

```bash
aws configure
```

Example:

```text
AWS Access Key ID: XXXXXXXXXXXXXX
AWS Secret Access Key: XXXXXXXXXXXXXX
Default region name: us-east-1
Default output format: json
```

---

# Project Structure

Create the following structure:

```text
terraform-ec2-module/
│
├── main.tf
├── outputs.tf
│
└── modules/
    └── ec2/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

# Step 5: Create EC2 Module

## File: modules/ec2/main.tf

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}
```

---

## File: modules/ec2/variables.tf

```hcl
variable "ami_id" {}

variable "instance_type" {}

variable "instance_name" {}
```

---

## File: modules/ec2/outputs.tf

```hcl
output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
```

---

# Step 6: Create Root Configuration

## File: main.tf

```hcl
provider "aws" {
  region = "us-east-1"
}

module "ec2_server" {
  source = "./modules/ec2"

  ami_id         = "ami-0c02fb55956c7d316"
  instance_type  = "t2.micro"
  instance_name  = "Terraform-Module-EC2"
}
```

### Understanding Module Syntax

```hcl
module "ec2_server" {
```

- `module` → Terraform keyword
- `ec2_server` → User-defined module name
- Not a reserved keyword
- Can be changed to any valid name

Examples:

```hcl
module "webserver" {
  source = "./modules/ec2"
}
```

```hcl
module "production_server" {
  source = "./modules/ec2"
}
```

---

## File: outputs.tf

```hcl
output "instance_id" {
  value = module.ec2_server.instance_id
}

output "public_ip" {
  value = module.ec2_server.public_ip
}
```

### Important

If your module name changes:

```hcl
module "webserver" {
  source = "./modules/ec2"
}
```

Then outputs must be:

```hcl
output "instance_id" {
  value = module.webserver.instance_id
}

output "public_ip" {
  value = module.webserver.public_ip
}
```

---

# Step 7: Initialize Terraform

```bash
terraform init
```

Expected Output:

```text
Initializing modules...
Initializing provider plugins...

Terraform has been successfully initialized!
```

---

# Step 8: Validate Configuration

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

---

# Step 9: Review Execution Plan

```bash
terraform plan
```

Terraform displays the resources it intends to create.

---

# Step 10: Create EC2 Instance

```bash
terraform apply
```

When prompted:

```text
yes
```

Expected:

```text
Apply complete!
```

---

# Step 11: Verify Outputs

```bash
terraform output
```

Example:

```text
instance_id = "i-0123456789abcdef0"
public_ip   = "54.210.100.50"
```

---

# Step 12: Verify in AWS Console

Navigate to:

1. AWS Console
2. EC2 Dashboard
3. Instances

You should see:

```text
Terraform-Module-EC2
```

running.

---

# Troubleshooting

## Error: Reference to undeclared module

Example:

```text
No module call named "ec2_server" is declared in the root module.
```

Cause:

Output references:

```hcl
module.ec2_server.instance_id
```

but no module named `ec2_server` exists.

Example:

```hcl
module "webserver" {
  source = "./modules/ec2"
}
```

Correct output:

```hcl
output "instance_id" {
  value = module.webserver.instance_id
}
```

---

## Reinitialize Terraform

If you create or rename modules after initialization:

```bash
terraform init
```

Run again.

---

# Destroy Resources

To avoid AWS charges:

```bash
terraform destroy
```

Type:

```text
yes
```

---

# Student Exercise 1

Create another EC2 instance using the same module.

```hcl
module "ec2_server2" {
  source = "./modules/ec2"

  ami_id         = "ami-0c02fb55956c7d316"
  instance_type  = "t2.micro"
  instance_name  = "Student-Server"
}
```

---

# Student Exercise 2

Convert hardcoded values into variables.

Example:

```hcl
variable "instance_name" {
  default = "MyServer"
}
```

Use:

```bash
terraform apply -var="instance_name=ProductionServer"
```

---

# Learning Outcomes

After completing this lab, you will be able to:

- Understand Terraform Modules
- Create reusable modules
- Pass variables to modules
- Use module outputs
- Deploy EC2 instances using modules
- Troubleshoot module-related errors
- Destroy infrastructure safely
