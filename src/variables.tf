variable "region" {
  description = "The region of the cluster"
  type        = string
}

variable "cloud" {
  description = "The cloud provider (e.g., gcp, aws, azure)"
  type        = string
}

// Do not use `google_compute_zones` because this forces a reshuffle on each apply
variable "zones" {
  type        = list(string)
  description = <<-EOT
The zone(s) of the cluster. If length(zones) > 1, then the cluster will become regional.
EOT
}

variable "node_pools" {
  type        = list(map(string))
  description = "A list of node pool parameters describing the nodes to create"
}

variable "project_id" {
  description = "The project-id"
  type        = string
}

locals {
  cluster_name           = "${terraform.workspace}-serving-${var.cloud}-${var.region}"
  network                = "${local.cluster_name}-network"
  subnetwork             = "${local.cluster_name}-subnet"
  ip_range_pods_name     = "ip-range-pods"
  ip_range_services_name = "ip-range-scv"

  _has_accelerator_gpu = anytrue([for pool in var.node_pools : pool.accelerator_count > 0])
}
