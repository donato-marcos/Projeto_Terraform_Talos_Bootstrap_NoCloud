output "controlplane_config" {
  description = "Configuração de máquina do control plane (com patches de common/ + controlplane/)"
  value       = data.talos_machine_configuration.controlplane.machine_configuration
  sensitive   = true
}

output "worker_config" {
  description = "Configuração de máquina do worker (com patches de common/ + worker/)"
  value       = data.talos_machine_configuration.worker.machine_configuration
  sensitive   = true
}

output "client_configuration" {
  description = "Certificados de cliente para a API Talos (usado pelos demais módulos)"
  value       = talos_machine_secrets.this.client_configuration
  sensitive   = true
}

output "talosconfig" {
  description = "talosconfig do cluster"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}
