env = "prod"
# Terraform .tfvars files do not support interpolation like ${env}. They are strictly key-value definitions.
grp-prefix   = "ce-grp-3a-prod-"
domain_name  = "sctp-sandbox.com"
txt_owner_id = "sctp-sandbox.com"
region       = "us-east-1"