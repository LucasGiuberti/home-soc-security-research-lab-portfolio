# Simulação de reconhecimento TCP — Linux Target

Realizei os testes exclusivamente em meu laboratório autorizado, usando o notebook Ubuntu com WireGuard `10.200.0.2` e o Linux Target `10.10.10.30` na rede virtual do Proxmox.

## Teste positivo documentado em 29/10/2026

```bash
sudo nmap -sS -Pn -p 1-200 10.10.10.30
```

O Splunk registrou 200 portas distintas e 200 eventos na fonte `/var/log/kern.log`. O alerta agendado da regra corrigida foi observado às 15h50 (UTC−3). Essa constatação é sustentada pelas capturas [E07](../incidents/INC-0001-port-scan/evidence/E07_alertas_1540_e_1550.png) e [E08](../incidents/INC-0001-port-scan/evidence/E08_resultado_alerta_corrigido_1550.png).

O comando original foi executado no laboratório, mas não há captura do terminal com a hora exata da execução.

## Teste negativo — validado em 01/11/2026

Em uma janela separada dos testes positivos, utilizei a seguinte sequência de comandos:

```bash
date -Is
sudo nmap -sS -Pn -p 22,80,443 10.10.10.30
date -Is
```

**Observado no teste de 01/11:** três portas distintas e três eventos em `kern.log` no intervalo de 01h15–01h20. A busca manual classificou esse grupo como `SEM ALERTA`; o histórico do agendador confirmou a busca das 01h25 com `status=success` e `result_count=0`, sem novo disparo apresentado em `Triggered Alerts`. Evidências: [E09](../incidents/INC-0001-port-scan/evidence/E09_comparacao_200_3_portas.png) e [E11](../incidents/INC-0001-port-scan/evidence/E11_scheduler_negativo_0125.png).

**Reteste positivo em 01/11:** scan das portas 1–200 às 00h57, 200 portas e 200 eventos na busca manual, com alerta agendado às 01h05. Evidência: [E10](../incidents/INC-0001-port-scan/evidence/E10_alerta_0105.png).

Outros testes propostos (11 portas, repetição da mesma porta, varredura atravessando duas janelas) estão descritos em [detections/tests/README.md](../detections/tests/README.md) e não foram marcados como realizados.

Nos próximos experimentos, pretendo preservar a saída do Nmap, os horários, o evento bruto correspondente e o resultado SPL.
