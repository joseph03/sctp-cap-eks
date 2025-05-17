resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${local.name_prefix}cap-eks-terraform-state"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "${local.name_prefix}cap-eks-terraform-state"
    Environment = var.env #"dev"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${local.name_prefix}cap-eks-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${local.name_prefix}cap-eks-terraform-locks"
    Environment = var.env #"dev"
  }
}
