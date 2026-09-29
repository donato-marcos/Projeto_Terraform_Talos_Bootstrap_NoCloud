# --- Cluster ---
cluster_name     = "k8s-cluster"
cluster_endpoint = "https://172.16.200.10:6443" # VIP (K8S_API_VIP) definido no patch controlplane/vip.yaml
talos_version    = "v1.14.0"

# --- Nós ---
# Pré-requisito: VMs bootadas em modo maintenance (ISO Talos),
# com IP acessível a partir da máquina que roda o Terraform.
nodes = {
  "talos-cp01" = { role = "controlplane", ip = "172.16.1.11" }
  "talos-cp02" = { role = "controlplane", ip = "172.16.1.12" }
  "talos-cp03" = { role = "controlplane", ip = "172.16.1.13" }

  "talos-worker01" = { role = "worker", ip = "172.16.1.21" }
  "talos-worder02" = { role = "worker", ip = "172.16.1.22" }
  "talos-worker03" = { role = "worker", ip = "172.16.1.23" }
}
