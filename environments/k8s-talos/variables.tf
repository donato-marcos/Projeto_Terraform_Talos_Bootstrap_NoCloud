# --- Conexão Libvirt/KVM (reservado) ---
variable "libvirt_uri" {
  description = "URI de conexão com o host Libvirt/KVM"
  type        = string
  default     = "qemu:///system"
}

# --- Cluster Talos ---
variable "cluster_name" {
  description = "Nome do cluster Kubernetes/Talos"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint da API do Kubernetes (normalmente o VIP do control plane, conforme patch vip.yaml)"
  type        = string
}

variable "talos_version" {
  description = "Versão do Talos para gerar as configs (ex: v1.12.6). null = última estável suportada pelo provider"
  type        = string
  default     = null
}

variable "apply_insecure" {
  description = "Usar conexão insegura ao aplicar a config nos nós em maintenance mode (false após o cluster instalado)"
  type        = bool
  default     = true
}

variable "nodes" {
  description = "Mapa de nós Talos já em modo maintenance e acessíveis pela rede"
  type = map(object({
    role = string
    ip   = string
  }))

  validation {
    condition     = alltrue([for n in var.nodes : contains(["controlplane", "worker"], n.role)])
    error_message = "role deve ser 'controlplane' ou 'worker'."
  }
}

variable "patches_dir" {
  description = "Diretório com os patches de configuração (common/, controlplane/ e worker/)"
  type        = string
}
