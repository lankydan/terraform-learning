resource "helm_release" "nginx_ingress" {
  name       = "ingress"
  namespace  = var.ingress_namespace
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = "4.12.2"

  # Adds a node port so there is a static address (removes the need to port forward).
  values = [
    <<EOF
controller:
  replicaCount: ${var.replicas}
  service:
    type: NodePort
    nodePorts:
      http: 30201
EOF
  ]
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = "ingress"
    namespace = var.namespace
    annotations = {
      # `ingress.class` needed for Nginx (the `nginx_ingress` defined above) to automatically discover this ingress
      # https://kubernetes.github.io/ingress-nginx/user-guide/basic-usage/#ingress-class
      "kubernetes.io/ingress.class"                = "nginx"
      # Rewrites all requests to the root path. So if `/app` routes to `app-service`, the url that the `app-service`
      # itself will receive will still be `/` instead of `/app`.
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      http {
        dynamic "path" {
          for_each = var.ingress_paths
          content {
            path = path.value["path"]
            backend {
              service {
                name = path.value["service_name"]
                port {
                  number = path.value["service_port"]
                }
              }
            }
          }
        }
      }
    }
  }
}
