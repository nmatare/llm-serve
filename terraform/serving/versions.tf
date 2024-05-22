terraform {
  required_version = "~> 1.8.3"

  required_providers {

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.2"
    }

  }

}

# provider "kubernetes" {
#   host                   = "https://${module.base.cluster_host}"
#   token                  = data.google_client_config.infrastructure.access_token
#   cluster_ca_certificate = base64decode(module.gke.ca_certificate)
# }

# provider "kubectl" {
#   host                   = "https://${module.base.cluster_host}"
#   token                  = data.google_client_config.infrastructure.access_token
#   cluster_ca_certificate = base64decode(module.gke.ca_certificate)
#   load_config_file       = false
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://${module.base.cluster_host}"
#     token                  = data.google_client_config.infrastructure.access_token
#     cluster_ca_certificate = base64decode(module.gke.ca_certificate)
#   }
# }
