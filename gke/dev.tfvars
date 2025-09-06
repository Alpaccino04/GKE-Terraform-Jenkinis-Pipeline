gcp_project = "fair-plasma-441014-q1"
gcp_region  = "us-central1"
gcp_zone    = "us-central1-a"

vpc_name    = "dev-vpc"
subnet_name = "dev-subnet"
subnet_region       = "us-central1"
subnet_primary_cidr = "10.0.0.0/24"

pods_secondary_range_name     = "pods-range"
pods_secondary_cidr           = "10.1.0.0/16"
services_secondary_range_name = "services-range"
services_secondary_cidr       = "10.2.0.0/20"

is_gke_cluster_enabled = true
cluster_name           = "dev-gke-cluster"

node_pools = [
  {
    name               = "default-pool"
    machine_type       = "e2-medium"
    min_count          = 1
    max_count          = 3
    initial_node_count = 1
    spot               = true
    disk_size_gb       = 50
    disk_type          = "pd-standard"
  },
  {
    name               = "cpu-pool"
    machine_type       = "e2-standard-4"
    min_count          = 0
    max_count          = 5
    initial_node_count = 1
    spot               = false
    disk_size_gb       = 100
    disk_type          = "pd-standard"
  }
]


addons = ["Monitoring", "Logging"]
