# nested variable is not allowed
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

locals {
  dynamodb_name = "${var.grp-prefix}dynamodb"
}
