resource "aws_s3_bucket" "s3_tf_state" {
  region = "us-east-1"
  bucket = "bucket-for-diff-terraform-worksapces"
  force_destroy  = true   # This is only for Practice. Industy doesn't allow it. to destroy s3 and all it's content.
  tags = {
    Name        = "TerraformStateBucket"
  }
}

resource "aws_s3_bucket_versioning" "s3_tf_state_versioning" {
  bucket = aws_s3_bucket.s3_tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.s3_tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
