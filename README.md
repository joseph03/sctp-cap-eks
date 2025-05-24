# sctp-cap-eks

# 03-workflow: create cluster and workspace

•	Eks cluster created by terraform
•	Include aws eks command and kubectl create namespace command to create namespace on cluster created.

# 04-external-dns: ExternalDNS Terraform Deployment (Helm + IRSA)

This module deploys ExternalDNS on an EKS cluster using:
- Terraform-managed IAM Role with OIDC (IRSA)
- Kubernetes ServiceAccount with role annotation
- Helm chart (`bitnami/external-dns`) for Kubernetes resources

---

## 📦 Components

- **IAM Policy & Role**
  - Allows ExternalDNS to manage Route53 records.

- **ServiceAccount**
  - Annotated with the IRSA role ARN.

- **Helm Release**
  - Installs ExternalDNS with AWS and IRSA integration.

---

## 🌎 Inputs

| Name         | Description                           | Type   | Required |
|---------- ---|---------------------------------------|--------|----------|
| env          | dev, staging or deploy                | string | yes      |
| domain_name  | Domain to manage (e.g. `example.com`) | string | yes      |
| txt_owner_id | TXT owner ID for ExternalDNS          | string | yes      |

---

## 🌟 Outputs

| Name                         | Description                         |
|------------------------------|-------------------------------------|
| external_dns_role_arn        | IAM Role ARN for ExternalDNS        |
| external_dns_service_account | Kubernetes ServiceAccount name      |

---

## 🚀 Usage

```hcl
module "external_dns" {
  source = "./path-to-module"

  region        = "us-east-1"
  domain_name   = "example.com"
  txt_owner_id = "my-cluster"
}

auto dev, uat, prod - why pr error? need to have uat branch created first