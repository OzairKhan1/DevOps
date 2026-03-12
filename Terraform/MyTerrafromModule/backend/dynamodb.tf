resource "aws_dynamodb_table" "db-state_lock" {
  region       = "us-east-1"
  name         = "dynamodb-for-diff-terraform-worksapces"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "TerraformLockTable"
    Environment = terraform.workspace
  }
}
