variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "App Environment"
  type        = string
  default     = "dev"
}

variable "s3_name" {
  description = "S3 bucket name"
  type        = string
  #default     = "ce-grp-3a-s3"   # ${local.name_prefix} is not allowed here
  default = null
}
#"ce-grp-3a-s3"

# locals.tf (or in your existing file)
locals {
  s3_name = "ce-grp-3a-s3"
}
