#------------------------------------------------------------------------------
# MÓDULO DE MONITOREO BASADO EN HELM (KUBE-PROMETHEUS-STACK)
#------------------------------------------------------------------------------

# Nota: El namespace se crea dinámicamente mediante kubectl en el pipeline de CI/CD 
# para evitar dependencias del proveedor de Kubernetes con el localhost de EKS.
resource "helm_release" "kube_prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"
  namespace  = "monitoring"

  values = [
    file("${path.module}/values.yaml")
  ]
}
