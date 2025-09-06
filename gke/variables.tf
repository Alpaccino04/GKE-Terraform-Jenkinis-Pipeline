variable "gcp_project" {
  description = "The GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "Default region for resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Default zone for resources"
  type        = string
  default     = "us-central1-a"
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "subnet_region" {
  description = "Region where subnet will be created"
  type        = string
}

variable "subnet_primary_cidr" {
  description = "Primary CIDR range for the subnet"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary range for GKE Pods"
  type        = string
}

variable "pods_secondary_cidr" {
  description = "CIDR range for GKE Pods"
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary range for GKE Services"
  type        = string
}

variable "services_secondary_cidr" {
  description = "CIDR range for GKE Services"
  type        = string
}

variable "is_gke_cluster_enabled" {
  description = "Whether to enable GKE cluster creation"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}


variable "node_pools" {
  description = "List of node pools for the GKE cluster"
  type = list(object({
    name               = string
    machine_type       = string
    min_count          = number
    max_count          = number
    initial_node_count = number
    spot               = bool
    disk_size_gb       = optional(number, 100)       # default 100GB
    disk_type          = optional(string, "pd-standard") # default pd-standard
  }))
}

variable "addons" {
  description = "List of GKE addons to enable (e.g. Monitoring, Logging)"
  type        = list(string)
  default     = []
}
