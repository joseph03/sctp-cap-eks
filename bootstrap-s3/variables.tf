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
  default     = "grp-3${local.name_prefix}s3"
}
#"grp-3${local.name_prefix}s3"