# === VPC ===
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# === Subnet ===
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_primary_cidr
  region        = var.subnet_region
  network       = google_compute_network.vpc.id

  # Secondary ranges (for GKE IP aliasing)
  secondary_ip_range {
    range_name    = var.pods_secondary_range_name
    ip_cidr_range = var.pods_secondary_cidr
  }
  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_cidr
  }
}

# === GKE Cluster ===
resource "google_container_cluster" "gke" {
  count   = var.is_gke_cluster_enabled ? 1 : 0
  name    = var.cluster_name
  location = var.gcp_zone

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.name

  initial_node_count       = 1
  remove_default_node_pool = true
  deletion_protection      = false

  # ✅ Explicit disk settings
  node_config {
    disk_type    = "pd-standard"
    disk_size_gb = 50
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  release_channel {
    channel = "REGULAR"
  }

  # prevent Terraform from trying to update a node pool that no longer exists
  lifecycle {
    ignore_changes = [
      node_pool,  # ignore default node pool changes
    ]
  }
}

# === Node Pools ===
resource "google_container_node_pool" "node_pools" {
  for_each = { for np in var.node_pools : np.name => np }

  # ✅ Use full cluster ID so Terraform doesn’t break
  cluster  = google_container_cluster.gke[0].id
  location = var.gcp_zone
  name     = each.value.name

  node_config {
    machine_type = each.value.machine_type
    spot         = each.value.spot
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    disk_size_gb = lookup(each.value, "disk_size_gb", 100)
    disk_type    = lookup(each.value, "disk_type", "pd-standard")
  }

  autoscaling {
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }

  initial_node_count = each.value.initial_node_count

  # ✅ Wait until cluster is ready before creating node pools
  depends_on = [google_container_cluster.gke]
}

# === Addons (just an output for visibility) ===
output "enabled_addons" {
  value = var.addons
}
