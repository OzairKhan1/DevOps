# Terraform Multi-Environment Infrastructure with Workspaces

## Overview

This project demonstrates how to manage multiple environments (dev, stage, prod) using:

- Terraform Workspaces
- Remote State Management with S3
- State Locking using DynamoDB
- Modular Infrastructure Design

The goal is to follow industry-standard Terraform practices while keeping environments isolated and secure.

---

## Table of Contents

- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Backend Bootstrapping](#backend-bootstrapping)
- [Terraform Workspaces](#terraform-workspaces)
- [How to Use](#how-to-use)
- [Remote State Management](#remote-state-management)
- [Best Practices Followed](#best-practices-followed)
- [Problems Faced & Lessons Learned](#problems-faced--lessons-learned)
- [Key Takeaways](#key-takeaways)

---

## Architecture

This project uses:

- S3 Bucket → Stores Terraform state files
- DynamoDB Table → Provides state locking
- Terraform Workspaces → Separate environments
- Reusable Modules → Infrastructure consistency

Each workspace generates its own state file inside the same S3 bucket:

- dev.tfstate
- stage.tfstate
- prod.tfstate

---

## Project Structure

```
.
├── backend/
│   └── main.tf         # Creates S3 bucket + DynamoDB table or seperate files for s3.tf and dynamodb.tf
│
├── modules/
│   └── myModule/        # Reusable infrastructure module
│
├── main.tf              # Root configuration
├── variables.tf
├── outputs.tf
├── .tfvars              # .tfvars per environment. 
```

---

## Backend Bootstrapping

### Step 1 — Create Remote Backend Resources

Navigate to the backend directory:

```bash
cd backend
terraform init
terraform apply
```

This creates:

- S3 bucket (for remote state storage)
- DynamoDB table (for state locking)

---

### Step 2 — Configure Backend in Root

In the root configuration:  # This could be a seperate file or inside the main.tf as used in this Project

```hcl
terraform {
  backend "s3" {
    bucket         = "your-s3-bucket-name"
    dynamodb_table = "your-dynamoTable-bucket-name"
    key            = "env.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
```

---

### Step 3 — Initialize Remote Backend

Return to the root directory:

```bash
terraform init
```

Terraform will migrate local state to the S3 backend.

---

## Terraform Workspaces

Workspaces allow multiple isolated state files using the same configuration.

### Create Workspaces

```bash
terraform workspace new dev
terraform workspace new stage
terraform workspace new prod
```

### Switch Workspace

```bash
terraform workspace select dev
```

### Verify Current Workspace

```bash
terraform workspace show
```

Each workspace maintains a separate state file in S3.

---

## How to Use

### 1. Select Workspace

```bash
terraform workspace select dev
```

### 2. Plan

```bash
terraform plan -var-file=dev.tfvars
```

### 3. Apply

```bash
terraform apply -var-file=dev.tfvars
```

Repeat for stage and prod environments.

---

## Remote State Management

This project uses:

- S3 versioning enabled
- Server-side encryption (AES256)
- DynamoDB state locking

Benefits:

- Prevents concurrent state modification
- Maintains state history
- Secures infrastructure metadata
- Enables team collaboration

---

## Best Practices Followed

- Separate backend bootstrap configuration
- Remote state storage
- State locking enabled
- Encryption enabled
- Modular infrastructure design
- Environment isolation via workspaces
- Unique resource naming per environment
- Manual variable file selection using -var-file

---

## Problems Faced & Lessons Learned

### 1. Multiple `.auto.tfvars` Files Loaded Automatically

Issue:

Having multiple files like:

- dev.auto.tfvars
- stage.auto.tfvars
- prod.auto.tfvars

Terraform automatically loads ALL `.auto.tfvars` files in the directory.

Result:

- Variables were overridden
- Wrong environment values were applied

Lesson:

Do not use multiple `.auto.tfvars` files in the same directory when using workspaces.

Instead use:

- dev.tfvars
- stage.tfvars
- prod.tfvars

And explicitly pass them using:

```bash
terraform plan -var-file=dev.tfvars
```

---

### 2. Backend S3 Bucket Could Not Be Destroyed

Error:

BucketNotEmpty: The bucket you tried to delete is not empty

Reason:

- Versioning was enabled
- State files and object versions still existed

Lesson:

- Versioned S3 buckets require deleting all object versions before deletion
- Backend infrastructure should be treated as permanent
- Backend should be created separately (bootstrap phase)

---

### 3. SSH Key Confusion Across Environments

Concern:

Whether the same public SSH key can be used for multiple environments.

Lesson:

- The same public key can be reused
- AWS key pair names must be unique per environment
- For production systems, separate keys or SSM is recommended

---

### 4. Workspace Does Not Automatically Change Variables

Issue:

Switching workspace did not automatically apply environment-specific variables.

Lesson:

Workspaces separate state, not variable values.

Variables must be managed manually using `-var-file`.

---

## Key Takeaways

- Workspaces isolate state, not configuration
- Backend infrastructure should be bootstrapped separately
- Avoid multiple `.auto.tfvars` in multi-environment setups
- Remote state and locking are mandatory for team environments
- Backend resources should not be destroyed during normal operations
- Always explicitly control environment variables

---

## Final Note

This project demonstrates core DevOps principles:

- Infrastructure as Code
- Secure state management
- Environment isolation
- Modular architecture
- Production-ready Terraform design
