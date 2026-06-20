# Terraform — Local Provider Notes & Assignments

A walkthrough of setting up a Terraform project with the `local` provider, followed by three practice assignments.

---

## 1. Project Setup

Create a project folder and initialize Terraform inside it.

```bash
cd Desktop
mkdir terraform-pwSkills
cd terraform-pwSkills
terraform init
```

---

## 2. Hello World Example

Create a `main.tf` file that writes a simple text file using the `local` provider.

**`main.tf`**

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "local" {}

resource "local_file" "hello" {
  filename = "hello.txt"
  content  = "Hello, World!"
}
```

### Core Workflow Commands

Run these in order after writing your configuration:

```bash
terraform fmt        # Format the configuration files
terraform validate   # Check the syntax and internal consistency
terraform plan       # Preview the changes Terraform will make
terraform apply      # Apply the changes and create the resources
```

| Command | Purpose |
| --- | --- |
| `terraform fmt` | Rewrites config files into a canonical format/style |
| `terraform validate` | Verifies the config is syntactically valid |
| `terraform plan` | Shows an execution plan without making changes |
| `terraform apply` | Creates/updates the actual resources |

---

## Assignment 1 — Create Two Text Files

**Goal:** Use Terraform to create two text files.

**`main.tf`**

```hcl
terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

resource "local_file" "file_one" {
  filename = "file1.txt"
  content  = "This is the first file."
}

resource "local_file" "file_two" {
  filename = "file2.txt"
  content  = "This is the second file."
}
```

---

## Assignment 2 — Generate an Application Configuration File

**Goal:** Generate an application configuration file (`app.conf`).

**`main.tf`**

```hcl
terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

resource "local_file" "config" {
  filename = "app.conf"
  content  = "port=8080"
}
```

---

## Assignment 3 — Create Multiple Files Using `for_each`

**Problem Statement:** A DevOps team needs separate configuration files for different environments (`dev`, `test`, `prod`).

**`main.tf`**

```hcl
terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

resource "local_file" "environments" {
  for_each = toset([
    "dev",
    "test",
    "prod"
  ])

  filename = "${each.key}.conf"
  content  = "Environment = ${each.key}"
}
```

This produces three files — `dev.conf`, `test.conf`, and `prod.conf` — each containing its environment name. The `for_each` meta-argument iterates over the set, and `each.key` holds the current value on every iteration.

---

> **Tip:** Always run `terraform plan` before `terraform apply` to review exactly what will be created, changed, or destroyed.
