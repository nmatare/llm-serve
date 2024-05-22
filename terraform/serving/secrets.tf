locals {
  huggingface_artifact_secret = "huggingface-secrets" # name of the k8 secret
  huggingface_secrets = jsondecode(var.settings.secrets_huggingface)
}

resource "kubectl_manifest" "huggingface_secrets" {

  yaml_body = <<-EOS
apiVersion: v1
kind: Secret
metadata:
  name: ${local.huggingface_artifact_secret}
  namespace: ${kubernetes_namespace.ray.metadata[0].name}
type: Opaque
stringData:
  HUGGINGFACE_API_KEY: ${local.huggingface_secrets["HUGGINGFACE_API_KEY"]}
  HUGGINGFACE_API_SECRET: ${local.huggingface_secrets["HUGGINGFACE_API_SECRET"]}
EOS

  sensitive_fields = ["stringData"]
}
