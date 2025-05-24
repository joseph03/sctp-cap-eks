
# kube-system is automatically created by the cluster
# the following are created in cluster specified in provider "kubernetes" 
resource "kubernetes_namespace" "ns-app" {
  metadata {
    name = "ns-app"
  }
  depends_on = [null_resource.wait_for_eks]
}

# depend on cluster specified in provider "kubernetes" 
resource "kubernetes_namespace" "ns-mon" {
  metadata {
    name = "ns-mon"
  }
  depends_on = [null_resource.wait_for_eks]
}

resource "kubernetes_namespace" "ns-db" {
  metadata {
    name = "ns-db"
  }
  depends_on = [null_resource.wait_for_eks]
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
  depends_on = [null_resource.wait_for_eks]
}


