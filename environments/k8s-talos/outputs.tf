output "talosconfig" {
  description = "talosconfig do cluster (equivalente ao arquivo gerado por talosctl gen config)"
  value       = module.orquestration.talosconfig
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig do cluster"
  value       = module.orquestration.kubeconfig
  sensitive   = true
}

output "nodes" {
  description = "Nós configurados"
  value       = var.nodes
}
