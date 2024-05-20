terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }

  }
}

provider "google-beta" {
  region = var.region
}

data "google_client_config" "infrastructure" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.infrastructure.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}
