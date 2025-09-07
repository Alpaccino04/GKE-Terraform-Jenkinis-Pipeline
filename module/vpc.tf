locals {
  cluster_name = var.cluster_name
}

# -----------------------------
# VPC Network
# -----------------------------
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# -----------------------------
# Subnet
# -----------------------------
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_primary_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
}

# -----------------------------
# GKE IP Alias Ranges
# -----------------------------
resource "google_compute_subnetwork" "subnet_with_secondary_ranges" {
  name          = "${var.subnet_name}-secondary"
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_primary_cidr

  secondary_ip_range {
    range_name    = var.pods_secondary_range_name
    ip_cidr_range = var.pods_secondary_cidr
  }

  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_cidr
  }
}

# -----------------------------
# Firewall Rules (locked to IAP)
# -----------------------------
resource "google_compute_firewall" "gke_firewall" {
  name    = "${var.env}-${local.cluster_name}-fw"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  # Restrict to IAP proxy range only
  source_ranges = ["35.235.240.0/20"]

  direction   = "INGRESS"
  target_tags = ["gke-cluster"]
}

resource "google_compute_firewall" "gke_egress" {
  name    = "${var.env}-${local.cluster_name}-egress"
  network = google_compute_network.vpc.id

  allow {
    protocol = "all"
  }

  direction           = "EGRESS"
  destination_ranges  = ["0.0.0.0/0"]
}

# -----------------------------
# Cloud NAT for Private Nodes (equivalent of AWS NAT Gateway)
# -----------------------------
resource "google_compute_router" "nat_router" {
  name    = "${var.env}-${local.cluster_name}-router"
  network = google_compute_network.vpc.id
  region  = var.gcp_region
}

resource "google_compute_router_nat" "nat" {
  name                              = "${var.env}-${local.cluster_name}-nat"
  router                            = google_compute_router.nat_router.name
  region                            = var.gcp_region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
