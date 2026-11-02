# Evolução do Home SOC

## SOC-LAB-001 — Reconhecimento TCP

**Concluí:** instrumentação de pacotes TCP SYN com `iptables`, coleta via Splunk Universal Forwarder, correlação de portas distintas em SPL, teste positivo de 200 portas, disparo agendado da regra corrigida e persistência do sensor após reinicialização.

**Validação adicional:** em 30/10/2026, observei três portas distintas e três registros no `kern.log`, sem verificar individualmente a execução agendada daquela janela. Em 01/11/2026, repeti o teste positivo: foram identificadas 200 portas distintas e 200 eventos, com novo alerta automático às 01h05 (UTC−3).

Também validei um **teste negativo** em 01/11/2026. A busca manual registrou três portas distintas na janela de 01h15–01h20, abaixo do limiar. O histórico do `scheduler` mostrou `status=success` e `result_count=0` na execução das 01h25.

**Ponto ainda não testado:** comportamento da regra quando uma varredura atravessa duas janelas fixas de cinco minutos.

[Relatório SOC-LAB-001](incidents/INC-0001-port-scan/README.md) · [Matriz de testes](detections/tests/README.md).

## SOC-LAB-002 — PowerShell no Windows

**Planejado; ainda não executado.**

Pretendo investigar atividades de PowerShell na VM Windows 11 usando Sysmon e Splunk. Minha proposta é executar uma simulação não destrutiva e autorizada, estudar os eventos produzidos, construir uma busca de investigação e comparar os resultados com uma regra Sigma apropriada, caso a telemetria permita.

Também pretendo registrar processo pai, linha de comando, usuário, horário e possíveis falsos positivos. Este segundo estudo só será apresentado como validado depois dos testes e das evidências.
