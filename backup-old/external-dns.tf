data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/Z00541411T1NGPV97B5C0"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "external_dns" {
  name        = "ExternalDNSPolicy"
  description = "Policy for ExternalDNS to access Route53"
  policy      = data.aws_iam_policy_document.external_dns.json
}
module "irsa_external_dns" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFExternalDNSRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:external-dns"]
}
# added below 
# resource "helm_release" "external_dns" {
#   name       = "external-dns"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "external-dns"
#   version    = "6.0.0"

#   set {
#     name  = "serviceAccount.create"
#     value = false
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = kubernetes_service_account.external_dns.metadata[0].name
#   }

#   set {
#     name  = "provider"
#     value = "aws"
#   }

#   set {
#     name  = "aws.zoneType"
#     value = "public"
#   }

#   set {
#     name  = "aws.assumeRoleARN"
#     value = module.irsa_external_dns.iam_role_arn
#   }
# }
resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa_external_dns.iam_role_arn
    }
  }
}
resource "kubernetes_cluster_role" "external_dns" {
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch"]
  }
}
resource "kubernetes_cluster_role_binding" "external_dns" {
  metadata {
    name = "external-dns"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_dns.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_dns.metadata[0].name
    namespace = kubernetes_service_account.external_dns.metadata[0].namespace
  }
}
resource "kubernetes_deployment" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"

    labels = {
      app = "external-dns"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "external-dns"
      }
    }

    template {
      metadata {
        labels = {
          app = "external-dns"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.external_dns.metadata[0].name

        container {
          name  = "external-dns"
          image = "bitnami/external-dns:6.0.0"

          env {
            name  = "AWS_REGION"
            value = var.region
          }

          args = [
            "--source=service",
            "--source=ingress",
            "--domain-filter=${var.domain_name}",
            "--provider=aws",
            "--policy=upsert-only",
            "--registry=txt",
            "--txt-owner-id=${var.txt_owner_id}",
            "--aws-zone-type=public",
            "--aws-assume-role-arn=${module.irsa_external_dns.iam_role_arn}"
            ]
        }
      }
    }
  }
}
resource "kubernetes_service" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"

    labels = {
      app = "external-dns"
    }
  }

  spec {
    selector = {
      app = kubernetes_deployment.external_dns.metadata[0].labels["app"]
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}
