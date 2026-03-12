# 🏗️ Terraform `count` Meta-Argument — Complete Guide

> Master Terraform's `count` meta-argument with real-world patterns used in production environments.

---

## 📚 Table of Contents

- [Variant 1 — Basic Count](#variant-1--basic-count)
- [Variant 2 — Variable-Controlled Count](#variant-2--variable-controlled-count)
- [Variant 3 — Even/Odd Tagging Logic](#variant-3--evenodd-tagging-logic)
- [Variant 4 — Environment-Based Conditional Creation](#variant-4--environment-based-conditional-creation)
- [Variant 5 — Referencing Counted Resources](#variant-5--referencing-counted-resources)

---

## Variant 1 — Basic Count

The simplest use of `count` — create multiple identical resources with a single block.

```hcl
resource "aws_s3_bucket" "demoBucket" {
  count = 3

  bucket = "${var.env}-bucket-${count.index + 1}"

  tags = {
    Name        = "bucket-${count.index + 1}"
    Environment = var.env
  }
}
```

**What this creates:**
| Index | Bucket Name |
|-------|-------------|
| `0`   | `dev-bucket-1` |
| `1`   | `dev-bucket-2` |
| `2`   | `dev-bucket-3` |

> 💡 `count.index` starts at `0`. Adding `+ 1` makes names human-friendly.

---

## Variant 2 — Variable-Controlled Count

> **Industry Standard** — dynamically scale infrastructure without editing resource blocks.

```hcl
variable "bucket_count" {
  default = 5
}

resource "aws_s3_bucket" "demoBucket" {
  count = var.bucket_count

  bucket = "${var.env}-bucket-${count.index + 1}"

  tags = {
    Name        = "bucket-${count.index + 1}"
    Environment = var.env
  }
}
```

**Why this matters:**

- Change `bucket_count` at plan time without touching resource logic
- Pass via CLI: `terraform apply -var="bucket_count=10"`
- Combine with `.tfvars` files for environment-specific scaling

> 🏢 This is the preferred pattern in team and enterprise Terraform setups.

---

## Variant 3 — Even/Odd Tagging Logic

Assign different roles to resources based on their index using the **modulo operator**.

```hcl
resource "aws_s3_bucket" "demoBucket" {
  count = 4

  bucket = "${var.env}-bucket-${count.index + 1}"

  tags = {
    Type = count.index % 2 == 0 ? "primary" : "secondary"
  }
}
```

**How the tagging works:**

| Index | `index % 2` | Tag Type    |
|-------|-------------|-------------|
| `0`   | `0` (even)  | `primary`   |
| `1`   | `1` (odd)   | `secondary` |
| `2`   | `0` (even)  | `primary`   |
| `3`   | `1` (odd)   | `secondary` |

> ⚙️ Useful for alternating AZ placement, primary/replica patterns, or blue/green bucket sets.

---

## Variant 4 — Environment-Based Conditional Creation

Conditionally create resources only in specific environments using a **ternary expression**.

```hcl
variable "env" {
  default = "dev"
}

resource "aws_s3_bucket" "demoBucket" {
  count = var.env == "prod" ? 3 : 0

  bucket = "prod-bucket-${count.index + 1}"
}
```

**Behavior by environment:**

| `var.env` | `count` Value | Buckets Created |
|-----------|---------------|-----------------|
| `"dev"`   | `0`           | ❌ None          |
| `"staging"` | `0`         | ❌ None          |
| `"prod"`  | `3`           | ✅ 3 buckets     |

> 🔐 A `count = 0` resource is **planned but never applied** — safe for non-production runs.  
> 🏢 This pattern is extremely common in enterprise Terraform for cost control and security isolation.

---

## Variant 5 — Referencing Counted Resources

Use `[count.index]` to reference a specific instance when wiring counted resources together.

```hcl
resource "aws_s3_bucket" "demoBucket" {
  count  = 3
  bucket = "${var.env}-bucket-${count.index + 1}"
}

resource "aws_s3_bucket_versioning" "versioning" {
  count  = 3
  bucket = aws_s3_bucket.demoBucket[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}
```

**What's happening:**

```
demoBucket[0]  ──►  versioning[0]  (bucket id referenced via [count.index])
demoBucket[1]  ──►  versioning[1]
demoBucket[2]  ──►  versioning[2]
```

> ⚠️ Both resources **must have the same `count`** to keep indexes aligned.  
> 📌 Syntax: `resource_type.resource_name[index].attribute`

---

## 🧠 Quick Reference

| Pattern | Use Case |
|--------|----------|
| `count = N` | Create N identical resources |
| `count = var.x` | Dynamically scale via variables |
| `count.index % 2` | Alternate tagging / role assignment |
| `count = condition ? N : 0` | Environment-gated provisioning |
| `resource[count.index].attr` | Cross-resource index referencing |

---

## 📎 Notes

- Removing an item from a counted list causes **index shifting** — consider `for_each` for stable, key-based resource management.
- `count` and `for_each` **cannot be used together** on the same resource.
- Always use `count.index + 1` in names unless zero-indexed naming is intentional.

---

<p align="center">Made with ❤️ for Terraform learners everywhere</p>
