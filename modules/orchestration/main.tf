# -------------------------------------------------
# 1. Segredos e configurações de máquina (talos_config)
# -------------------------------------------------
module "talos_config" {
  source = "../talos_config"

  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  talos_version    = var.talos_version
  patches_dir      = var.patches_dir

  controlplane_ips = [for name, node in var.nodes : node.ip if node.role == "controlplane"]
  node_ips         = [for name, node in var.nodes : node.ip]

  depends_on = []
}

# -------------------------------------------------
# 2. Aplicação das configs + bootstrap (talos_bootstrap)
# -------------------------------------------------
module "talos_bootstrap" {
  source = "../talos_bootstrap"

  nodes                = var.nodes
  apply_insecure       = var.apply_insecure
  controlplane_config  = module.talos_config.controlplane_config
  worker_config        = module.talos_config.worker_config
  client_configuration = module.talos_config.client_configuration

  depends_on = [module.talos_config]
}
