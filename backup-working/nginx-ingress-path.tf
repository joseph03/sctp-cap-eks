# required. This creates the actual ingress controller pod and the cloud load balancer.
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.9.1"
  namespace  = "ingress-nginx"
  
  set {
    name  = "controller.service.type"
    value = "LoadBalancer" # Creates the AWS ELB/NLB
  }
  depends_on = [kubernetes_namespace.ingress_nginx]
}

# Ingress depends on the Service — 
# because the Ingress needs the Service to already exist so it can route traffic to it. 
resource "kubernetes_ingress_v1" "webapp" {
  metadata {
    name      = "${local.name_prefix}webapp-ingress"
    namespace = kubernetes_namespace.joseph03app.metadata[0].name  # ✅ Use the namespace resource
    # annotations = {
    #   "kubernetes.io/ingress.class"               = "nginx"
    #   "external-dns.alpha.kubernetes.io/hostname" = "${local.name_prefix}webapp.sctp-sandbox.com"

    #   #-- Add Health check annotations
    #   "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    #   "alb.ingress.kubernetes.io/healthcheck-port" = "80"
    # }
    
    #@@ added to solve 504 gateway timeout error
    annotations = {
      "kubernetes.io/ingress.class"               = "nginx"
      "external-dns.alpha.kubernetes.io/hostname" = "${local.name_prefix}apps.sctp-sandbox.com"   #change from webapp to apps
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "120"    #"30"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "120"    #"30"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "120"    #"30"
    }
  }

  depends_on = [
    kubernetes_namespace.ingress_nginx,
    kubernetes_namespace.joseph03app, # Use the namespace resource
    kubernetes_service.webapp
  ]

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "${local.name_prefix}apps.sctp-sandbox.com" # Single host
      http {
        path {
          path = "/"
          #path_type = "Prefix"  # Ensures /webapp and subpaths are routed
          backend {
            service {
              name = "${local.name_prefix}webapp-service"
              port { name = "http" }
            }
          }
        }
        path {
          path = "/webmon"
          path_type = "Prefix"  # Ensures /webmon and subpaths are routed
          backend {
            service {
              name = "${local.name_prefix}webmon-service"
              port { name = "http" }
            }
          }
        }
      }
    }    # #@@ Add this new rule for ELB DNS access to solve 404 error
    # rule {
    #   host = "" # Match any host. A good trick to serve requests when hitting the ELB DNS directly.
    #   http {
    #     path {
    #       path = "/"
    #       backend {
    #         service {
    #           name = "${local.name_prefix}webapp-service"
    #           port { name = "http" }
    #         }
    #       }
    #     }
    #   }
    # }
  }
}

# kubernetes_ingress_v1 references this service
resource "kubernetes_service" "webapp" {
  metadata {
    name      = "${local.name_prefix}webapp-service"
    namespace = kubernetes_namespace.joseph03app.metadata[0].name  # ✅ Use the namespace resource
  }
  
  spec {
    selector = {
      app = "${local.name_prefix}webapp"      #linked to deployment
    }
    port {
      name        = "http"  #-- This must match the name in the ingress
      port        = 80      # service port
      target_port = 3000     # 80. app's container port
      #node_port   = 30080   #09 NodePort (accessible externally)
    }
    #@@ Add explicit session affinity
    session_affinity = "ClientIP"      #09 improves sticky sessions.

    # Specify LoadBalancer type
    #type = "LoadBalancer"    #09 since helm_release is loadbalancer, this is not needed
    #type = "ClusterIP"        #12 this is default, let the Ingress handle external traffic
  }
  depends_on = [
    kubernetes_namespace.ingress_nginx,
    kubernetes_namespace.joseph03app, 
    helm_release.nginx_ingress 
  ]
}

resource "kubernetes_deployment" "webapp" {
  metadata {
    name      = "${local.name_prefix}webapp"
    namespace = kubernetes_namespace.joseph03app.metadata[0].name  # "default"
  }

  depends_on = [
    kubernetes_namespace.ingress_nginx,
    kubernetes_namespace.joseph03app, 
    kubernetes_service.webapp
  ]

  spec {
    replicas = 2 # Number of replicas for the deployment
    selector {
      match_labels = {
        app = "${local.name_prefix}webapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "${local.name_prefix}webapp"
        }
      }

      spec {
        container {
          name  = "${local.name_prefix}webapp"
          #image = "nginx:latest" # default to port 80. Replace with your app image
          #image = "dkjt/joseph03-webapp:latest"  # ← updated
          image = "node:20-alpine"  # Lightweight Node.js
          command = ["npx", "http-server", "-p", "3000"]  # Serves files on port 3000
          port {
            container_port = 3000  #80
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000    #80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000   #80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
          
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "webapp" {
  metadata {
    name      = "${local.name_prefix}webapp-hpa"
    namespace = kubernetes_namespace.joseph03app.metadata[0].name  # ✅ Use the namespace resource
  }

  depends_on = [
    kubernetes_namespace.ingress_nginx,
    kubernetes_namespace.joseph03app, # Use the namespace resource
  ]
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.webapp.metadata[0].name
    }
    min_replicas                      = 2
    max_replicas                      = 5
    target_cpu_utilization_percentage = 80
  }
}

# matrix server is needed by autoscaler
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  
  depends_on = [null_resource.wait_for_eks]

values = [
  <<-EOF
  args:
    - --kubelet-insecure-tls
    - --kubelet-preferred-address-types=InternalIP
  resources:
    limits:
      cpu: 100m
      memory: 300Mi
    requests:
      cpu: 50m
      memory: 150Mi
  EOF
  ]
}


