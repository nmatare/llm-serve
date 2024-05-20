// Namespaces are local to the cluster (they are not exported to the fleet)
resource "kubernetes_namespace" "ray" {
  metadata { name = "ray" }
}
