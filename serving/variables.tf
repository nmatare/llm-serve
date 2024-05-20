variable "ray_operator_helm_chart_version" {
  description = "The helm chart version for the ray operator"
  type        = string
}

variable "gemma_model_service_name" {
  description = "The name of the RayService hosting the Gemma model clas"
  type        = string
  default     = "gemma-service"
}
