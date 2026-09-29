# --- Cluster ---
variable "cluster_name" {
  description = "Nome do cluster Kubernetes/Talos"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint da API do Kubernetes (VIP do control plane)"
  type        = string
}

variable "talos_version" {
  description = "Versão do Talos usada na geração das configs (null = última estável)"
  type        = string
  default     = null
}

variable "patches_dir" {
  description = "Diretório com os patches (subdiretórios common/, controlplane/ e worker/)"
  type        = string
}

# --- Nós ---
variable "controlplane_ips" {
  description = "IPs dos control planes (endpoints da API Talos)"
  type        = list(string)
}

variable "node_ips" {
  description = "IPs de todos os nós (registrados no talosconfig)"
  type        = list(string)
}
