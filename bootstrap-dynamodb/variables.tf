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

# variable is not allowed in
variable "dynamodb_name" {
  description = "dynamodb table name"
  type        = string
  #default     = "grp-3${local.name_prefix}dynamodb"    # ${local.name_prefix} is not allowed here
  default = null
}

# locals.tf (or in your existing file)
locals {
  dynamodb_name = "grp-3${local.name_prefix}dynamodb"
}
