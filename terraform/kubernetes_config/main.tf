terraform {
  backend "gcs" {
    bucket = "pj-happtiq-tf-states"
    prefix = "kubernetes_config"
  }
}

provider "google" {
  project = "happtiq-pjsmets-demo-play"
  region  = "europe-west3"
}

data "google_container_cluster" "demo-gke-cluster" {
  name = "demo-gke-cluster"
}

data "google_compute_global_address" "demo-app-public-ip" {
  name = "demo-app-external-ip"
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

data "google_service_account" "demo-app-sac" {
  account_id = "demo-app-sac"
}

resource "kubernetes_service_account" "demo-app-sac" {
  metadata {
    name      = "demo-app-sac"
    namespace = kubernetes_namespace.demo-namespace.metadata.0.name
    annotations = {
      "iam.gke.io/gcp-service-account" = data.google_service_account.demo-app-sac.email
    }
  }
}

resource "google_service_account_iam_binding" "workload-identity-user-binding" {
  service_account_id = data.google_service_account.demo-app-sac.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:happtiq-pjsmets-demo-play.svc.id.goog[happtiq-demo/demo-app-sac]"
  ]
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
        service_account_name = kubernetes_service_account.demo-app-sac.metadata.0.name
        init_container {
          name  = "download-images"
          image = "google/cloud-sdk:453.0.0"
          command = [
            "gcloud",
            "storage",
            "cp",
            "gs://demo-app-image-bucket/happtiq_logo.png",
            "/usr/share/nginx/images/happtiq_logo.png",
          ]
          volume_mount {
            name       = "image-dir"
            mount_path = "/usr/share/nginx/images"
          }
        }
        container {
          image = "europe-west3-docker.pkg.dev/happtiq-pjsmets-demo-play/happtiq-demo/happtiq-demo:image3"
          name  = "happtiq-demo-app"

          volume_mount {
            name       = "image-dir"
            mount_path = "/usr/share/nginx/images"
          }

          resources {
            limits = {
              memory = "50Mi"
            }
            requests = {
              memory = "20Mi"
              cpu    = "100m"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
          port {
            container_port = 80
          }
        }
        volume {
          name = "image-dir"
          empty_dir {

          }
        }
      }
    }
  }
}

resource "kubernetes_service" "demo-app-service" {
  metadata {
    name      = "demo-deployment-service"
    namespace = kubernetes_namespace.demo-namespace.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.demo-deployment.metadata.0.labels.app
    }
    port {
      port        = 8080
      target_port = 80
    }
    type = "NodePort" # The Ingress requires it to be NodePort or LoadBalancer.
  }
}

resource "kubernetes_ingress_v1" "demo-app-ingress" {
  metadata {
    name      = "demo-deployment-ingress"
    namespace = kubernetes_namespace.demo-namespace.metadata.0.name
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = data.google_compute_global_address.demo-app-public-ip.name
    }
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
