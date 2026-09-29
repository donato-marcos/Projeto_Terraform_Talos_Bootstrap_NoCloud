# Talos Linux Bootstrap — Terraform/OpenTofu

Automação do bootstrap de um cluster Kubernetes sobre **Talos Linux v1.14** em VMs pré-provisionadas. O projeto cuida apenas da camada **Talos + Kubernetes**: geração de secrets, aplicação de configuração, bootstrap do etcd, health check, kubeconfig e (opcionalmente) instalação de Helm charts como Cilium, Tetragon e ArgoCD.

> ⚠️ **Pré-requisito fundamental:** as VMs com Talos **já devem existir** e ter **IPs fixos** configurados. Este projeto **não cria VMs**.

---

## 📋 Pré-requisitos

### 1. VMs Talos já provisionadas

Você precisa ter, no mínimo:

- **1 control plane** (recomendado: 3 para HA)
- **N workers** (opcional, mas necessário para workloads)

Cada VM deve ter:

- **Talos Linux** já bootado em **modo maintenance** (via ISO ou imagem cloud).
- **IP fixo** em pelo menos uma interface de gerenciamento (a que o Terraform usará para conversar com a API do Talos, porta 50000).
- Acesso de rede a partir da máquina que executa o Terraform/OpenTofu.
- Pelo menos 2 GB de RAM por nó, 2 vCPUs e disco conforme o workload.
- **Firmware EFI** e **Secure Boot** recomendados (a imagem `talos-1140-nocloud-amd64-secureboot.qcow2` já vem preparada).

### 2. Como criar as VMs

Você tem três caminhos:

**Opção A — Usar o projeto de VMs Libvirt/KVM (recomendado para lab local)**

