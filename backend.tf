terraform {
  # variable is not allowed in backend block
  backend "s3" {
    bucket         = "joseph03-cap-eks-terraform-state"
    key            = "cap-eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "joseph03-cap-eks-terraform-locks"
    encrypt        = true
  }
}
