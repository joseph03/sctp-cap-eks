variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "App Environment"
  type        = string
}

variable "domain_name" {
  description = "The domain name managed by ExternalDNS"
  type        = string
}

variable "txt_owner_id" {
  description = "The owner ID used in TXT records to identify ownership"
  type        = string
}
