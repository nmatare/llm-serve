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
      machine_type       = "n1-standard-8"
      min_count          = 1
      max_count          = 1
      initial_node_count = 1
      disk_size_gb       = 500
      preemptible        = false
      autoscaling        = true
      auto_repair        = true
      auto_upgrade       = true

      accelerator_count = 2
      accelerator_type  = "nvidia-tesla-p100"
    },
  ]

  # https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/blob/main/ai-ml/gke-ray/rayserve/models/quantized-model.yaml

  settings = {
    # ref: https://github.com/ray-project/ray-llm
    ray_node_image                 = "anyscale/ray-llm"
    ray_node_image_tag             = "0.5.0"
    service_unhealthy_threshold    = 2400
    deployment_unhealthy_threshold = 2400

    ray_head_node_cpu_count = 2
    ray_head_node_memory    = "8Gi"

    ray_serving_accelerator_count  = 2
    ray_serving_accelerator_marker = "nvidia.com/gpu"
    ray_serving_accelerator_type   = "nvidia-tesla-p100"
    ray_serving_accelerator_memory = "40Gi"z
    # resources: '"{\"accelerator_type_cpu\": 22, \"accelerator_type_l4\": 2}"'

    ray_serving_cpu_count          = 20

    ray_serving_min_replicas = 1
    ray_serving_max_replicas = 2

  }

}

// Hosts provider models on shared cluster
//
# module "model_google-gemma" {
#   source = "./ray_serving"

#   # providers = {
#   #   argocd       = argocd
#   #   google       = google
#   #   kubernetes   = kubernetes.europe-west
#   #   kubectl      = kubectl.europe-west
#   #   kubectl.head = kubectl.europe-west
#   #   helm         = helm.europe-west
#   # }

#   cluster_name                    = local.cluster_name
#   region                          = local.cluster_region
#   ray_operator_helm_chart_version = local.ray_operator_version

# }
