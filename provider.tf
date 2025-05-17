provider "aws" {
  region = var.region
}

# depends_on does not work with data sources
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  #depends_on = [module.eks]
}

# depends_on does not work with data sources
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  #depends_on = [module.eks]
}

# in order to run the following first in wsl, try() is used
# terraform plan -target=module.vpc -target=module.eks -out=tfplan
provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster.endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), "")
  token                  = try(data.aws_eks_cluster_auth.cluster.token, "")

  # Exec configuration for AWS authentication
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }

}

provider "helm" {
  kubernetes {
    host                   = try(data.aws_eks_cluster.cluster.endpoint, "")
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), "")
    token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
  }
}


# provider "kubernetes" {
#   #host                   = data.aws_eks_cluster.cluster.endpoint
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.cluster.token  # to wait for the cluster to be ready
#   # instead of using local config file
#   #config_path = "~/.kube/config"
#   #config_context = local.cluster_name
# }

# provider "helm" {
#   kubernetes {
#     #host                   = data.aws_eks_cluster.cluster.endpoint
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.cluster.token  # to wait for the cluster to be ready
#     # instead of using local config file
#     #config_path = "~/.kube/config"
#     #config_context = local.cluster_name
#   }
# }
