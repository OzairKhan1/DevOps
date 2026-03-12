# 📘 AWS IAM Deep Dive – Complete Practical Understanding (From Zero to Industrial Level)

This document summarizes all IAM-related questions, confusions, and clarifications discussed during this project.  
It includes detailed explanations, examples, Terraform perspective, and industrial best practices.

This README covers:

- IAM User vs IAM Role
- Trust Policy vs Permission Policy
- STS (Security Token Service)
- Why EC2 does not need IAM User
- EC2 Instance Profile
- SSM Industrial Approach (No SSH Keys)
- ARN structure
- Policy JSON mastery
- Resource confusion (S3 bucket vs object)
- Terraform IAM best practices
- Real-world thinking model

---

# 1️⃣ IAM Fundamentals

AWS Identity and Access Management (IAM) controls:

- WHO can access AWS
- WHAT actions they can perform
- ON WHICH resources
- UNDER WHAT conditions

IAM works using JSON-based policies.

Think of IAM as a security system:

- IAM User → A person
- IAM Role → A temporary badge
- Policy → Rules attached to badge
- STS → The machine issuing temporary badges

---

# 2️⃣ IAM User vs IAM Role

## IAM User

- Has permanent credentials (Access Key + Secret Key)
- Used by humans or external systems
- Credentials must be stored securely
- Example: `aws configure` uses IAM User

Problem:
If access keys leak → security breach.

---

## IAM Role

- Has NO permanent credentials
- Is assumed temporarily
- Uses STS to generate temporary credentials
- Recommended for AWS services like EC2, Lambda, ECS

Industrial Best Practice:
❌ Do NOT attach access keys to EC2  
✅ Use IAM Role

---

# 3️⃣ Two Types of Policies (Very Important Concept)

This was a major confusion point.

There are TWO different policy types involved with roles.

---

## A) Trust Policy (Assume Role Policy)

This policy answers:

👉 WHO is allowed to assume the role?

Key identifier:

```json
"Principal"
```

Example:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Service": "ec2.amazonaws.com"
  },
  "Action": "sts:AssumeRole"
}
```

Explanation:

- Principal → EC2 service
- Action → sts:AssumeRole
- Effect → Allow

Meaning:
EC2 is trusted to use this role.

Important:
Trust policy is embedded inside the IAM Role.

---

## B) Permission Policy (Attached Policy)

This policy answers:

👉 WHAT can the role do after assuming?

Example:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```

Explanation:

- Allow Get and Put
- On objects inside bucket
- No Principal here
- Because the role itself is the identity

Key Difference:

Trust Policy → Who can assume  
Permission Policy → What actions are allowed  

---

# 4️⃣ What is STS?

STS = Security Token Service

It provides temporary credentials.

Flow when EC2 launches:

1. EC2 has a role attached
2. EC2 calls sts:AssumeRole
3. STS generates temporary credentials
4. EC2 uses them automatically

No access keys stored.
No credentials in code.
Fully secure and automatic.

---

# 5️⃣ Why We Do NOT Need IAM User for EC2

Normally flow:

IAM User → Access Keys → Attach Policy

But EC2 is an AWS service.

Correct Industrial Flow:

IAM Role  
→ Trust EC2  
→ Attach Permission Policy  
→ Attach role to EC2  
→ EC2 automatically gets temporary credentials  

So IAM User is unnecessary here.

---

# 6️⃣ What is EC2 Instance Profile?

EC2 cannot directly attach a role.

AWS requires an Instance Profile as a wrapper.

Concept:

IAM Role → Instance Profile → EC2

Terraform Example:

```hcl
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_role.name
}
```

Then attach it to EC2:

```hcl
resource "aws_instance" "example" {
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
}
```

Instance Profile is simply a container for the role.

---

# 7️⃣ Industrial Approach: EC2 + SSM (No SSH)

Instead of:

- Opening port 22
- Managing SSH keys
- Using key pairs

We use:

AmazonSSMManagedInstanceCore policy

Steps:

1. Create IAM Role
2. Trust EC2 in trust policy
3. Attach AWS managed policy:
   arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
4. Create Instance Profile
5. Attach to EC2
6. Connect via Session Manager

Benefits:

- No open ports
- No SSH keys
- No key rotation
- Centralized access control
- More secure

---

# 8️⃣ Understanding ARN Structure

Example:

arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

Breakdown:

arn → Amazon Resource Name  
aws → partition  
iam → service  
aws:policy → AWS managed policy  
AmazonSSMManagedInstanceCore → policy name  

From ARN you can understand:

- Which service
- Whether AWS managed or custom
- Resource type

---

# 9️⃣ Understanding Policy JSON Structure

Basic structure:

```json
{
  "Version": "2012-10-17",
  "Statement": []
}
```

Each Statement answers:

- Effect → Allow or Deny
- Action → What operations
- Resource → Which resource
- Condition → Optional restrictions

Example:

```json
{
  "Effect": "Allow",
  "Action": ["ec2:DescribeInstances"],
  "Resource": "*"
}
```

Action and Resource can be:

- Single string
- List of strings

---

# 🔟 S3 Resource Confusion (Bucket vs Object)

Bucket only:

arn:aws:s3:::my-bucket

Objects inside bucket:

arn:aws:s3:::my-bucket/*

Why separate?

Because:

- s3:ListBucket applies to bucket
- s3:GetObject applies to objects

Correct policy usually needs both statements.

---

# 1️⃣1️⃣ Can One Role Be Used by Multiple Services?

Yes.

Example trust policy:

```json
"Principal": {
  "Service": [
    "ec2.amazonaws.com",
    "lambda.amazonaws.com"
  ]
}
```

Now both EC2 and Lambda can assume the role.

Important:
Only services defined in Principal can assume the role.

---

# 1️⃣2️⃣ Terraform IAM Best Practice

Avoid:

aws_iam_policy_attachment

Because if role name changes → DeleteConflict error.

If using it, you must set:

force_detach_policies = true

Better approach:

Use:

aws_iam_role_policy_attachment

It is safer and recommended.

---

# 1️⃣3️⃣ How to Master Writing IAM Policies

To master policy writing:

1. Always identify:
   - Who? → Trust Policy
   - What? → Permission Policy
   - On what? → Resource ARN
   - Under what condition? → Condition block

2. Understand:
   - Statement is a list of rules
   - Action can be string or list
   - Resource can be string or list
   - Deny overrides Allow

3. Follow least privilege principle:
   Give minimum required permissions.

---

# 1️⃣4️⃣ Complete IAM Flow Summary

Trust Policy  
→ Defines WHO can assume role  

Permission Policy  
→ Defines WHAT actions are allowed  

Instance Profile  
→ Attaches role to EC2  

STS  
→ Issues temporary credentials  

EC2  
→ Uses temporary credentials automatically  

---

# ✅ Final Industrial Best Practice Summary

❌ Do not use IAM users for EC2  
❌ Do not store access keys inside instances  
❌ Do not open port 22 unnecessarily  

✅ Use IAM Roles  
✅ Use STS temporary credentials  
✅ Use SSM instead of SSH  
✅ Use least privilege  
✅ Use aws_iam_role_policy_attachment in Terraform  

---

# 🚀 Project Learning Outcome

After this deep dive, the following concepts are fully understood:

- IAM Roles
- Trust vs Permission Policies
- STS mechanism
- EC2 Instance Profile
- SSM industrial approach
- ARN structure
- Policy JSON structure
- S3 bucket vs object permissions
- Terraform IAM best practices


---
