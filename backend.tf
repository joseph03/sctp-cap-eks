terraform {
  # variable is not allowed in backend block
  backend "s3" {
    bucket         = "grp-3joseph03-cap-eks-tfstate"
    key            = "cap-eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "grp-3joseph03-cap-eks-tf-locks"
    encrypt        = true
  }
}
#"grp-3${local.name_prefix}cap-eks-tfstate"
#"grp-3${local.name_prefix}cap-eks-tf-locks"