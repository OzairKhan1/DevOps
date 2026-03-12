# 🏗️ Terraform Basics – Easy Learning Guide

> **Terraform** is an **IaC (Infrastructure as Code)** tool used to create and manage infrastructure on cloud platforms like **AWS**, **Azure**, and **GCP**.

---

## 🧠 Simple Rule for Learning Terraform

```
"BLOCK_TYPE" "LABEL_1" "LABEL_2" { arguments }
```

| Term | Meaning |
|------|---------|
| **Block** | What you want to define / do |
| **Arguments** | Configuration settings inside `{}` |

---

## 📦 Block Types

### a) `resource` — Create Infrastructure

Used to **create** cloud or local infrastructure.

```hcl
resource "local_file" "myfile" {
  filename = "myfile.txt"
  content  = "This is my first file via Terraform"
}
```

| Part | Description |
|------|-------------|
| `resource` | Block type |
| `"local_file"` | Provider resource type (TYPE) |
| `"myfile"` | Your logical name (NAME) |
| Arguments | Settings inside `{}` |

---

### b) `terraform` — Terraform Settings

Used to **configure Terraform itself**. This block does **NOT** require labels.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

> ✅ Configures: required providers, backend, Terraform version.

---

### c) `provider` — Configure Cloud Provider

Used to **configure authentication and region** settings for a cloud provider.

```hcl
provider "aws" {
  region = "us-east-1"
}
```

> 💡 The provider block has **one label** (the provider name).

---

### d) `output` — Display Output

Used to **show values** after `terraform apply`.

```hcl
output "instance_ip" {
  value = aws_instance.web.public_ip
}
```

---

### e) `variable` — Input Variables

Used for **input values** to make configuration reusable and dynamic.

```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
```

---

### f) `data` — Read Existing Infrastructure

Used to **fetch existing infrastructure** — does NOT create anything.

```hcl
data "aws_ami" "latest" {
  most_recent = true
}
```

---

### g) `locals` — Reusable Internal Values

Used for **internal reusable values** within your configuration.

```hcl
locals {
  environment = "production"
}
```

---

## 🔄 Terraform Workflow

```bash
terraform init      # Initialize the project & download providers
terraform plan      # Preview changes before applying
terraform apply     # Create/update infrastructure
terraform destroy   # Tear down infrastructure
```

---

## 📌 Key Concepts

### Resource Address Format
```
resource_type.resource_name.attribute
# Example:
aws_instance.web.public_ip
```

### State File
- Terraform stores infrastructure state in **`terraform.tfstate`**
- ⚠️ **Do NOT edit manually**
- In production, use **remote backends** (e.g., S3 + DynamoDB)

### File Reading
> Terraform reads **ALL `.tf` files** in the directory automatically.
> File names don't matter — only the `.tf` extension does.

---

## ✅ Best Practices

- [ ] Use **variables** instead of hardcoding values
- [ ] Use **modules** to organize large infrastructure
- [ ] Use **remote backend** for state management
- [ ] **Lock state file** in team environments
- [ ] Use **version constraints** for providers
- [ ] Keep **separate environments** (dev, stage, prod)
- [ ] Follow **naming conventions**
- [ ] Never store **secrets in plain text** — use `sensitive = true`
- [ ] Run `terraform fmt` before committing code
- [ ] Run `terraform validate` to check syntax

---

## 🎯 Golden Interview Line

> *"Terraform is **declarative**, maintains **state**, and uses **providers** to manage infrastructure resources across multiple cloud platforms."*

---

## 📝 Quick Reference Cheat Sheet

| Block | Purpose | Requires Labels? |
|-------|---------|-----------------|
| `resource` | Create infrastructure | ✅ Yes (type + name) |
| `terraform` | Terraform settings | ❌ No |
| `provider` | Configure cloud provider | ✅ Yes (provider name) |
| `output` | Display values | ✅ Yes (output name) |
| `variable` | Input variables | ✅ Yes (variable name) |
| `data` | Read existing infrastructure | ✅ Yes (type + name) |
| `locals` | Internal reusable values | ❌ No |

