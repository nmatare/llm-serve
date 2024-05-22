resource "helm_release" "kuberay-operator" {
  name       = "kuberay-operator"
  repository = "https://ray-project.github.io/kuberay-helm/"
  chart      = "kuberay-operator"
  version    = var.ray_operator_helm_chart_version
  namespace  = kubernetes_namespace.ray.metadata[0].name
  wait       = true
}

# ref: https://ray-project.github.io/kuberay/reference/api/#rayservicespec
resource "kubectl_manifest" "ray_model_service" {
  depends_on = [helm_release.kuberay-operator]
  yaml_body  = <<YAML
apiVersion: ray.io/v1
kind: RayService
metadata:
  name: ${local.model_qualified_name}
  namespace: ${kubernetes_namespace.ray.metadata[0].name}
spec:
  serviceUnhealthySecondThreshold: ${var.settings.ray_k8_service_unhealthy_threshold}
  deploymentUnhealthySecondThreshold: ${var.settings.ray_k8_deployment_unhealthy_threshold}
  serveConfigV2: |
    applications:
    - name: ${local.model_qualified_name}
      route_prefix: /
      import_path: models.${var.settings.model_import_path}
      runtime_env:
        env_vars:
          RAY_SERVE_NUM_REPLICAS: "1"
        pip:
        - transformers==4.41.0  # patch for gemma model in latest transformers lib

  rayClusterConfig:
    headGroupSpec:
      rayStartParams:
        # resources: '"{\"accelerator_type_cpu\": ${var.settings.ray_head_node_cpu_count}}"'
        dashboard-host: '0.0.0.0'
        block: 'true'
      template:
        spec:
          containers:
          - name: ray-head-node
            image: ${var.settings.ray_image}:${var.settings.ray_image_tag}
            env:
            - name: HUGGINGFACE_API_SECRET
              valueFrom:
                secretKeyRef:
                  name: ${kubectl_manifest.huggingface_secrets.name}
                  key: HUGGINGFACE_API_SECRET
            resources:
              requests:
                cpu: "${var.settings.ray_head_node_cpu_count}"
                memory: "${var.settings.ray_head_node_memory}"
              limits:
                cpu: "${var.settings.ray_head_node_cpu_count}"
                memory: "${var.settings.ray_head_node_memory}"
            volumeMounts:
            - mountPath: /home/ray/models
              name: hosted-${local.model_qualified_name}-model
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
          - name: hosted-${local.model_qualified_name}-model
            configMap:
              name: ${kubernetes_config_map.model_src.metadata[0].name}
              items:
              - key: ${var.settings.model_import_file}.py
                path: ${var.settings.model_import_file}.py

    workerGroupSpecs:
    - replicas: ${var.settings.ray_model_serving_min_replicas}
      minReplicas: ${var.settings.ray_model_serving_min_replicas}
      maxReplicas: ${var.settings.ray_model_serving_max_replicas}
      groupName: ${local.model_qualified_name}-group
      # ref: https://docs.ray.io/en/latest/cluster/kubernetes/user-guides/config.html#ray-start-parameters
      rayStartParams:
        block: 'true'
        num-gpus: "${var.settings.ray_model_serving_accelerator_count}"

        # resources: '"{\"accelerator_type_cpu\": 12, \"accelerator_type_t4\": 1}"'
      template:
        spec:
          containers:
          - name: ray-worker-node
            image: ${var.settings.ray_image}:${var.settings.ray_image_tag}
            env:
            - name: HUGGINGFACE_API_SECRET
              valueFrom:
                secretKeyRef:
                  name: ${kubectl_manifest.huggingface_secrets.name}
                  key: HUGGINGFACE_API_SECRET
            lifecycle:
              preStop:
                exec:
                  command: ["/bin/sh","-c","ray stop"]
            resources:
              # ref: https://docs.ray.io/en/latest/cluster/kubernetes/user-guides/gpu.html
              requests:
                cpu: "${var.settings.ray_model_serving_cpu_count}"
                memory: "${var.settings.ray_model_serving_accelerator_memory}"
                # nvidia.com/gpu: "1"
                ${var.settings.ray_model_serving_accelerator_marker}: "${var.settings.ray_model_serving_accelerator_count}"
              limits:
                cpu: "${var.settings.ray_model_serving_cpu_count}"
                memory: "${var.settings.ray_model_serving_accelerator_memory}"
                # nvidia.com/gpu: "1"
                ${var.settings.ray_model_serving_accelerator_marker}: "${var.settings.ray_model_serving_accelerator_count}"
          tolerations:
            - key: "ray.io/node-type"
              operator: "Equal"
              value: "worker"
              effect: "NoSchedule"
          nodeSelector:
            cloud.google.com/gke-accelerator: ${var.settings.ray_model_serving_accelerator_type}
            cloud.google.com/gke-gpu-driver-version: latest
YAML
}
