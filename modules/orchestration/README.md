# Modulo `orquestration`

Orquestrador central do bootstrap Talos: gera segredos/configs e coordena a aplicação e o bootstrap do cluster.

## Fluxo

1. **`module.talos_config`** → gera `secrets.yaml` (no tfstate), `controlplane.yaml`, `worker.yaml` e `talosconfig`, aplicando os patches do diretório
2. **`module.talos_bootstrap`** → aplica a config em cada nó (com hostname por nó), executa o bootstrap no primeiro control plane, aguarda o cluster saudável e recupera o kubeconfig

Cada etapa usa `depends_on` para garantir a ordenação.

## Limitações

- Não valida conectividade com os nós antes do apply
- Requer que os patches existam no `patches_dir` informado
