#------------------------------------------------------------------------------
# MÓDULO DE MONITOREO BASADO EN HELM (KUBE-PROMETHEUS-STACK)
#------------------------------------------------------------------------------

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}
