terraform {
  # variable is not allowed in backend block
  backend "s3" {} # to work with hcl
}
