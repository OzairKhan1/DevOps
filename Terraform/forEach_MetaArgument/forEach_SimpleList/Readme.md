# ⚠️ `for_each` with a Simple List — Limitations & Why You Need `map(object)`

> This covers the **simple list approach** to `for_each` — what it can do, where it breaks down, and why it's not enough for real multi-environment setups.

---

## 📌 What This Example Does

Using `toset(var.ec2_type)` with `for_each`, Terraform creates one EC2 instance per item in the list. Each instance gets a different `instance_type` via `each.value`.

```hcl
for_each      = toset(var.ec2_type)
instance_type = each.value
```

Simple. Clean. But **limited**.

---

## 🧱 The Core Limitation — One Parameter Only

With a plain list, `each.value` gives you **a single string**. That means you can only vary **one thing** per instance.

### The Problem in Plain Terms

Say you want 3 environments with different configs:

| Environment | Instance Type | Volume Size |
|-------------|--------------|-------------|
| dev         | t2.small     | 8 GB        |
| stage       | t2.micro     | 10 GB       |
| prod        | t2.large     | 20 GB       |

With a list, you can do this ✅:
```hcl
for_each      = toset(var.ec2_type)
instance_type = each.value   # works — one value per item
```

But you **cannot** do this ❌:
```hcl
volume_size = each.value   # already used for instance_type — can't use it twice
```

> **`each.value` is a single string. You cannot attach a second parameter to it.**  
> Need volume size + instance type + AMI per environment? A list won't cut it.

---

## 🔒 Other Hardcoded Limitations in This Example

Because the list only drives `instance_type`, everything else had to be **hardcoded**:

```hcl
ami        = "ami-0b6c6ebed2801a5cb"   # same AMI for all envs — no flexibility
volume_size = 8                         # same volume for all envs — no flexibility
Environment = "General"                 # meaningless tag — not tied to actual env
```

This defeats the purpose of dynamic provisioning. Dev and prod end up with the same AMI, same disk size, and the same generic tag.

---

## 🪣 Bonus: S3 `count` Naming Pitfall

The commented-out S3 bucket block highlights a classic gotcha:

```hcl
# bucket = "${var.env}-demobucket-${count.index + 1}-ozairkhan"
```

**S3 bucket names must always be lowercase.** If `var.env` ever contains uppercase letters (e.g., `Dev`, `PROD`), Terraform will throw an error. Always use `lower()` or enforce lowercase in your variable validation:

```hcl
bucket = lower("${var.env}-demobucket-${count.index + 1}-ozairkhan")
```

---

## ✅ The Fix — Use `map(object(...))` Instead

To vary multiple parameters per environment, switch from a list to a map of objects:

```hcl
variable "ec2_config" {
  type = map(object({
    ec2_type   = string
    volume_size = number
    ami_id     = string
  }))
}
```

Now `each.value.ec2_type`, `each.value.volume_size`, and `each.value.ami_id` are all available independently — giving you full per-environment control with zero hardcoding.

---

## 🆚 Quick Comparison

| Feature | `for_each` + List | `for_each` + `map(object)` |
|---|---|---|
| Multiple parameters per env | ❌ | ✅ |
| Named environment tags | ❌ (generic) | ✅ (`each.key`) |
| Different AMI per env | ❌ | ✅ |
| Different volume per env | ❌ | ✅ |
| Scalability | Low | High |

---

> 💡 **Takeaway:** Use a list with `for_each` only when you need to vary a **single attribute**. The moment you need two or more unique values per environment, move to `map(object(...))`.
