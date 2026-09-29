# --- Nós ---
variable "nodes" {
  description = "Mapa de nós Talos em modo maintenance"
  type = map(object({
    role = string
    ip   = string
  }))
}

# --- Configurações geradas pelo módulo talos_config ---
variable "controlplane_config" {
  description = "Configuração de máquina do control plane (com patches aplicados)"
  type        = string
  sensitive   = true
}

variable "worker_config" {
  description = "Configuração de máquina do worker (com patches aplicados)"
  type        = string
  sensitive   = true
}

variable "client_configuration" {
  description = "Certificados de cliente para a API Talos"
  type        = any
  sensitive   = true
}

# --- Modo maintenance ---
variable "apply_insecure" {
  description = "Usar conexão insegura ao aplicar a config (necessário enquanto os nós estão em maintenance mode, equivale ao --insecure do talosctl)"
  type        = bool
  default     = true
}

# --- Timeouts ---
variable "health_check_timeout" {
  description = "Tempo máximo aguardando o cluster ficar saudável após o bootstrap (ex: 10m)"
  type        = string
  default     = "10m"
}
