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

variable "dynamodb_name" {
  description = "dynamodb table name"
  type        = string
  default     = "grp-3${local.name_prefix}dynamodb"
}