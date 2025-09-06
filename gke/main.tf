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
  location = var.gcp_region

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.name

  initial_node_count       = 1
  remove_default_node_pool = true

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  release_channel {
    channel = "REGULAR"
  }

}

# === Node Pools ===
resource "google_container_node_pool" "node_pools" {
  for_each = { for np in var.node_pools : np.name => np }

  cluster  = google_container_cluster.gke[0].name
  location = var.gcp_region
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
}

# === Addons (just an output for visibility) ===
output "enabled_addons" {
  value = var.addons
}
