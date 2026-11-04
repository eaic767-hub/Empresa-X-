#------------------------------------------------------------------------------
# MÓDULO DE MONITOREO BASADO EN HELM (KUBE-PROMETHEUS-STACK)
#------------------------------------------------------------------------------

# Nota: El namespace se crea dinámicamente mediante kubectl en el pipeline de CI/CD 
# para evitar dependencias del proveedor de Kubernetes con el localhost de EKS.
