terraform {
  backend "gcs" {
    bucket = "pj-happtiq-tf-states"
    prefix = "infrastructure"
  }
}

provider "google" {
  project = "happtiq-pjsmets-demo-play"
  region  = "europe-west3"
}

resource "google_container_cluster" "demo-gke-cluster" {
  name                = "demo-gke-cluster"
  enable_autopilot    = true
  deletion_protection = false # Needed to easily destroy with Terraform
}

resource "google_compute_global_address" "demo-app-public-ip" {
  project      = "happtiq-pjsmets-demo-play"
  name         = "demo-app-external-ip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

resource "google_storage_bucket" "demo-app-image-bucket" {
  name          = "demo-app-image-bucket"
  location      = "europe-west3"
  force_destroy = true # So we can delete the bucket plus contents with TF for easier recreation of the infra

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}
