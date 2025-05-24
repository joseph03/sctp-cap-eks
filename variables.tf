variable "region" {
  description = "AWS region"
  type        = string
}

variable "env" {
  description = "App Environment"
  type        = string
}

variable "domain_name" {
  description = "Domain for ExternalDNS"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.domain_name))
    error_message = "Invalid domain name format"
  }
}

variable "txt_owner_id" {
  description = "The owner ID used in TXT records to identify ownership"
  type        = string
}

variable "grp-prefix" {
  description = "Prefix for resource group"
  type        = string
}