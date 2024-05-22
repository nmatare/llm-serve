// Hosts backend serving clusters for large models
//
module "base" {
  source = "./src"

  project_id = local.project_id
  cloud      = local.cluster_cloud
  region     = local.cluster_region
  zones      = ["a"]

  node_pools = [
    // For RayKube Operator
    {
      name               = "persistent-gpu-backbone"
      machine_type       = "a2-highgpu-1g"
      min_count          = 1
      max_count          = 1
      initial_node_count = 1
      disk_size_gb       = 500
      preemptible        = false
      autoscaling        = true
      auto_repair        = true
      auto_upgrade       = true

      accelerator_count  = 1
      accelerator_type   = "nvidia-tesla-a100"
      gpu_driver_version = "LATEST"
    },
  ]

}

// Hosts provider models on shared cluster
//
# terraform destroy -target module.foundational_model_google-gemma
module "foundational_model_google-gemma" {
  source = "./serving"
  count  = 1

  settings = {
    # ref: https://github.com/ray-project/ray-llm
    model_name        = "google/gemma-2b"
    model_import_file = "model"
    model_import_path = "model:entrypoint" # model_import_file:app_name

    ray_k8_service_unhealthy_threshold     = 600
    ray_k8_deployment_unhealthy_threshold  = 600
    ray_k8_deployment_service_num_replicas = 1

    ray_image     = "anyscale/ray-llm"
    ray_image_tag = "0.5.0"

    ray_head_node_cpu_count = 2
    ray_head_node_memory    = "8Gi"

    ray_model_serving_max_replicas       = 1
    ray_model_serving_min_replicas       = 1
    ray_model_serving_cpu_count          = 8
    ray_model_serving_accelerator_marker = "nvidia.com/gpu"
    ray_model_serving_accelerator_type   = "nvidia-tesla-a100"
    ray_model_serving_accelerator_count  = 1
    ray_model_serving_accelerator_memory = "40Gi"

    secrets_huggingface = jsonencode(local.huggingface_secrets)
  }

  ray_operator_helm_chart_version = local.ray_operator_version
}
