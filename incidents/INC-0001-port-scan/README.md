# SOC-LAB-001 — Detecção e investigação de varredura de portas TCP

**Data da validação:** 29/10/2026  
**Área:** Security Operations Center (SOC) · Detection Engineering  
**Ambiente:** Proxmox VE · WireGuard · Ubuntu Linux · Splunk Enterprise  
**MITRE ATT&CK:** [T1046 — Network Service Discovery](https://attack.mitre.org/techniques/T1046/)  
**Status:** validei testes positivos com alerta automático e um teste negativo de três portas. Ainda não executei os testes de borda nem a auditoria completa de isolamento.

## 1. Resumo executivo

Implementei e validei uma detecção automatizada de **varredura de portas TCP** em um laboratório SOC virtualizado com rede LAB em bridge interna, acessada por VPN. A simulação utilizou o Nmap para gerar tráfego de reconhecimento a partir de um notebook Ubuntu, encaminhado por WireGuard até um endpoint Linux monitorado.

O endpoint registrou pacotes TCP SYN via `iptables`, com identificação `SYN_PROBE`. Os registros foram enviados ao **Splunk Enterprise** por meio do **Splunk Universal Forwarder** e analisados com uma busca **SPL** que correlaciona portas de destino distintas por origem, destino e intervalo de cinco minutos.

**Resultado comprovado:** a busca identificou **200 portas TCP distintas a partir de 200 eventos analisados**, e a regra corrigida produziu um **alerta automático às 15h50 (UTC−3), em 29/10/2026**. O teste demonstra uma detecção funcional de comportamento compatível com **T1046 — Network Service Discovery**, sem caracterizar um incidente de segurança real.

## 2. Objetivo e hipótese de detecção

O objetivo foi criar uma regra capaz de reconhecer uma mesma origem tentando iniciar conexões com diversas portas TCP de um único destino em um intervalo curto, para apoiar a triagem de atividades de descoberta de serviços.

> **Hipótese:** uma origem que acessa **mais de 10 portas TCP distintas no mesmo destino em uma janela de cinco minutos** pode estar realizando reconhecimento de serviços de rede.

A condição é **heurística**: identifica um padrão de tráfego, não um programa específico nem, isoladamente, intenção maliciosa.

## 3. Escopo e arquitetura do laboratório

```text
Notebook Ubuntu — Nmap
  10.200.0.2 (WireGuard)
         |
         | túnel VPN autenticado
         v
VPN Gateway
  wg0: 10.200.0.1
  LAB: 10.10.10.1
         |
         v
  vmbr1 — rede virtual isolada (Proxmox)
         |
         +-- Linux Target — 10.10.10.30
         |     iptables -> kern.log -> Splunk Universal Forwarder
         |
         +-- Splunk Enterprise — 10.10.10.10
               índice: soc_lab
```

O teste ocorreu exclusivamente entre equipamentos do laboratório, em rede LAB virtual separada em camada 2, mas com VMs gateway e Splunk também conectadas à LAN doméstica. O isolamento integral entre as redes ainda requer teste fim a fim. A simulação foi autorizada e não representa ataque contra infraestrutura de terceiros.

## 4. Metodologia

### 4.1 Instrumentação do endpoint Linux

Configurei o `iptables` para registrar tentativas de estabelecimento de conexão TCP que chegam ao endpoint com a flag SYN definida e ACK, FIN e RST desativadas:

```bash
sudo iptables -I INPUT 1 \
  -p tcp --tcp-flags SYN,RST,ACK,FIN SYN \
  -m limit --limit 30/second --limit-burst 200 \
  -j LOG --log-prefix "SYN_PROBE " --log-level 4
```

A ação `LOG` registra os pacotes correspondentes **sem bloquear o tráfego**. O prefixo `SYN_PROBE` permite localizar os eventos; a regra inclui limitação da taxa de logging para controlar o volume gerado.

Para restaurar a regra após a inicialização do endpoint, usei um script chamado `soc-syn-probe.sh` e um serviço `systemd`. A presença de uma única regra e a execução do serviço foram verificadas **após um reboot da VM**. Versionei uma [reconstituição da configuração](../../infrastructure/linux-target/README.md) para facilitar a reprodução. Ainda não a comparei diretamente com todos os arquivos instalados na VM.

### 4.2 Simulação controlada

No notebook Ubuntu, conectado à VPN, utilizei:

```bash
sudo nmap -sS -Pn -p 1-200 10.10.10.30
```

A simulação realiza uma varredura TCP SYN das portas 1 a 200 do Linux Target. O estudo documenta o comportamento observado nos registros do Splunk. O horário exato do comando Nmap não foi capturado no terminal.

### 4.3 Coleta e correlação

O Splunk Universal Forwarder encaminhou eventos do Linux Target ao índice `soc_lab`. Para a regra de detecção, selecionei **`source="/var/log/kern.log"`**, que fornece os registros `SYN_PROBE` sem contabilizar também as cópias presentes em outra fonte de log do host.

Os campos analisados foram:

| Campo | Finalidade |
|---|---|
| `SRC` | Identificar a origem das tentativas TCP |
| `DST` | Identificar o endpoint de destino |
| `DPT` | Identificar a porta TCP de destino |
| `_time` | Agrupar os eventos em janelas de cinco minutos |

## 5. Regra de detecção (SPL)

Arquivo de referência: [`../../detections/spl/01_tcp_port_scan.spl`](../../detections/spl/01_tcp_port_scan.spl)

```spl
index=soc_lab host="linux-target" source="/var/log/kern.log" "SYN_PROBE"
| rex "SRC=(?<src>\S+) DST=(?<dst>\S+).*?DPT=(?<dpt>\d+)"
| bin _time span=5m
| stats dc(dpt) as portas_distintas count as tentativas by _time, src, dst
| where portas_distintas > 10
| sort - portas_distintas
```

A busca extrai os IPs e portas a partir dos logs, agrupa registros por intervalo, origem e destino e calcula a quantidade de portas distintas com `dc(dpt)`. A condição `> 10` significa que **11 ou mais portas distintas** satisfazem o critério.

### Agendamento e disparo

| Parâmetro | Configuração |
|---|---|
| Tipo | Scheduled |
| Cron | `*/5 * * * *` |
| Intervalo inicial | `-10m@m` |
| Intervalo final | `-5m@m` |
| Condição de disparo | Number of Results > 0 |
| Modo | Once |
| Severidade configurada | High |

A janela com atraso de cinco minutos permite uma margem para ingestão antes da análise. A severidade **High** é uma configuração de laboratório e não significa, por si só, comprometimento ou alto risco no contexto observado.

## 6. Resultados da validação

| Indicador | Resultado observado |
|---|---|
| Data | 29/10/2026 |
| Origem | `10.200.0.2` |
| Destino | `10.10.10.30` |
| Portas TCP distintas | **200** |
| Eventos contabilizados na fonte da regra | **200** |
| Janela de correlação | **5 minutos** |
| Alerta automático da regra corrigida | **Confirmado — 15h50 (UTC−3)** |
| Classificação | Comportamento de reconhecimento simulado e autorizado |
| Técnica ATT&CK | **T1046 — Network Service Discovery** |

O resultado final confirmou o fluxo completo: **Nmap → logging TCP SYN no Linux → Universal Forwarder → Splunk → correlação SPL → alerta agendado**.

A consulta final foi validada tanto na análise dos eventos quanto na execução agendada, conforme as evidências da seção seguinte.

### Reteste positivo — 01/11/2026

Às **00h57 (UTC−3)**, executei novamente `sudo nmap -sS -Pn -p 1-200 10.10.10.30` a partir do notebook conectado à VPN. O Nmap reportou 1 porta aberta (22/tcp) e 199 fechadas. Uma busca manual no Splunk com `source="/var/log/kern.log"` e intervalo de 00h55 a 01h00 confirmou **200 portas TCP distintas e 200 eventos**, origem `10.200.0.2` e destino `10.10.10.30`. O reteste valida novamente coleta e correlação; o painel de **Triggered Alerts** confirmou novo disparo às **01h05 (UTC−3)**, em modo **Scheduled** e severidade **High**. A captura da consulta comparativa e a do disparo agendado estão versionadas como E09 e E10; a captura do terminal Nmap não integra esse conjunto de evidências.

### Reteste negativo — 01/11/2026

Na janela de **01h15–01h20 (UTC−3)**, a busca manual isolada em `source="/var/log/kern.log"` retornou **três portas distintas e três eventos** para o par `10.200.0.2 → 10.10.10.30`. A expressão `eval resultado=if(portas_distintas>10,"ALERTA","SEM ALERTA")` classificou o grupo como `SEM ALERTA`; na mesma consulta, o bloco de 00h55 continha 200 portas e 200 eventos, classificado `ALERTA`. A tela de `Triggered Alerts` apresentada continha apenas o disparo do teste positivo às 01h05. O histórico do `scheduler` confirmou execuções às **01h20** e **01h25**, ambas com `status=success` e `result_count=0`. Pela configuração `earliest=-10m@m` / `latest=-5m@m`, a execução das **01h25** analisou a janela do teste negativo (01h15–01h20), sem resultados acima do limiar. As evidências da comparação SPL e do agendador estão versionadas como E09 e E11.

## 7. Evidências

| ID | Evidência | Demonstração |
|---|---|---|
| [E01](evidence/E01_telemetria_linux_windows.png) | Telemetria no índice | Ingestão de logs de Windows e Linux |
| [E02](evidence/E02_coleta_em_tres_fontes.png) | Auditoria de fontes | Identificação das fontes utilizadas na coleta |
| [E03](evidence/E03_busca_corrigida_200_eventos.png) | Busca de investigação | 200 portas distintas e 200 eventos na fonte selecionada |
| [E04](evidence/E04_alerta_agendado_disparado.png) | Triggered Alerts | Funcionamento do mecanismo de alerta agendado |
| [E06](evidence/E06_configuracao_corrigida_no_editor.png) | Configuração final | SPL e agendamento atualizados no editor |
| [E07](evidence/E07_alertas_1540_e_1550.png) | Triggered Alerts | Disparos registrados às 15h40, 15h50 e 16h00 (UTC−3) |
| [E08](evidence/E08_resultado_alerta_corrigido_1550.png) | View Results | Regra corrigida: 200 portas distintas, 200 eventos, origem e destino corretos |
| [E09](evidence/E09_comparacao_200_3_portas.png) | Comparação SPL | 200 portas / 200 eventos e 3 portas / 3 eventos em janelas diferentes |
| [E10](evidence/E10_alerta_0105.png) | Triggered Alerts | Novo disparo automático às 01h05 em 01/11/2026 |
| [E11](evidence/E11_scheduler_negativo_0125.png) | Histórico do scheduler | Execução das 01h25: `status=success`, `result_count=0` |

As evidências E07 e E08 documentam a primeira validação; E09–E11 documentam os testes positivo e negativo posteriores. Registros de versões anteriores permanecem no [acervo de evidências](evidence/README.md), sem serem utilizados como prova da regra definitiva.

O instante exato do comando Nmap não foi documentado em captura de terminal, portanto a linha do tempo privilegia horários comprovados pelas telas do Splunk.

## 8. Decisões de engenharia

Durante o experimento, tomei três decisões para melhorar a confiabilidade e a manutenção da detecção:

- **Seleção da fonte de telemetria:** a regra utiliza `kern.log` para que os mesmos registros não sejam contados em conjunto com os de `syslog`. A coleta geral das outras fontes permanece disponível para outras investigações.
- **Instrumentação persistente:** a regra de logging é gerenciada por um serviço `systemd` e foi verificada após reinicialização da VM, mantendo o monitoramento disponível.
- **Correlação temporal:** o processamento considera origem, destino, portas distintas e janelas de cinco minutos, em vez de tratar um único pacote SYN como evidência de varredura.

## 9. Limitações e possíveis falsos positivos

- O mecanismo observa pacotes TCP com o padrão de flags configurado; **não cobre** varreduras UDP, FIN/NULL/Xmas ou todos os métodos de reconhecimento.
- Ferramentas legítimas de inventário, diagnóstico e disponibilidade podem gerar o mesmo padrão e exigir contextualização pela equipe SOC.
- O limitador `iptables` (`30/second`, burst `200`) pode reduzir a quantidade de eventos registrados em tráfego de maior intensidade.
- A consulta usa intervalos **fixos** de cinco minutos: atividades que atravessam a fronteira entre janelas podem ser divididas entre dois grupos.
- A detecção depende do formato do log (`SRC`, `DST`, `DPT`), da qualidade dos timestamps e do prazo de chegada dos eventos ao Splunk.
- Não foram calculadas métricas de precisão, recall ou taxa de falsos positivos neste experimento.

**Validação negativa concluída em 01/11:** o reteste de três portas teve telemetria, comparação do limiar e histórico do agendador confirmados. O teste de 30/10 permanece como observação adicional de telemetria, sem auditoria individual do seu agendamento. O [plano de validação](../../detections/tests/README.md) separa cenários observados dos ainda não executados.

## 10. Conclusão

No SOC-LAB-001, implementei e validei uma **detecção automatizada de reconhecimento TCP**, desde a instrumentação do endpoint até a correlação e o disparo de alertas no Splunk Enterprise.

A validação identificou corretamente **200 portas de destino distintas, com 200 eventos contabilizados**, e comprovou a execução da regra final em um alerta agendado. Com esse resultado, estabeleci uma base para estudar novas detecções, triagem de eventos e investigações de Threat Hunting e Purple Team no laboratório.

## 11. Referências

- [MITRE ATT&CK — T1046: Network Service Discovery](https://attack.mitre.org/techniques/T1046/)
- [MITRE ATT&CK — Detection Strategy DET0376](https://attack.mitre.org/detectionstrategies/DET0376/)
- [Splunk — Scheduled Alerts](https://help.splunk.com/en/splunk-enterprise/alert-and-respond/alerting-manual/10.4/create-alerts/create-scheduled-alerts)
