# -------------------------------------------------
# 1. Segredos do cluster
#    Equivalente ao secrets.yaml do `talosctl gen config`.
#    Fica apenas no tfstate (sensitive).
# -------------------------------------------------
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

# -------------------------------------------------
# 2. Patches (lidos do diretório de patches)
#    Por enquantos são estáticos, depois tento fazer com templates
# -------------------------------------------------
locals {
  common_patches = sort([
    for f in fileset(var.patches_dir, "common/*.yaml") :
    file("${var.patches_dir}/${f}")
  ])

  controlplane_patches = sort([
    for f in fileset(var.patches_dir, "controlplane/*.yaml") :
    file("${var.patches_dir}/${f}")
  ])

  worker_patches = sort([
    for f in fileset(var.patches_dir, "worker/*.yaml") :
    file("${var.patches_dir}/${f}")
  ])
}

# -------------------------------------------------
# 3. Configurações de máquina
#    Equivalentes ao controlplane.yaml / worker.yaml.
#    Geradas em memória: nenhum arquivo é gravado em disco.
# -------------------------------------------------
data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  docs             = false
  examples         = false

  config_patches = concat(local.common_patches, local.controlplane_patches)
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  docs             = false
  examples         = false

  config_patches = concat(local.common_patches, local.worker_patches)
}

# -------------------------------------------------
# 4. talosconfig do cliente
# -------------------------------------------------
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = var.node_ips
  endpoints            = var.controlplane_ips
}
