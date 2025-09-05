terraform {
  required_version = "~> 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0" # pick the latest stable
    }
  }

  backend "gcs" {
    bucket      = "my-state-bucket-gcp"      # GCS bucket name (must exist)
    prefix      = "gke/terraform.tfstate"   # folder/object path inside the bucket
  }
}

provider "google" {
  project = var.gcp_project   # your GCP project ID
  region  = var.gcp_region    # e.g. us-central1
  zone    = var.gcp_zone      # e.g. us-central1-a (optional if using only region)
}
