# ingress controller
resource "helm_release" "nginx_ingress" {
  name       = "${var.grp-prefix}nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.9.1"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name # need "ingress-nginx"  else error 

  # set {
  #   name  = "controller.service.externalTrafficPolicy"
  #   value = "Cluster"
  # }

  #  expose the Ingress via ELB/NLB
  # set {
  #   name  = "controller.service.type"
  #   value = "LoadBalancer"
  # }

  # #@@ add
  # set {
  #   name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-connection-idle-timeout"
  #   value = "3600" # 1 hour timeout for NLB
  # }

  # #--
  # # Add these settings:
  # NLB (faster, L4, and supports static IPs)
  # set {
  #   name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
  #   value = "nlb"
  # }

  # set {
  #   name  = "controller.config.use-forwarded-headers"
  #   value = "true"
  # }

  # set {
  #   name  = "controller.config.compute-full-forwarded-for"
  #   value = "true"
  # }
  # end add
  depends_on = [
    kubernetes_namespace.ingress_nginx,
    kubernetes_namespace.ns-app, # Use the namespace resource
    kubernetes_namespace.ns-mon  # Use the namespace resource
  ]
  # Note: The above depends_on is not necessary if the namespaces are created in the same file
}

resource "kubernetes_service" "webapp" {
  metadata {
    name      = "${var.grp-prefix}webapp-service"
    namespace = kubernetes_namespace.ns-app.metadata[0].name # ✅ Use the namespace resource
  }
  spec {
    selector = {
      app = "${var.grp-prefix}webapp" #linked to deployment
    }
    port {
      name        = "http" #-- This must match the name in the ingress
      port        = 80     # service port
      target_port = 80     # pod port
      #13 node_port   = 30080   #09 NodePort (accessible externally)
    }
    #@@ Add explicit session affinity
    #13 session_affinity = "ClientIP"      #09 improves sticky sessions.

    # Specify LoadBalancer type
    #type = "LoadBalancer"    #09 for external access
  }
  depends_on = [
    kubernetes_namespace.ingress_nginx,
    kubernetes_namespace.ns-app, # Use the namespace resource
    kubernetes_ingress_v1.webapp
  ]
}

resource "kubernetes_ingress_v1" "webapp" {
  metadata {
    name      = "${var.grp-prefix}webapp-ingress"
    namespace = kubernetes_namespace.ns-app.metadata[0].name # ✅ Use the namespace resource
    # annotations = {
    #   "kubernetes.io/ingress.class"               = "nginx"
    #   "external-dns.alpha.kubernetes.io/hostname" = "${var.grp-prefix}webapp.sctp-sandbox.com"

    #   #-- Add Health check annotations
    #   "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    #   "alb.ingress.kubernetes.io/healthcheck-port" = "80"
    # }

    #@@ added to solve 504 gateway timeout error
    annotations = {
      "kubernetes.io/ingress.class"                       = "nginx"
      "external-dns.alpha.kubernetes.io/hostname"         = "${var.grp-prefix}webapp.sctp-sandbox.com"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"    = "120" #"30"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout" = "120" #"30"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"    = "120" #"30"
    }
  }

  depends_on = [
    helm_release.nginx_ingress,
    kubernetes_namespace.ingress_nginx,
    kubernetes_namespace.ns-app, # Use the namespace resource
  ]

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "${var.grp-prefix}webapp.sctp-sandbox.com"
      http {
        path {
          path = "/"
          #path_type = "Prefix"
          backend {
            service {
              name = "${var.grp-prefix}webapp-service"
              port {
                #--
                # Choose ONE of these - either name OR number
                # Recommended to use name for better maintainability
                name = "http" # This must match the port name in your service
                # number = 80  # Don't use both!
              }
            }
          }
        }
      }
    }
    #@@ Add this new rule for ELB DNS access to solve 404 error
    # rule {
    #   host = "" # Match any host. A good trick to serve requests when hitting the ELB DNS directly.
    #   http {
    #     path {
    #       path = "/"
    #       backend {
    #         service {
    #           name = "${var.grp-prefix}webapp-service"
    #           port { name = "http" }
    #         }
    #       }
    #     }
    #   }
    # }
  }
}

resource "kubernetes_deployment" "webapp" {
  metadata {
    name      = "${var.grp-prefix}webapp"
    namespace = kubernetes_namespace.ns-app.metadata[0].name # "default"
  }

  depends_on = [
    kubernetes_namespace.ingress_nginx,
    kubernetes_namespace.ns-app, # Use the namespace resource
    kubernetes_service.webapp,   # Use the service resource
    kubernetes_ingress_v1.webapp # Use the ingress resource
  ]

  spec {
    replicas = 2 # Number of replicas for the deployment
    selector {
      match_labels = {
        app = "${var.grp-prefix}webapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.grp-prefix}webapp"
        }
      }

      spec {
        container {
          name  = "${var.grp-prefix}webapp"
          image = "nginx:latest" # default to port 80. Replace with your app image
          port {
            # use custome image if port 3000 is desired
            container_port = 80 # port 80 will be used even if 3000 is stated here when nginx:latest is used
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
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            failure_threshold     = 3 #-- 0523
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            failure_threshold     = 3 #-- 0523
          }

        }
      }
    }
  }
}


resource "kubernetes_horizontal_pod_autoscaler" "webapp" {
  metadata {
    name      = "${var.grp-prefix}webapp-hpa"
    namespace = kubernetes_namespace.ns-app.metadata[0].name # ✅ Use the namespace resource
  }

  depends_on = [
    kubernetes_namespace.ingress_nginx,
    kubernetes_namespace.ns-app, # Use the namespace resource
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

# metric server is needed by autoscaler
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  values = [
    <<-EOF
    args:
      - --kubelet-insecure-tls
      - --kubelet-preferred-address-types=InternalIP
    EOF
  ]
}


