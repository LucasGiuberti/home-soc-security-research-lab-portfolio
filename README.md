# Home SOC — Security Research Lab

Laboratório pessoal de segurança com Proxmox VE, WireGuard, Linux, Windows e Splunk Enterprise. O foco é desenvolver detecções, testar hipóteses e documentar investigações com evidências verificáveis. **Os testes descritos ocorreram exclusivamente em máquinas autorizadas do laboratório.**

## Resultados demonstrados

- **Detecção validada:** TCP SYN port scan com 200 portas distintas e 200 eventos na fonte selecionada.
- **Dois testes positivos:** alertas agendados confirmados em 29/10 e 01/11/2026.
- **Um teste negativo validado:** 3 portas distintas; execução agendada sem resultados acima do limiar, em 01/11/2026.
- **Escopo real:** um caso de uso e telemetria específica; não representa cobertura completa, métricas de precisão nem comprometimento real.

## Estudo de caso

### [SOC-LAB-001 — Detecção de varredura TCP](incidents/INC-0001-port-scan/README.md)

Implementei uma regra que identifica origens que tentam alcançar mais de dez portas TCP distintas de um mesmo host em cinco minutos. Usei Nmap para gerar o tráfego de teste, `iptables` para registrar pacotes SYN e Splunk para coletar, correlacionar e alertar.

**Resultado em 29/10/2026:** 200 portas distintas, 200 eventos na fonte selecionada e disparo automático da regra final confirmado às 15h50 (UTC−3).

**Teste negativo adicional em 01/11/2026, 01h15 (UTC−3):** a consulta no Splunk identificou 3 portas distintas e 3 eventos em janela independente, abaixo do limiar. O histórico do agendador confirmou a execução das **01h25**, com `status=success` e `result_count=0`, sem novo disparo no painel de alertas.

**Reteste em 01/11/2026, 00h57 (UTC−3):** busca manual confirmou novamente 200 portas distintas e 200 eventos. O alerta **Scheduled / High** disparou às **01h05 (UTC−3)**, oito minutos após o início do scan, confirmando a segunda execução positiva da regra.

A atividade foi autorizada e ocorreu em máquinas do laboratório. O evento foi detectado corretamente; não se trata de uma invasão real.

[Relatório e evidências](incidents/INC-0001-port-scan/README.md) · [Regra SPL](detections/spl/01_tcp_port_scan.spl) · [Testes e limites](detections/tests/README.md)

## Ambiente

```text
Notebook Ubuntu — Nmap (10.200.0.2)
          |
       WireGuard
          |
VPN Gateway (10.200.0.1 / 10.10.10.1)
          |
      Proxmox vmbr1 (bridge sem uplink físico)
          |
          +-- Linux Target 10.10.10.30 — iptables / Universal Forwarder
          +-- Windows 11   10.10.10.20 — Sysmon
          +-- Splunk       10.10.10.10 — índice soc_lab

Gateway e Splunk também têm NICs na vmbr0/LAN doméstica;
a política de isolamento integral ainda exige validação fim a fim.
```

A [topologia verificada](architecture/topology.md) documenta ambas as interfaces do Splunk e do gateway, além das restrições observadas de encaminhamento. Veja também [como funciona o Ubuntu VPN Gateway](infrastructure/vpn-gateway/README.md).

## Organização

| Diretório | Conteúdo |
|---|---|
| [incidents/](incidents/INC-0001-port-scan/README.md) | Estudos de caso e evidências |
| [detections/spl/](detections/spl/01_tcp_port_scan.spl) | Consultas SPL; arquivos com `DRAFT` ainda não foram validados |
| [detections/tests/](detections/tests/README.md) | Critérios de teste e resultados observados |
| [infrastructure/linux-target/](infrastructure/linux-target/README.md) | Configuração reproduzível do sensor |
| [simulations/](simulations/01_nmap_lab.md) | Procedimentos de teste controlado |
| [playbooks/](playbooks/triage-portscan.md) | Roteiro de triagem |
| [infrastructure/vpn-gateway/](infrastructure/vpn-gateway/README.md) | Endereços, rotas e regras observadas do Ubuntu Gateway |
| [ROADMAP.md](ROADMAP.md) | Próximos estudos |

As pastas de Sigma e análise de malware ainda são preparatórias; não representam detecções ou análises concluídas.

## Limites do experimento

A regra atual detecta determinados pacotes TCP SYN recebidos no Linux Target. Ela não identifica todas as técnicas de varredura, e um alerta não prova intenção maliciosa. Os testes positivos com alerta agendado e o teste negativo abaixo do limiar foram validados no escopo do experimento. Permanecem pendentes cenários de borda e testes completos de segmentação.

A segmentação completa LAB → LAN ainda não foi validada por teste fim a fim. O estudo de caso descreve exclusivamente simulações em ambiente autorizado.

## Referências

- [MITRE ATT&CK — T1046](https://attack.mitre.org/techniques/T1046/)
- [Splunk — Scheduled Alerts](https://help.splunk.com/en/splunk-enterprise/alert-and-respond/alerting-manual/10.4/create-alerts/create-scheduled-alerts)
- [Sigma](https://sigmahq.io/docs/)
- [Atomic Red Team](https://www.atomicredteam.io/docs/atomic-red-team)
