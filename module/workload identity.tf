# ------------------------------------------------------------
# Workload Identity setup for GKE (Google Kubernetes Engine)
# ------------------------------------------------------------

# Create a Google Service Account (GSA) for workloads
resource "google_service_account" "gke_workload" {
  account_id   = "gke-test"
  display_name = "GKE Workload Identity Service Account"
}

# Create a Kubernetes Service Account (KSA) inside the cluster
resource "kubernetes_service_account" "ksa" {
  metadata {
    name      = "gke-test"   # Kubernetes service account name
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gke_workload.email
    }
  }
}

# Allow the KSA to impersonate the GSA using Workload Identity
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.gke_workload.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/gke-test]"
}
