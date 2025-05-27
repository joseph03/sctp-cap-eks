resource "aws_s3_bucket" "tf_state" {
  # Use var.s3_name if provided, else local.s3_name
  # coalesce(var.s3_name, local.s3_name) 
  bucket        = local.s3_name # Use local.s3_name as the bucket name
  force_destroy = true

  tags = {
    Name        = local.s3_name # Use local.s3_name for the tag
    Environment = var.env #"dev"
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

