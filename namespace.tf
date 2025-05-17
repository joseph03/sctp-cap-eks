
# kube-system is automatically created by the cluster
# the following are created in cluster specified in provider "kubernetes" 
resource "kubernetes_namespace" "joseph03app" {
  metadata {
    name = "${local.name_prefix}app"
  }
  depends_on = [null_resource.wait_for_eks]
}

# depend on cluster specified in provider "kubernetes" 
resource "kubernetes_namespace" "joseph03mon" {
  metadata {
    name = "${local.name_prefix}mon"
  }
  depends_on = [null_resource.wait_for_eks]
}

resource "kubernetes_namespace" "joseph03db" {
  metadata {
    name = "${local.name_prefix}db"
  }
  depends_on = [null_resource.wait_for_eks]
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
  depends_on = [null_resource.wait_for_eks]
}


