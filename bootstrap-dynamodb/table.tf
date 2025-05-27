
resource "aws_dynamodb_table" "tf_locks" {
  name         = local.dynamodb_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = local.dynamodb_name  #coalesce(var.dynamodb_name, local.dynamodb_name)
    Environment = var.env #"dev"
  }
}
