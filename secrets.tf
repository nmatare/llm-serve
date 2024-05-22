// HuggingFace Secrets
data "google_secret_manager_secret_version" "environment-huggingface-secrets" {
  project = local.project_id
  secret  = "${terraform.workspace}-huggingface-readwrite"
}

locals {
  _deploy_secrets      = data.google_secret_manager_secret_version.environment-huggingface-secrets.secret_data
  _flat_deploy_secrets = compact(split("\n", local._deploy_secrets))
  huggingface_secrets  = sensitive({ for k in local._flat_deploy_secrets : split("=", k)[0] => split("=", k)[1] })
}
