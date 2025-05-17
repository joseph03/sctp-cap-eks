locals {
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

locals {
  # Filter out local zones, which are not currently supported 
  # with managed node groups
  #cluster_name = "${local.name_prefix}eks-${random_string.suffix.result}"
  cluster_name = "${local.name_prefix}eks-cluster"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${local.name_prefix}vpc"

  cidr = "10.0.0.0/16"
  #azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  azs = local.availability_zones

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    # #-- deep
    # iam_role_additional_policies = {
    #   AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    #   AmazonEKS_CNI_Policy              = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    #   AmazonEKSWorkerNodePolicy         = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    # }
    # #-- end

    # #-- chat
    # iam_role_additional_permissions = [
    #   {
    #     actions = [
    #       "ec2:CreateLaunchTemplateVersion",
    #       "ec2:RunInstances",
    #       "ec2:DescribeLaunchTemplates",
    #       "ec2:DescribeLaunchTemplateVersions",
    #       "ec2:DescribeInstances"
    #     ]
    #     resources = ["*"]
    #   }
    # ]
    # #-- end
  }
  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.medium"] #t3.small is not allowed

      min_size      = 1
      max_size      = 3
      desired_size  = 2
      capacity_type = "ON_DEMAND" #-- deep
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.medium"] #t3.small is not allowed

      min_size      = 1
      max_size      = 2
      desired_size  = 1
      capacity_type = "ON_DEMAND" #-- deep
    }
  }
}

# #-- deep
# resource "aws_iam_role_policy_attachment" "additional" {
#   for_each = module.eks.eks_managed_node_groups

#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = each.value.iam_role_name
# }
# #-- end

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}
