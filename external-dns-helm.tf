# ✅ IAM policy document
data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:TagResource",
      "route53:ChangeTagsForResource"
    ]
    # these actions require access to sctp-sandbox.com hosted zone
    # aws route53 list-hosted-zones --query 'HostedZones[?Name==`sctp-sandbox.com.`]' 
    resources = [
      "arn:aws:route53:::hostedzone/Z00541411T1NGPV97B5C0"
    ]
    #resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListTagsForResource",
    ]
    # * - These actions (like ListHostedZones) require access to all Route 53 resources
    resources = ["*"]
  }
}

# ✅ IAM policy
resource "aws_iam_policy" "external_dns" {
  name        = "${var.grp-prefix}ExternalDNSPolicy"
  description = "Policy for ExternalDNS to access Route53"
  policy      = data.aws_iam_policy_document.external_dns.json


}

# ✅ IRSA role
module "irsa_external_dns" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFExternalDNSRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:external-dns"]
}

# ✅ Kubernetes service account (no ClusterRole, ClusterRoleBinding, Deployment, or Service needed)
resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system" # 

    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa_external_dns.iam_role_arn
    }
  }
  depends_on = [null_resource.wait_for_eks]
}


resource "helm_release" "external_dns" {
  depends_on = [kubernetes_service_account.external_dns]

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.16.1"
  timeout    = 300 # Increase the timeout (default is 300)
  namespace  = "kube-system"

  set {
    name  = "image.repository"
    value = "registry.k8s.io/external-dns/external-dns"
  }

  # set {
  #   name  = "image.tag"
  #   value = "v0.13.5"
  # }

  # Service Account Configuration
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external_dns.metadata[0].name
  }

  # AWS Provider Configuration
  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "aws.assumeRoleARN"
    value = module.irsa_external_dns.iam_role_arn
  }
  # Add the label to the deployment for the following to work
  # kubectl get pods -n kube-system -l app=external-dns
  set {
    name  = "podLabels.app"
    value = "external-dns"
  }

  #@@ 
  set {
    name  = "aws.zoneType"
    value = "public" # Ensure this matches your Route53 zone
  }

  # Add explicit DNS TTL
  set {
    name  = "txt-owner-id"
    value = "${var.grp-prefix}dns-owner"
  }
  #@@ end
}


