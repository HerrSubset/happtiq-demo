provider "google" {
    project = "happtiq-pjsmets-demo-play"
    region = "europe-west3"
}

resource "google_container_cluster" "demo-gke-cluster" {
  name     = "demo-gke-cluster"
  enable_autopilot = true
  deletion_protection = false # Needed to easily destroy with Terraform
}

