output "talosconfig" {
  description = "talosconfig do cluster"
  value       = module.talos_config.talosconfig
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig do cluster"
  value       = module.talos_bootstrap.kubeconfig
  sensitive   = true
}

output "machine_config_controlplane" {
  description = "Configuração de máquina do control plane (com patches aplicados)"
  value       = module.talos_config.controlplane_config
  sensitive   = true
}

output "machine_config_worker" {
  description = "Configuração de máquina do worker (com patches aplicados)"
  value       = module.talos_config.worker_config
  sensitive   = true
}
