##############################
# GKE Cluster Module
##############################
resource "google_container_cluster" "gke" {
  count    = var.is_gke_cluster_enabled ? 1 : 0
  name     = var.cluster_name
  location = var.gcp_region

  # Remove default node pool (we’ll define custom ones below)
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  release_channel {
    channel = "REGULAR"
  }

  min_master_version = var.cluster_version

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    dns_cache_config {
      enabled = true
    }
  }

  resource_labels = {
    env = var.env
  }
}

##############################
# Node Pools
##############################
resource "google_container_node_pool" "node_pools" {
  for_each = {
    for np in var.node_pools : np.name => np
  }

  cluster  = google_container_cluster.gke[0].name
  location = var.gcp_region
  name     = "${var.cluster_name}-${each.value.name}"

  node_config {
    machine_type = each.value.machine_type
    preemptible  = each.value.spot
    disk_size_gb = 50

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      type = each.value.spot ? "spot" : "ondemand"
    }

    tags = [
      "${var.cluster_name}-${each.value.name}-nodes"
    ]
  }

  autoscaling {
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }

  initial_node_count = each.value.initial_node_count

  management {
    auto_upgrade = true
    auto_repair  = true
  }
}

##############################
# GKE Addons (simulated)
##############################
resource "google_project_service" "addons" {
  for_each = {
    for idx, addon in var.addons : idx => addon
  }

  project = var.gcp_project
  service = each.value.name
}
