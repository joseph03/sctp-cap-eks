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

resource "aws_dynamodb_table" "tf_locks" {
  name         = "${var.grp-prefix}dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.grp-prefix}dynamodb"
    Environment = var.env #"dev"
  }
}
