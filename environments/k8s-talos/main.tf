module "orquestration" {
  source = "../../modules/orchestration"

  # Dados do cluster
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  talos_version    = var.talos_version
  nodes            = var.nodes
  apply_insecure   = var.apply_insecure

  patches_dir = "${path.module}/talos/configs/patches"
}
