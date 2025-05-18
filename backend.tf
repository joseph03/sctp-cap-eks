terraform {
  # variable is not allowed in backend block
  backend "s3" {
    bucket         = "grp-3joseph03-s3"
    key            = "cap-eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "grp-3joseph03-dynamodb"
    encrypt        = true
  }
}
