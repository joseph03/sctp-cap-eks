provider "aws" {
  region = var.region #"us-east-1"

}

# add the following, else there is plugin load error
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # or another stable version
    }
  }
}