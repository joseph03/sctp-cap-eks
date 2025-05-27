variable "region" {
  description = "AWS region"
  type        = string
  #default     = "us-east-1"
  default = null
}

variable "env" {
  description = "App Environment"
  type        = string
  #default     = "dev"
  default = null
}

variable "grp-prefix" {
  description = "App Environment"
  type        = string
}

# variable "s3_name" {
#   description = "S3 bucket name"
#   type        = string
#   #default     = "ce-grp-3a-dev-s3"   # ${var.grp-prefix} is not allowed here
#   default = null
# }

locals {
  s3_name = "${var.grp-prefix}s3"
}
