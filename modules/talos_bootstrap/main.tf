# -------------------------------------------------
# Locais: separação por role e primeiro control plane
# -------------------------------------------------
locals {
  controlplane_nodes = {
    for name, node in var.nodes : name => node
    if node.role == "controlplane"
  }

  worker_nodes = {
    for name, node in var.nodes : name => node
    if node.role == "worker"
  }

  # Primeiro control plane (ordem alfabética) recebe o bootstrap
  first_controlplane_name = sort(keys(local.controlplane_nodes))[0]
  first_controlplane_ip   = local.controlplane_nodes[local.first_controlplane_name].ip
}

# -------------------------------------------------
# 1. Aplicação da configuração em todos os nós
#    Um patch por nó define o hostname (nome da chave no mapa).
# -------------------------------------------------
resource "talos_machine_configuration_apply" "this" {
  for_each = var.nodes

  client_configuration        = var.client_configuration
  machine_configuration_input = each.value.role == "controlplane" ? var.controlplane_config : var.worker_config
  node                        = each.value.ip
  endpoint                    = each.value.ip
  
}

# -------------------------------------------------
# 2. Bootstrap do cluster (executado no primeiro control plane)
# -------------------------------------------------
resource "talos_machine_bootstrap" "this" {
  node                 = local.first_controlplane_ip
  endpoint             = local.first_controlplane_ip
  client_configuration = var.client_configuration

  depends_on = [talos_machine_configuration_apply.this]
}

# -------------------------------------------------
# 3. Aguarda o cluster ficar saudável
# -------------------------------------------------
data "talos_cluster_health" "this" {
  client_configuration = var.client_configuration
  control_plane_nodes  = [for name, node in local.controlplane_nodes : node.ip]
  worker_nodes         = [for name, node in local.worker_nodes : node.ip]
  endpoints            = [for name, node in local.controlplane_nodes : node.ip]
  skip_kubernetes_checks = true

  depends_on = [talos_machine_bootstrap.this]
}

# -------------------------------------------------
# 4. Recuperação do kubeconfig
# -------------------------------------------------
resource "talos_cluster_kubeconfig" "this" {
  node                 = local.first_controlplane_ip
  endpoint             = local.first_controlplane_ip
  client_configuration = var.client_configuration

  depends_on = [data.talos_cluster_health.this]
}
