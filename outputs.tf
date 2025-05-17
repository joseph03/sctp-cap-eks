output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "external_dns_role_arn" {
  description = "IAM Role ARN for ExternalDNS"
  value       = module.irsa_external_dns.iam_role_arn
}

output "external_dns_service_account" {
  description = "ServiceAccount name for ExternalDNS"
  value       = kubernetes_service_account.external_dns.metadata[0].name
}

output "eks_oidc_provider" {
  description = "value"
  value       = module.eks.oidc_provider
}