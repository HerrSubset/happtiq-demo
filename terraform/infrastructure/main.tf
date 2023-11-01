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

resource "google_service_account" "demo-app-sac" {
  account_id   = "demo-app-sac"
  display_name = "Demo App SAC"
  description  = "Service account for the Happtiq Demo app running on GKE"
}

resource "google_project_iam_member" "demo-app-sac-objectviewer" {
  project = "happtiq-pjsmets-demo-play"
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.demo-app-sac.email}"
}

resource "google_project_iam_member" "demo-app-sac-workloadidentityuser" {
  project = "happtiq-pjsmets-demo-play"
  role    = "roles/iam.workloadIdentityUser"
  member  = "serviceAccount:${google_service_account.demo-app-sac.email}"
}

