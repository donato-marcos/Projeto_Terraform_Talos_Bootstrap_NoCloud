# Módulo `talos_bootstrap`

Aplica as configurações de máquina nos nós, executa o bootstrap do cluster e recupera o kubeconfig.

## Fluxo

1. **`talos_machine_configuration_apply`** → aplica a config em **todos** os nós (control planes e workers), com um patch por nó definindo o `hostname`. Em maintenance mode usa conexão insegura (`insecure = true`, equivalente ao `--insecure` do talosctl)
2. **`talos_machine_bootstrap`** → bootstrapa o cluster no primeiro control plane (ordem alfabética dos nomes)
3. **`data.talos_cluster_health`** → aguarda o cluster ficar saudável (timeout configurável)
4. **`data.talos_cluster_kubeconfig`** → recupera o kubeconfig

## Limitações

- Assume que os nós já estão em modo maintenance e acessíveis nos IPs informados
- O bootstrap é executado em um único nó; se ele for recriado, o bootstrap é executado novamente
