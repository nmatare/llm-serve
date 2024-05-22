variable "ray_operator_helm_chart_version" {
  description = "The helm chart version for the ray operator"
  type        = string
}

variable "settings" {
  description = "The settings"
  type        = map(string)
}

locals {
  model_qualified_name = replace("${var.settings.model_name}-model-server", "/[^a-z0-9.-]/", "-")
}
