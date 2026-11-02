# Plano de validação — TCP Port Scan

A regra usa `dc(dpt)` para calcular quantas portas de destino distintas foram observadas por par origem-destino em blocos fixos de cinco minutos. O limiar é `> 10`.

A tabela distingue o que já foi **observado** do que ainda é apenas uma hipótese de teste.

| Cenário | Esperado | Evidência / estado |
|---|---|---|
| Nmap TCP SYN, portas 1–200 | Detecção por diversidade de portas | **Observado:** 200 portas, 200 eventos, alerta agendado; [E08](../../incidents/INC-0001-port-scan/evidence/E08_resultado_alerta_corrigido_1550.png) |
| Reteste Nmap TCP SYN, portas 1–200 (01/11, 00h57 UTC−3) | 200 portas distintas na fonte selecionada | **Observado em busca manual:** 200 portas e 200 eventos, origem `10.200.0.2`, destino `10.10.10.30`; novo disparo **Scheduled / High confirmado às 01h05 (UTC−3)** |
| Scan de apenas três portas | Não criar disparo exclusivamente por esse teste | **Parcialmente observado (30/10):** 3 portas distintas e 3 eventos em `kern.log`; consulta do histórico do agendador pendente |
| Reteste negativo (01/11, janela 01h15 UTC−3) | 3 portas distintas, sem disparo pela regra final | **Validado:** 3 portas e 3 eventos na busca manual; `eval` classificou `SEM ALERTA`. Histórico do `scheduler`: 01h25, `status=success`, `result_count=0`; o painel de alertas exibiu apenas o disparo positivo das 01h05. |
| Muitas tentativas na mesma porta | `dc(dpt)` não deve superar 10 apenas por repetição | **Pendente** |
| Scan cruzando duas janelas fixas | Pode perder a detecção se a diversidade ficar dividida | **Pendente** |
| Scanner autorizado com várias portas | Detectar padrão e classificar corretamente como atividade permitida | **Pendente** |

[Regra SPL](../spl/01_tcp_port_scan.spl) · [Simulação](../../simulations/01_nmap_lab.md)
