resource "aws_s3_bucket" "tf_state" {
  bucket        = "ce-grp-3a-s3"
  force_destroy = true

  tags = {
    Name        = "ce-grp-3a-s3"
    Environment = var.env #"dev"
  }

  # versioning {
  #   enabled = true
  # }

  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       sse_algorithm = "AES256"
  #     }
  #   }
  # }
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
  name         = "ce-grp-3a-dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "ce-grp-3a-dynamodb"
    Environment = var.env #"dev"
  }
}
