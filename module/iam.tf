# ==========================================================
# Workload Identity & GCP Service Accounts for GKE
# ==========================================================

locals {
  cluster_name = var.cluster_name
  ksa_name     = "gke-test"    # Kubernetes Service Account name
  gsa_name     = "gke-test"    # Google Service Account name
}

# Create a Google Service Account (GSA) for workloads
resource "google_service_account" "gsa" {
  account_id   = local.gsa_name
  display_name = "${local.cluster_name} Workload Identity Service Account"
}

# Grant IAM roles to the GSA as needed (replace/add roles as required)
resource "google_project_iam_member" "gsa_roles_storage" {
  project = var.gcp_project
  role    = "roles/storage.admin"  # Example role, adjust as needed
  member  = "serviceAccount:${google_service_account.gsa.email}"
}

resource "google_project_iam_member" "gsa_roles_pubsub" {
  project = var.gcp_project
  role    = "roles/pubsub.admin"   # Example role, adjust as needed
  member  = "serviceAccount:${google_service_account.gsa.email}"
}

# Create a Kubernetes Service Account (KSA) inside the cluster
resource "kubernetes_service_account" "ksa" {
  metadata {
    name      = local.ksa_name
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gsa.email
    }
  }
}

# Bind the KSA to the GSA using Workload Identity
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.gsa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project}.svc.id.goog[default/${local.ksa_name}]"
}
