provider "google" {
    project = "happtiq-pjsmets-demo-play"
    region = "europe-west3"
}

resource "google_container_cluster" "demo-gke-cluster" {
  name     = "demo-gke-cluster"
  enable_autopilot = true
  deletion_protection = false # Needed to easily destroy with Terraform
}

resource "google_compute_global_address" "demo-app-public-ip" {
  project      = "happtiq-pjsmets-demo-play"
  name         = "demo-app-external-ip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}
