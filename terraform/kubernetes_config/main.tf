provider "google" {
    project = "happtiq-pjsmets-demo-play"
    region = "europe-west3"
}

data "google_container_cluster" "demo-gke-cluster" {
  name     = "demo-gke-cluster"
}

data "google_client_config" "google-client" {
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.demo-gke-cluster.endpoint}"
  token = data.google_client_config.google-client.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.demo-gke-cluster.master_auth[0].cluster_ca_certificate,
  )
}


resource "kubernetes_namespace" "demo-namespace" {
   metadata {
     name = "happtiq-demo" 
   }
}

resource "kubernetes_deployment" "demo-deployment" {
    metadata {
      name = "demo-deployment"
      labels = {
          app = "happtiq-demo-app"
      }
      namespace = kubernetes_namespace.demo-namespace.metadata.0.name
    }

    spec {
      replicas = 2
      selector {
        match_labels = {
          app = "happtiq-demo-app"
        }
      }
      template {
        metadata {
          labels = {
              app = "happtiq-demo-app"
          }
        }
        spec {
          container {
            image = "europe-west3-docker.pkg.dev/happtiq-pjsmets-demo-play/happtiq-demo/happtiq-demo:latest"
            name = "happtiq-demo-app"

            resources {
              limits = {
                memory = "50Mi"
              }
              requests = {
                memory = "20Mi"
                cpu = "100m"
              }
            }
            liveness_probe {
              http_get {
                path = "/"
                port = 80
              }
              initial_delay_seconds = 3
              period_seconds = 3
            }
            port {
              container_port = 80
            }
          }
        }
      }
    }
}

resource "kubernetes_service" "demo-app-service" {
    metadata {
      name = "demo-deployment-service"
      namespace = kubernetes_namespace.demo-namespace.metadata.0.name
    }
    spec {
      selector = {
        app = kubernetes_deployment.demo-deployment.metadata.0.labels.app
      }
      port {
        port = 8080
        target_port = 80
      }
      type = "NodePort" # The Ingress requires it to be NodePort or LoadBalancer.
    }
}

resource "kubernetes_ingress_v1" "demo-app-ingress" {
    metadata {
      name = "demo-deployment-ingress"
      namespace = kubernetes_namespace.demo-namespace.metadata.0.name
    }

    spec {
        default_backend {
          service {
            name = kubernetes_service.demo-app-service.metadata.0.name
            port {
              number = 8080
            }
          }
        }

        # TODO: the rule block might be unneeded
        rule {
          http {
            path {
              backend {
                service {
                    name = kubernetes_service.demo-app-service.metadata.0.name
                    port {
                      number = 8080
                    }
                }
              }
              path = "/"
            }
          }
        }
    }
}
