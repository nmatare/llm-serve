resource "helm_release" "kuberay-operator" {
  name       = "kuberay-operator"
  repository = "https://ray-project.github.io/kuberay-helm/"
  chart      = "kuberay-operator"
  version    = var.ray_operator_helm_chart_version
  namespace  = kubernetes_namespace.ray.metadata[0].name
  values     = [file("${path.module}/ray/values.yaml")]
}

locals {
  model_name                   = "gemma"
  model_import_file            = "model"
  model_import_path            = "${local.model_import_file}:entrypoint"
  model_huggingface_model_name = "hf-gemma"

  settings_ray_node_image                   = "anyscale/ray-llm"
  settings_ray_node_image_tag               = "0.5.0"
  settings_service_unhealthy_threshold      = 2400
  settings_deployment_unhealthy_threshold   = 2400
  settings_deployment_service_num_replicaas = 1

  settings_ray_head_node_cpu_count = 2
  settings_ray_head_node_memory    = "8Gi"

  settings_ray_serving_gpu_count  = 2
  settings_ray_serving_gpu_type   = ""
  settings_ray_serving_gpu_memory = "40Gi"
  settings_ray_serving_cpu_count  = 20

  settings_ray_model_serving_min_replicas = 1
  settings_ray_model_serving_max_replicas = 2
}

resource "kubectl_manifest" "ray_model_service" {
  depends_on = [helm_release.kuberay-operator]
  yaml_body  = <<YAML
apiVersion: ray.io/v1
kind: RayService
metadata:
  name: ${var.gemma_model_service_name}
spec:
  serviceUnhealthySecondThreshold: ${local.settings_service_unhealthy_threshold}
  deploymentUnhealthySecondThreshold: ${local.settings_deployment_unhealthy_threshold}

  serveConfigV2: |
    applications:
    - name: ${local.model_name}
      route_prefix: /
      import_path: ${local.model_import_path}

      # runtime_env:
      #   env_vars:
      #     MODEL_ID: "meta-llama/Llama-2-70b-chat-hf"
      #     PYTHONPATH: "$${HOME}/models"
      #   pip:
      #   - bitsandbytes==0.42.0

      deployments:
      - name: Chat
        num_replicas: ${local.settings_deployment_service_num_replicaas}

  rayClusterConfig:
   headGroupSpec:
      rayStartParams:
        # resources: '"{\"accelerator_type_cpu\": ${local.settings_ray_head_node_cpu_request}}"'
        dashboard-host: '0.0.0.0'
        block: 'true'
      template:
        spec:
          containers:
          - name: ray-head-node
            image: ${local.settings_ray_node_image}:${local.settings_ray_node_image_tag}
            resources:
              requests:
                cpu: "${local.settings_ray_head_node_cpu_count}"
                memory: "${local.settings_ray_head_node_memory}"
              limits:
                cpu: "${local.settings_ray_head_node_cpu_count}"
                memory: "${local.settings_ray_head_node_memory}"
            volumeMounts:
            - mountPath: /home/ray/models
              name: hosted-${local.model_name}-model
            ports:
            - containerPort: 6379
              name: gcs-server
            - containerPort: 8265 # Ray dashboard
              name: dashboard
            - containerPort: 10001
              name: client
            - containerPort: 8000
              name: serve
          volumes:
          - name: hosted-${local.settings.model_name}-model
            configMap:
              name: ${resource.kubernetes_config_map.model_name.metadata[0].name}
              items:
              - key: ${local.settings_model_import_file}.py
                path: ${local.setings.model_import_file}.py

    workerGroupSpecs:
    - replicas: ${local.settings_ray_serving_min_replicas}
      minReplicas: ${local.settings_ray_serving_min_replicas}
      maxReplicas: ${local.settings_ray_serving_max_replicas}
      # groupName: gpu-group
      rayStartParams:
        block: 'true'
        # resources: '"{\"accelerator_type_cpu\": 22, \"accelerator_type_l4\": 2}"'
      template:
        spec:
          containers:
          - name: ray-worker-node
            image: ${local.settings_ray_node_image}:${local.settings_ray_node_image_tag}
            env:
            - name: HUGGINGFACE_API
              valueFrom:
                secretKeyRef:
                  name: ${kubectl_manifest.huggingface_secrets.metadata[0].name}
                  key: HUGGINGFACE_API_SECRET
            lifecycle:
              preStop:
                exec:
                  command: ["/bin/sh","-c","ray stop"]
            resources:
              requests:
                cpu: "${local.setting_ray_serving_cpu_count}"
                memory: "${local.settings_ray_serving_gpu_memory}"
                ${local.settings.accelerator_marker}: "${local.settings_ray_serving_gpu_count}"
              limits:
                cpu: "${local.settings_ray_serving_cpu_count}"
                memory: "${local.settings_ray_serving_gpu_memory}"
                ${local.settings.accelerator_marker}: "${local.settings_ray_serving_gpu_count}"
          tolerations:
            - key: "ray.io/node-type"
              operator: "Equal"
              value: "worker"
              effect: "NoSchedule"
          nodeSelector:
            cloud.google.com/gke-accelerator: ${local.settings_ray_serving_gpu_type}
YAML
}

