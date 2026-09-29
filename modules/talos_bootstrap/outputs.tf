output "kubeconfig" {
  description = "Kubeconfig do cluster"
  value       = resource.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "bootstrapped_node" {
  description = "Nó (IP) onde o bootstrap foi executado"
  value       = local.first_controlplane_ip
}
