provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.34.0"
    }
  }

  backend "s3" {
    bucket         = "bucket-for-diff-terraform-worksapces"
    dynamodb_table = "dynamodb-for-diff-terraform-worksapces"
    key            = "demo/terraform.tfstate" # The path create at s3 will be: s3_name/env/workspace_name/demo/.tfstate
    region         = "us-east-1"
    encrypt        = true
  }
}

module "myModule" {
  source = "git::https://github.com/OzairKhan1/Terraform.git//MyTerrafromModule/GenModule?ref=main"
  environment  = var.environment
  project_name = var.project_name
  role         = var.role
  path_to_public_key = var.path_to_public_key
  ec2_type           = var.ec2_type
  block_storage      = var.block_storage
  allowed_ports      = var.allowed_ports
  count_number       = var.count_number

  tags = {
    Name        = "Demo Instance for ${terraform.workspace}"
    Environment = terraform.workspace
  }
}