Clone e aplique o repositório [Projeto-Terraform-Libvirt-KVM](https://github.com/donato-marcos/Projeto-Terraform-Libvirt-KVM). Ele cria as VMs no libvirt/KVM com as interfaces e IPs que este projeto espera (ver `talos.auto.tfvars`).

**Opção B — Criar manualmente**

Suba as VMs em qualquer hypervisor (Proxmox, VMware, VirtualBox, libvirt, etc.) com Talos em modo maintenance e IPs fixos. Anote os IPs de gerenciamento.

**Opção C — Outro hypervisor/cloud**

Se você usa outro ambiente (AWS, GCP, Azure, bare metal), você precisará do **seu próprio Terraform** para criar as VMs ou criá-las manualmente. Este projeto apenas consome VMs já existentes — a camada de infraestrutura é sua responsabilidade.

### 3. Ferramentas necessárias

| Ferramenta | Versão mínima | Uso |
|---|---|---|
| [OpenTofu](https://opentofu.org/) ou Terraform | 1.6+ | Executar o projeto |
| [talosctl](https://www.talos.dev/latest/talos-guides/install/talosctl/) | v1.14.0 | Administração do cluster |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | 1.30+ | Acesso ao Kubernetes |
| [helm](https://helm.sh/) | 3.14+ | Instalação de charts (opcional) |
| [cilium CLI](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/) | 0.18+ | Diagnóstico do Cilium (opcional) |

Instale o `talosctl`:

```bash
curl -LO https://github.com/siderolabs/talos/releases/download/v1.14.0/talosctl-linux-amd64
chmod +x talosctl-linux-amd64
sudo mv talosctl-linux-amd64 /usr/local/bin/talosctl
```

---

## 📁 Estrutura do projeto

```
.
├── environments/
│   └── k8s-talos/                   # ← você executa o Terraform daqui
│       ├── main.tf                  # Orquestra os módulos
│       ├── outputs.tf               # kubeconfig, talosconfig, nós
│       ├── providers.tf             # Providers: talos, helm, kubernetes
│       ├── variables.tf             # Variáveis do ambiente
│       ├── version.tf               # Versões dos providers
│       ├── talos.auto.tfvars        # ← sua configuração (ver seção abaixo)
│       └── talos/configs/patches/   # Patches YAML (common, controlplane, worker)
│
└── modules/
    ├── talos_config/                # Gera secrets e configs de máquina
    ├── talos_bootstrap/             # Aplica config, bootstrap, health check, kubeconfig
    └── orchestration/               # Apenas organiza os outros dois módulos
```

### Responsabilidade dos módulos

| Módulo | O que faz |
|---|---|
| `talos_config` | Gera os segredos do cluster (`talos_machine_secrets`), renderiza `controlplane.yaml` e `worker.yaml` (via `talos_machine_configuration`) e o `talosconfig` do cliente. |
| `talos_bootstrap` | Aplica a configuração em cada nó, executa o bootstrap do etcd no primeiro control plane, aguarda o cluster ficar saudável e recupera o `kubeconfig`. |
| `orquestration` | Instala Helm releases sobre o cluster já formado (Cilium, Tetragon, ArgoCD, etc.). Opcional — pode ser removido se você preferir GitOps puro. |

---

## 🔗 Projetos relacionados

Este projeto faz parte de um conjunto de repositórios que, juntos, provisionam um cluster Kubernetes completo sobre Talos Linux em ambiente local:

| Repositório | Responsabilidade | Quando usar |
|---|---|---|
| **[Projeto-Terraform-Libvirt-KVM](https://github.com/donato-marcos/Projeto-Terraform-Libvirt-KVM)** | Criação das VMs no libvirt/KVM com as interfaces e IPs fixos que o Talos espera. | **Antes** deste projeto. Sem as VMs, não há como aplicar a configuração do Talos. |
| **Este projeto** (`talos-bootstrap`) | Bootstrap do Talos: secrets, configuração, etcd, health check, kubeconfig. | **Depois** que as VMs estão bootadas em modo maintenance. |
| **[terraform-k8s-helm](https://github.com/donato-marcos/terraform-k8s-helm)** | Camada de aplicações: instala e gerencia Helm charts no cluster já formado (Cilium, Tetragon, ArgoCD, etc.). | **Depois** que o cluster está `Ready` e o `kubeconfig` foi obtido. Mantém a gestão de charts separada do bootstrap. |

### Fluxo de dependências

```
┌─────────────────────────────┐
│ Projeto-Terraform-Libvirt-  │
│ KVM                         │  ← Cria as VMs com Talos em modo maintenance
└─────────────┬───────────────┘
              │ VMs bootadas, IPs fixos
              ▼
┌─────────────────────────────┐
│ Este projeto                │
│ (talos-bootstrap)           │  ← Bootstrap: secrets, config, etcd, kubeconfig
└─────────────┬───────────────┘
              │ Cluster Ready + kubeconfig
              ▼
┌─────────────────────────────┐
│ terraform-k8s-helm          │  ← Helm releases: Cilium, Tetragon, ArgoCD...
└─────────────────────────────┘
```

### Por que separar em dois projetos?

A separação em três camadas segue o princípio de **responsabilidade única**:

1. **Infraestrutura (VMs)** — muda raramente; recriar o cluster inteiro é uma decisão deliberada.
2. **Bootstrap do Talos** — muda apenas quando o cluster é reconstruído ou os patches de configuração base são alterados.
3. **Aplicações (Helm)** — muda com frequência; adicionar/remover charts não deve arriscar o cluster.

Se tudo estivesse em um único state, um `tofu apply` para atualizar uma versão do Cilium poderia, em um erro de plan, recriar acidentalmente o cluster. Com states separados, cada camada evolui no seu ritmo e com seu próprio nível de risco.

### O que o `terraform-k8s-helm` gerencia

O repositório [terraform-k8s-helm](https://github.com/donato-marcos/terraform-k8s-helm) é um projeto Terraform/OpenTofu dedicado exclusivamente à instalação de Helm charts no cluster. Ele contém:

- **`environments/`** — configuração por ambiente (valores dos charts, versões, namespaces).
- **`modules/helm_release/`** — módulo genérico que encapsula o `helm_release` do provider Helm, permitindo declarar charts de forma padronizada.

Exemplo de uso típico:

```hcl
module "cilium" {
  source = "../../modules/helm_release"

  name             = "cilium"
  namespace        = "kube-system"
  chart            = "cilium"
  repository       = "https://helm.cilium.io/"
  version          = "1.20.2"
  create_namespace = false
  values           = [file("${path.module}/values/cilium.yaml")]
}
```

## ⚙️ Configurando o `talos.auto.tfvars`

O arquivo `environments/k8s-talos/talos.auto.tfvars` é a **única fonte de verdade** sobre o cluster. Edite-o antes de rodar o Terraform.

### Estrutura

```hcl
# --- Cluster ---
cluster_name     = "k8s-cluster"
cluster_endpoint = "https://172.16.200.10:6443"  # VIP do control plane (API K8s)
talos_version    = "v1.14.0"

# --- Nós ---
nodes = {
  "talos-cp01"     = { role = "controlplane", ip = "172.16.1.11" }
  "talos-worker01" = { role = "worker",       ip = "172.16.1.21" }
  "talos-worker02" = { role = "worker",       ip = "172.16.1.22" }
  "talos-worker03" = { role = "worker",       ip = "172.16.1.23" }
}
```

### Campos explicados

| Campo | Descrição |
|---|---|
| `cluster_name` | Nome do cluster. Usado em contextos de talosconfig e kubeconfig. **Não repita entre clusters** — o merge de credenciais sobrescreve contextos de mesmo nome. |
| `cluster_endpoint` | Endereço do **VIP** da API do Kubernetes (`https://<vip>:6443`). Deve ser o mesmo VIP configurado no patch `controlplane/vip.yaml`. |
| `talos_version` | Versão do Talos. Deve bater com a imagem de boot das VMs. |
| `nodes` | Mapa de nós. **A chave** vira o hostname do nó. |

### ⚠️ Sobre os IPs no `nodes`

Use os **IPs de gerenciamento** (ex.: `172.16.1.x`), **não** os IPs da rede do cluster. Motivo:

- O `talosctl` e o Terraform usam esses IPs para conversar com a **API do Talos** (porta 50000), que está disponível já no modo maintenance.
- Os IPs da rede de cluster (`172.16.200.x`) só são configurados **após** o patch de rede ser aplicado — usá-los no `nodes` faria o `apply` falhar.

Se o seu ambiente tiver três redes por nó (gerência, cluster, storage) como o do exemplo, `ip` é sempre o endereço de **gerência**.

### Patches

Os patches ficam em `talos/configs/patches/` e são aplicados automaticamente pelos módulos:

| Diretório | Aplica a | Exemplos |
|---|---|---|
| `common/` | Todos os nós | `install.yaml`, `kubernetes.yaml`, `cni.yaml`, `ntp.yaml`, `sysctl.yaml`, `hostname.yaml` |
| `controlplane/` | Apenas control planes | `vip.yaml`, `kubeproxy.yaml`, `admissioncontrol.yaml` |
| `worker/` | Apenas workers | `longhorn-v1.yaml` |

São arquivos YAML no formato **multi-documento do Talos v1.14** (ex.: `HostnameConfig`, `KubeNetworkConfig`, `KubeNodeConfig`, `Layer2VIPConfig`). Não use o formato legado (`machine.network.interfaces[].vip`).

---

## 🚀 Uso

### 1. Inicializar e planejar

```bash
cd environments/k8s-talos
tofu init
tofu plan
```

O Terraform perguntará o caminho dos patches:

```
var.patches_dir
  Diretório com os patches de configuração (common/, controlplane/ e worker/)
  Enter a value: ./talos/configs/patches
```

### 2. Aplicar

```bash
tofu apply
```

O que acontece em ordem:

1. `talos_machine_secrets` — gera os segredos do cluster (fica no state, marcado como sensível).
2. `data.talos_machine_configuration` — renderiza `controlplane.yaml` e `worker.yaml` em memória, aplicando os patches.
3. `data.talos_client_configuration` — gera o `talosconfig` do cliente.
4. `talos_machine_configuration_apply` — aplica a config em cada nó via API do Talos.
5. `talos_machine_bootstrap` — bootstrap do etcd no primeiro control plane (ordem alfabética).
6. `talos_cluster_health` — aguarda o cluster ficar saudável.
7. `talos_cluster_kubeconfig` — recupera o kubeconfig.
8. (Opcional) Helm releases no módulo `orchestration`.

### 3. Obter credenciais

O jeito mais seguro é usar arquivos dedicados por cluster, evitando sobrescrever outros clusters no seu `~/.talos/config` e `~/.kube/config`:

```bash
mkdir -p ~/.talos ~/.kube
tofu output -raw talosconfig > ~/.talos/config-k8s-cluster
tofu output -raw kubeconfig  > ~/.kube/config-k8s-cluster
chmod 600 ~/.talos/config-k8s-cluster ~/.kube/config-k8s-cluster

export TALOSCONFIG=~/.talos/config-k8s-cluster
export KUBECONFIG=~/.kube/config-k8s-cluster
```

**Validação:**

```bash
talosctl config info
talosctl -n 172.16.1.11 health
kubectl get nodes -o wide
```

> 💡 Se você alterna entre clusters com frequência, prefira um script `activate-k8s-cluster.sh` no diretório do projeto que exporta essas variáveis. Alternativamente, use `talosctl config merge` e `kubectl config view --flatten` para mesclar em arquivos únicos — mas **nunca** redirecione `tofu output` diretamente para `~/.talos/config` ou `~/.kube/config`, ou você perderá os demais clusters.

### 4. Destruir

```bash
tofu destroy
```

> ⚠️ Isso remove o state, mas **não** desliga nem apaga as VMs. Talos continua rodando nelas. Para reaproveitá-las, é preciso reinstalar o Talos (boot pela ISO novamente) ou limpar os discos.

---

## 🧩 Patches — notas importantes

### Hostname

O hostname de cada nó é definido pelo **nome da chave no mapa `nodes`**. Ex.: a chave `"talos-cp01"` faz o nó se registrar como `talos-cp01`. Isso é implementado via `HostnameConfig` com `auto: off` — **não** use `machine.network.hostname`, que foi removido no Talos v1.14.

Se você definir hostname no patch `common/` **e** deixar o módulo `talos_bootstrap` aplicar seu próprio patch, o Talos aborta com `static hostname is already set`. Mantenha apenas uma das duas fontes.

### VIP (Layer2)

O VIP do control plane é configurado no patch `controlplane/vip.yaml`:

```yaml
apiVersion: v1alpha1
kind: Layer2VIPConfig
name: 172.16.200.10
link: eth1
```

O `link` **precisa** ser a interface da rede do cluster (ex.: `eth1`). O `cluster_endpoint` no `talos.auto.tfvars` deve apontar para esse mesmo VIP.

### CNI

O patch `common/cni.yaml` desabilita o Flannel padrão:

```yaml
apiVersion: v1alpha1
kind: KubeFlannelCNIConfig
$patch: delete
```

**Sem um CNI substituto, os nós ficam `NotReady`.** O módulo `orquestration` (ou o `terraform-k8s-helm`) instala o Cilium via Helm automaticamente. Se preferir outro CNI (Calico, etc.), remova o Cilium e instale-o por conta própria.

### Rede do kubelet

O patch `common/kubernetes.yaml` define `KubeNodeConfig.nodeIP.validSubnets`, que determina **qual rede o kubelet usa como node IP**. No exemplo, é `172.16.200.0/24`. Como consequência:

- `kubectl get nodes -o wide` mostra `INTERNAL-IP = 172.16.200.x`.
- O `data.talos_cluster_health` precisa usar esses IPs (não os de gerência).

---

## 🐛 Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Unsupported argument: insecure` | Provider Talos novo removeu o campo | Remova `insecure` do `talos_machine_configuration_apply`. O provider trata o modo maintenance automaticamente. |
| `can't find expected node with IPs ["172.16.1.11"]` | Health check usa IP de gerência, kubelet reporta IP de cluster | Use os IPs `172.16.200.x` no `talos_cluster_health` (ou o campo `cluster_ip` no tfvars). |
| Nós `NotReady` após o bootstrap | Sem CNI instalado | Instale o Cilium (ou outro CNI). O patch `cni.yaml` removeu o Flannel padrão. |
| `talos_cluster_kubeconfig` deprecated warning | Uso de `data` em vez de `resource` | Troque `data "talos_cluster_kubeconfig"` por `resource "talos_cluster_kubeconfig"`. |
| `context deadline exceeded` no health check | Cluster ainda não formou | Aumente o timeout (`timeouts { read = "15m" }`) ou use `skip_kubernetes_checks = true` para diagnóstico. |

---

## 📚 Referências

- [Talos Linux — Documentação oficial](https://www.talos.dev/latest/)
- [Talos v1.14 — Configuration reference](https://www.talos.dev/v1.14/reference/configuration/)
- [Provider Terraform `siderolabs/talos`](https://registry.terraform.io/providers/siderolabs/talos/latest/docs)
- [Cilium — Documentação](https://docs.cilium.io/)
- [Projeto-Terraform-Libvirt-KVM](https://github.com/donato-marcos/Projeto-Terraform-Libvirt-KVM) — criação das VMs (opcional)
- [terraform-k8s-helm](https://github.com/donato-marcos/terraform-k8s-helm) — camada de Helm releases (Cilium, Tetragon, ArgoCD, etc.)

