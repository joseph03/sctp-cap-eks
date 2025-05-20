terraform {
  # variable is not allowed in backend block
  backend "s3" {
    bucket         = "ce-grp-3a-s3"
    key            = "cap-eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ce-grp-3a-dynamodb"
    encrypt        = true
  }
}
