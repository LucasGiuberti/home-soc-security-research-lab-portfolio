# SOC-LAB-001 — Configuração do alerta

Configuração final documentada no Splunk Enterprise em 29/10/2026:

| Campo | Valor |
|---|---|
| Fonte | `index=soc_lab host="linux-target" source="/var/log/kern.log" "SYN_PROBE"` |
| Critério | `dc(dpt) > 10`, por origem, destino e intervalo fixo de cinco minutos |
| Tipo | Scheduled |
| Cron | `*/5 * * * *` |
| Earliest | `-10m@m` |
| Latest | `-5m@m` |
| Disparo | Number of Results > 0, Once |
| Severidade no laboratório | High |

Arquivo: [01_tcp_port_scan.spl](spl/01_tcp_port_scan.spl).

## Validação

Em 29/10/2026, às **15h50 (UTC−3)**, o Splunk registrou um novo disparo agendado da regra corrigida. O `View Results` mostrou **200 portas distintas e 200 eventos** no par `10.200.0.2 → 10.10.10.30`. A consulta apresentada nesse resultado continha o filtro `source="/var/log/kern.log"` e o limiar `> 10`.

- [E07 — Triggered Alerts](../incidents/INC-0001-port-scan/evidence/E07_alertas_1540_e_1550.png)
- [E08 — Resultado da consulta corrigida](../incidents/INC-0001-port-scan/evidence/E08_resultado_alerta_corrigido_1550.png)

**Testes posteriores:** em 30/10, o teste de três portas produziu três portas distintas e três eventos em `kern.log`, sem confirmação do agendamento correspondente. Em 01/11, às 00h57 (UTC−3), a busca manual do novo teste positivo identificou 200 portas e 200 eventos, e a tela de `Triggered Alerts` comprovou o novo disparo automático da regra, modo **Scheduled**, severidade **High**, às **01h05 (UTC−3)**. O alerta agendado utiliza uma janela cinco minutos atrasada; essa margem não garante a inclusão de eventos recebidos com atraso superior ao intervalo configurado. Scans atravessando o limite de duas janelas também podem escapar à agregação.

**Teste negativo validado (01/11):** a busca manual mostrou 3 portas distintas e 3 eventos no bloco de 01h15, classificado `SEM ALERTA` por `eval`. O `sourcetype=scheduler` registrou as execuções das **01h20 e 01h25**, ambas com `status=success` e `result_count=0`. A execução das **01h25** analisou a janela de **01h15–01h20**, segundo o agendamento. O painel de `Triggered Alerts` mostrou somente o disparo positivo das 01h05.

Referência: [Splunk — Scheduled Alerts](https://help.splunk.com/en/splunk-enterprise/alert-and-respond/alerting-manual/10.4/create-alerts/create-scheduled-alerts).
