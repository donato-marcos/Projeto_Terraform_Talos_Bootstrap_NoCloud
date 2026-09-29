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

variable "apply_insecure" {
  description = "Usar conexão insegura ao aplicar a config nos nós em maintenance mode"
  type        = bool
  default     = true
}

variable "patches_dir" {
  description = "Diretório com os patches (subdiretórios common/, controlplane/ e worker/)"
  type        = string
}

variable "nodes" {
  description = "Mapa de nós Talos em modo maintenance"
  type = map(object({
    role = string
    ip   = string
  }))
}
