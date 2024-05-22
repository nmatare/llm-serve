variable "node_pools_auth_scopes" {
  type        = map(list(string))
  description = "Map of lists containing node oauth scopes by node-pool name"
  default = {
    default = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/monitoring",
    ]

    persistent-gpu-backbone = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/devstorage.full_control",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/taskqueue"
    ]

  }
}

variable "node_pools_taints" {
  type        = map(list(object({ key = string, value = string, effect = string })))
  description = "Map of lists containing node taints by node-pool name"

  default = {
    default             = []
    persistent-backbone = []

    ephemeral-node = [
      {
        key    = "cloud.google.com/preemptible" # not a k8 default taint
        value  = true
        effect = "NO_SCHEDULE"
      },
    ]

    persistent-highmem = [
      {
        key    = "cloud.google.com/gke-highmem" # not a k8 default taint
        value  = true
        effect = "NO_SCHEDULE"
      },
    ]
  }
}

variable "node_pools_labels" {
  type    = map(map(string))
  default = {}
}

module "gcp_network" {
  source       = "terraform-google-modules/network/google"
  project_id   = var.project_id
  network_name = local.cluster_name
  subnets = [
    {
      subnet_name   = "${local.subnetwork}"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    "${local.subnetwork}" = [
      {
        range_name    = local.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = local.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}


module "gke" {
  depends_on                 = [module.gcp_network, ]
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  name                       = local.cluster_name
  network                    = module.gcp_network.network_name
  subnetwork                 = module.gcp_network.subnets_names[0]
  ip_range_pods              = local.ip_range_pods_name
  ip_range_services          = local.ip_range_services_name
  create_service_account     = true
  grant_registry_access      = true
  deletion_protection        = false
  node_pools                 = var.node_pools
  node_pools_oauth_scopes    = var.node_pools_auth_scopes
  horizontal_pod_autoscaling = true
  node_pools_labels          = var.node_pools_labels
  node_pools_taints          = var.node_pools_taints
  region                     = var.region
  zones                      = [for zone in var.zones : "${var.region}-${zone}"]
  node_metadata              = "GKE_METADATA_SERVER"
  # Prevent verbose logging from cluster
  logging_service = null
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

}

data "google_client_config" "cluster" {}

output "cluster_name" {
  value     = module.gke.name
  sensitive = false
}

output "cluster_host" {
  description = "The GKE cluster endpoint"
  value       = nonsensitive(module.gke.endpoint)
}

output "cluster_ca_certificate" {
  description = "Public cluster CA certificate (base64 encoded) "
  value       = module.gke.ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The cluster location (region if regional cluster, zone if zonal cluster)"
  value       = module.gke.location
}

output "cluster_service_account" {
  description = "The cluster service account"
  value       = module.gke.service_account
}
