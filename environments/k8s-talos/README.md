# `k8s-talos` Environment

Ponto de entrada para bootstrap de um cluster Talos/Kubernetes em VMs Libvirt/KVM já provisionadas (modo **maintenance**).

- Carrega variáveis do cluster via `talos.auto.tfvars` e conexões via `libvirt.auto.tfvars`
- Invoca o módulo `orquestration`, que gera segredos/configs do Talos, aplica em cada nó e faz o bootstrap
- Não cria recursos diretamente — delega tudo ao orquestrador

## Pré-requisitos

1. VMs com imagem ISO Talos (ou nocloud) bootadas em **modo maintenance**, com IP fixo acessível
2. Patches em `talos/configs/patches/` (já testados manualmente)
3. `cluster_endpoint` apontando para o VIP do patch `controlplane/vip.yaml`

## Fluxo

```
cd environments/k8s-talos
terraform init
terraform validate
terraform apply
```

## Outputs úteis

- `talosconfig`: equivalente ao arquivo `talosconfig` do `talosctl gen config`
- `kubeconfig`: kubeconfig do cluster (após bootstrap + health check)
- Segredos e configs ficam apenas no **tfstate** — nenhum arquivo é gravado em disco

## Limitações

- Não verifica se os nós estão acessíveis antes do apply (falha no primeiro recurso de rede)
- Um único bootstrap é executado (no primeiro control plane, ordenado por nome)
- Segredos do cluster ficam no tfstate — trate o state como sensível
