locals {
  dotenv = { for tuple in regexall("(.*)=(.*)", file(".env")) : tuple[0] => tuple[1] }
}

locals {
  organization_name = local.dotenv["GOOGLE_INFRASTRUCTURE_ORGANIZATION_NAME"]
  organization_id   = local.dotenv["GOOGLE_INFRASTRUCTURE_ORGANIZATION_ID"]
  billing_account   = local.dotenv["GOOGLE_INFRASTRUCTURE_BILLING_ACCOUNT"]
  project_id        = local.dotenv["GOOGLE_INFRASTRUCTURE_PROJECT_ID"]
  project_name      = local.dotenv["GOOGLE_INFRASTRUCTURE_PROJECT_NAME"]

  github_repo_url          = local.dotenv["GITHUB_REPO_URL"]
  github_repo_organization = local.dotenv["GITHUB_REPO_ORGANIZATION"]

  cluster_cloud  = local.dotenv["CLUSTER_CLOUD"]
  cluster_name   = local.dotenv["CLUSTER_NAME"]
  cluster_region = local.dotenv["CLUSTER_REGION"]

  ray_operator_version = local.dotenv["RAY_OPERATOR_STACK_VERSION"]

}

output "billing_account" {
  description = "The ID of the billing account to associate this project with"
  value       = local.billing_account
}

output "organization_id" {
  description = "Google Cloud organization ID"
  value       = local.organization_id
}

output "organization_name" {
  description = "Google Cloud organization name"
  value       = local.organization_name
}

output "project_name" {
  description = "Project short name"
  value       = local.project_name
}

output "project_id" {
  description = "Google Cloud project ID"
  value       = local.project_id
}

output "github_repo_url" {
  description = "Github repository URL"
  value       = local.github_repo_url
}

output "github_repo_organization" {
  description = "Github repository organization"
  value       = local.github_repo_organization
}

output "cluster_name" {
  value = module.base.cluster_name
}

output "cluster_host" {
  value     = module.base.cluster_host
  sensitive = false
}

output "cluster_ca_certificate" {
  value     = module.base.cluster_ca_certificate
  sensitive = true
}

output "cluster_service_account" {
  value = module.base.cluster_service_account
}
