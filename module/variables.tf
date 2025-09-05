# =====================================================
# GCP Module Variables (Workload Identity + GKE)
# =====================================================

# General / Project
variable "cluster_name" {}
variable "env" {}
variable "gcp_project" {}
variable "gcp_region" {}
variable "gcp_zone" {}

# Networking / VPC
variable "vpc_name" {}
variable "subnet_name" {}
variable "subnet_primary_cidr" {}
variable "pods_secondary_range_name" {}
variable "pods_secondary_cidr" {}
variable "services_secondary_range_name" {}
variable "services_secondary_cidr" {}

# GKE Cluster
variable "is_gke_cluster_enabled" {}
variable "cluster_version" {}

# Node Pools
variable "node_pools" {
  type = list(object({
    name               = string
    machine_type       = string
    min_count          = number
    max_count          = number
    initial_node_count = number
    spot               = bool
  }))
}

# Addons
variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
}

# Workload Identity (IAM equivalent)
variable "is_gsa_enabled" {
  type = bool
  default = true
}
