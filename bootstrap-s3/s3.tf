resource "aws_s3_bucket" "tf_state" {
  bucket        = coalesce(var.s3_name, local.s3_name) # Use var.s3_name if provided, else local.s3_name
  force_destroy = true

  tags = {
    Name        = coalesce(var.s3_name, local.s3_name) # Use var.s3_name if provided, else local.s3_name
    Environment = var.env                              #"dev"
  }
}

resource "aws_s3_bucket" "tf_state" {
  bucket        = "${var.grp-prefix}s3"
  force_destroy = true

  tags = {
    Name        = "${var.grp-prefix}s3"
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

