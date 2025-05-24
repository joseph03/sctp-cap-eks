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
# variable is not allowed in
variable "dynamodb_name" {
  description = "dynamodb table name"
  type        = string
  #default     = "ce-grp-3a-dynamodb"    # ${var.grp-prefix} is not allowed here
  default = null
}

# locals.tf (or in your existing file)
locals {
  dynamodb_name = "${var.grp-prefix}dynamodb"
}
