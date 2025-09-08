# === VPC ===
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# === Subnet (with secondary ranges for GKE IP aliasing) ===
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_primary_cidr
  region        = var.subnet_region
  network       = google_compute_network.vpc.id

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
  count    = var.is_gke_cluster_enabled ? 1 : 0
  name     = var.cluster_name
  location = var.gcp_zone

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.name

  initial_node_count       = 1
  remove_default_node_pool = true
  deletion_protection      = false

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  release_channel {
    channel = "REGULAR"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true   # 👈 Public control plane endpoint
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "iap-proxy"
      cidr_block   = "35.235.240.0/20"
    }

    cidr_blocks {
      display_name = "my-pc"
      cidr_block   = "102.90.103.77/32"
    }
  }

  lifecycle {
    ignore_changes = [node_pool]
  }
}

# === Node Pools ===
resource "google_container_node_pool" "node_pools" {
  for_each = { for np in var.node_pools : np.name => np }

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

  depends_on = [google_container_cluster.gke]
}

# === Enable OS Login at project level ===
resource "google_compute_project_metadata_item" "enable_oslogin" {
  project = var.gcp_project
  key     = "enable-oslogin"
  value   = "TRUE"
}

# === Output (optional) ===
output "enabled_addons" {
  value = var.addons
}
