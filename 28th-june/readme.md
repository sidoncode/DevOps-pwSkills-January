# Terraform: Vault & Workspaces — Simple Step-by-Step Tutorial

A beginner-friendly guide. Just follow the steps in order and copy-paste the commands.

**Before you start, make sure you have:**

- Terraform installed → check with `terraform version`
- HashiCorp Vault installed → check with `vault version`
- A terminal open and a folder for your project

---

# Part 1: Terraform + Vault (Simple Tutorial)

**Goal:** Store a secret in Vault, then have Terraform read it. This keeps passwords and keys *out* of your code.

## Step 1 — Start Vault in dev mode

Dev mode is the easiest way to learn (do **not** use it in production).

```bash
vault server -dev
```

When it starts, it prints two important things. Copy them:

- A line like `Unseal Key: ...`
- A line like `Root Token: ...` (e.g. `hvs.xxxxxxxx`)

Leave this terminal running. Open a **new** terminal for the next steps.

## Step 2 — Point your tools at Vault

In the new terminal, run these (paste your own Root Token):

```bash
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='paste-your-root-token-here'
```

Check it works:

```bash
vault status
```

## Step 3 — Save a secret in Vault

Let's store a fake database password.

```bash
vault kv put secret/myapp db_password="SuperSecret123"
```

Read it back to confirm:

```bash
vault kv get secret/myapp
```

You should see `db_password = SuperSecret123`.

## Step 4 — Create your Terraform files

Make a folder and go into it:

```bash
mkdir terraform-vault-demo
cd terraform-vault-demo
```

Create a file called **`main.tf`** and paste this:

```hcl
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# Connects Terraform to Vault
provider "vault" {
  address = "http://127.0.0.1:8200"
  # Token comes from the VAULT_TOKEN environment variable
}

# Reads the secret we stored
data "vault_kv_secret_v2" "myapp" {
  mount = "secret"
  name  = "myapp"
}

# Shows the secret value (just for learning)
output "db_password" {
  value     = data.vault_kv_secret_v2.myapp.data["db_password"]
  sensitive = true
}
```

## Step 5 — Run Terraform

```bash
terraform init      # downloads the Vault provider
terraform plan      # shows what will happen
terraform apply     # type "yes" when asked
```

## Step 6 — See your secret

Because we marked it `sensitive`, run:

```bash
terraform output db_password
```

You'll see `SuperSecret123` — pulled from Vault, never written in your code.

**You're done with Part 1!** Press `Ctrl+C` in the Vault terminal to stop it when finished.

> **Tip:** Never hard-code passwords. Marking outputs `sensitive = true` hides them from logs.

---

# Part 2: Terraform Workspaces (Simple Tutorial)

**Goal:** Use the *same* code to manage *different* environments (like `dev` and `prod`) without copying files.

Think of a workspace as a separate "save file" — same code, separate state.

## Step 1 — Create a simple project

```bash
mkdir terraform-workspace-demo
cd terraform-workspace-demo
```

Create **`main.tf`** with this beginner example (it just creates a local file):

```hcl
# Picks a value based on the current workspace name
locals {
  environment = terraform.workspace
}

# Creates a file named after the environment
resource "local_file" "example" {
  filename = "${local.environment}-config.txt"
  content  = "This is the ${local.environment} environment."
}

output "current_workspace" {
  value = terraform.workspace
}
```

Initialize it:

```bash
terraform init
```

## Step 2 — See your current workspace

Every project starts with one called `default`.

```bash
terraform workspace list
```

The `*` shows which one you're in.

## Step 3 — Create new workspaces

```bash
terraform workspace new dev
terraform workspace new prod
```

After creating one, you're automatically switched into it.

## Step 4 — Switch between workspaces

```bash
terraform workspace select dev
```

Check where you are:

```bash
terraform workspace show
```

## Step 5 — Apply in each workspace

While in `dev`:

```bash
terraform apply   # type "yes"
```

This creates `dev-config.txt`.

Now switch and apply again:

```bash
terraform workspace select prod
terraform apply   # type "yes"
```

This creates `prod-config.txt`.

**Same code, two different results** — that's the power of workspaces.

## Step 6 — Clean up (optional)

You can only delete a workspace you're *not* currently in. So:

```bash
terraform workspace select default
terraform workspace delete dev
terraform workspace delete prod
```

---

## Quick Command Cheat Sheet

| What you want | Command |
|---|---|
| List workspaces | `terraform workspace list` |
| Show current workspace | `terraform workspace show` |
| Create a workspace | `terraform workspace new <name>` |
| Switch workspace | `terraform workspace select <name>` |
| Delete a workspace | `terraform workspace delete <name>` |
| Save a Vault secret | `vault kv put secret/myapp key="value"` |
| Read a Vault secret | `vault kv get secret/myapp` |

---

## Common Beginner Notes

- **Workspaces are for environments, not big differences.** If `dev` and `prod` are wildly different, use separate folders instead.
- **Dev-mode Vault is temporary.** All secrets vanish when you stop the server. That's fine for learning.
- **`terraform.workspace`** is a built-in variable that always equals the current workspace name.
- Always run `terraform plan` before `apply` to preview changes safely.

Happy building!
