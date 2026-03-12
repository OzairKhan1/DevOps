# 🔁 Terraform `for_each` Meta-Argument — Dynamic Multi-Environment EC2 Provisioning

> Provision multiple AWS EC2 instances across different environments using a **single resource block** powered by Terraform's `for_each` meta-argument. No copy-paste. No duplication. Just clean, scalable infrastructure.

---

## 📌 What This Does

This configuration dynamically creates **one EC2 instance per environment** (dev, stage, prod) using a single `aws_instance` resource block. Each instance gets its own:

- ✅ AMI (Amazon Linux / Ubuntu / RedHat)
- ✅ Instance type
- ✅ Root volume size
- ✅ Environment tag

All driven by a single `map(object(...))` variable — change one value, re-apply, done.

---

## 🗂️ Project Structure

```
forEach_MetaArgument/
├── main.tf           # EC2 resource using for_each
├── variables.tf      # Versatile map(object) variable with defaults
├── provider.tf       # AWS provider (us-east-1)
└── terraform.tf      # Required providers block (AWS ~> 6.33.0)
```

---

## ⚙️ How `for_each` Works Here

Instead of writing three separate `aws_instance` blocks, we pass a **map of objects** to `for_each`. Terraform iterates over each key-value pair:

| Key (Environment) | `each.key` | `each.value.ec2_type` | `each.value.ami_id` | `each.value.ec2_volume` |
|-------------------|------------|----------------------|---------------------|------------------------|
| `dev`             | `dev`      | `t2.small`           | Amazon Linux        | 8 GB                   |
| `stage`           | `stage`    | `t2.micro`           | Ubuntu              | 10 GB                  |
| `prod`            | `prod`     | `t2.micro`           | RedHat              | 12 GB                  |

The `Environment = each.key` tag automatically names each instance based on its map key.

---

## 🧩 Variable Schema

```hcl
variable "ec2_versitile_config" {
  type = map(object({
    ami_id     = string
    ec2_type   = string
    ec2_volume = number
  }))
}
```

This schema is **intentionally open-ended** — need a new parameter like `subnet_id` or `iam_role`? Just add it to the object and reference it via `each.value.<new_param>`.

---

## 🚀 Getting Started

### Prerequisites
- Terraform `>= 1.0`
- AWS CLI configured with appropriate credentials
- An existing key pair named `terraformKey` in your AWS account
- A valid security group ID (update `vpc_security_group_ids` in `main.tf`)

### Deploy

```bash
# Initialize providers
terraform init

# Preview what will be created
terraform plan

# Apply the configuration
terraform apply
```

Terraform will create **3 EC2 instances** named after their map keys:
- `aws_instance.forEachMapObj["dev"]`
- `aws_instance.forEachMapObj["stage"]`
- `aws_instance.forEachMapObj["prod"]`

---

## 🛠️ Customization

### Add a New Environment

Simply add a new entry to the `default` map in `variables.tf` (or pass via `-var-file`):

```hcl
uat = {
  ec2_type   = "t2.medium"
  ec2_volume = 15
  ami_id     = "ami-xxxxxxxxxxxxxxxxx"
}
```

Re-run `terraform apply` — only the new instance will be created. Existing ones are untouched.

### Override at Runtime

```bash
terraform apply -var='ec2_versitile_config={
  prod = {
    ec2_type   = "t3.large"
    ec2_volume = 20
    ami_id     = "ami-xxxxxxxxxxxxxxxxx"
  }
}'
```

### Extend the Object Schema

To add more per-instance parameters (e.g., `subnet_id`):

1. Add to the `type` definition in `variables.tf`
2. Add values in the `default` block for each environment
3. Reference via `each.value.subnet_id` in `main.tf`

---

## 🔒 Security Defaults

All EC2 root volumes are:
- Encrypted at rest (`encrypted = true`)
- Using `gp3` volume type for better performance and lower cost

---

## 📋 Resource Summary

| Resource | Description |
|----------|-------------|
| `aws_instance.forEachMapObj` | Dynamic EC2 instances (one per map key) |
| `root_block_device` | Encrypted `gp3` volumes, size per environment |
| Tags | `Environment` tag auto-set from map key |

---

## 💡 Why `for_each` Over `count`?

| | `count` | `for_each` |
|---|---------|-----------|
| Index type | Integer (`0`, `1`, `2`) | Named key (`dev`, `stage`, `prod`) |
| Remove middle item | Causes re-creation of all subsequent resources 😬 | Only removes the targeted resource ✅ |
| Readability | `aws_instance.ec2[1]` | `aws_instance.ec2["stage"]` |
| Recommended for maps | ❌ | ✅ |

---

## 📄 License

MIT — free to use, modify, and distribute.

---

> 💬 *"Write once, deploy many."* — The `for_each` way.
