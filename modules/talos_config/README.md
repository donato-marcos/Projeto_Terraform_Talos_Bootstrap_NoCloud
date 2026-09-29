# Módulo `talos_config`

Gera os segredos e as configurações de máquina do Talos — o equivalente ao `talosctl gen config`.

- Gera os segredos do cluster (`talos_machine_secrets`), mantidos apenas no tfstate
- Lê os patches de `patches_dir/{common,controlplane,worker}/*.yaml` (ordem alfabética, com `common` sempre primeiro)
- Gera as configs de `controlplane` e `worker` via `talos_machine_configuration`, já com os patches aplicados
- Gera o `talosconfig` do cliente (`talos_client_configuration`)

## Limitações

- Não grava arquivos em disco (`controlplane.yaml`, `worker.yaml`, `secrets.yaml`, `talosconfig` existem só como valores/outputs)
- Não aplica configuração em nenhum nó (isso é o `talos_bootstrap`)
