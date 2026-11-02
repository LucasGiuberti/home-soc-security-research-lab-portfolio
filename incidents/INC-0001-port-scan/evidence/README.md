# Evidências — SOC-LAB-001

Capturas de testes controlados em **29/10 e 01/11/2026**. O conjunto mostra coleta da telemetria, investigação SPL, configuração da regra e execução agendada nos cenários positivo e negativo. O experimento ocorreu apenas em ativos autorizados.

| ID | Arquivo | O que mostra |
|---|---|---|
| E01 | [Telemetria Windows e Linux](E01_telemetria_linux_windows.png) | Eventos de múltiplas fontes no índice `soc_lab` |
| E02 | [Auditoria de fontes](E02_coleta_em_tres_fontes.png) | Logs SYN presentes em mais de uma fonte Linux |
| E03 | [Investigação — 200 eventos](E03_busca_corrigida_200_eventos.png) | 200 portas distintas e 200 eventos após filtrar `kern.log` |
| E04 | [Primeiro disparo agendado](E04_alerta_agendado_disparado.png) | Execução do alerta durante a validação inicial |
| E05 | [Resultado histórico](E05_resultado_alerta_versao_antiga.png) | Versão anterior da busca, preservada para rastreabilidade |
| E06 | [Configuração final](E06_configuracao_corrigida_no_editor.png) | Busca corrigida e programação no editor |
| E07 | [Lista de alertas](E07_alertas_1540_e_1550.png) | Disparos registrados às 15h40, 15h50 e 16h00 (UTC−3) |
| E08 | [Resultado final](E08_resultado_alerta_corrigido_1550.png) | `source="/var/log/kern.log"`, `> 10`, 200 portas e 200 eventos |
| E09 | [Comparação dos testes](E09_comparacao_200_3_portas.png) | Busca manual: 200 portas / 200 eventos (`ALERTA`) versus 3 portas / 3 eventos (`SEM ALERTA`) em janelas distintas |
| E10 | [Reteste: alerta às 01h05](E10_alerta_0105.png) | Novo disparo agendado em 01/11/2026 após o teste positivo de 200 portas |
| E11 | [Agendador do teste negativo](E11_scheduler_negativo_0125.png) | Execuções às 01h20 e 01h25 com `status=success` e `result_count=0`; 01h25 cobre a janela negativa |

Para a validação inicial de 29/10, as evidências centrais são **E07 e E08**. Para o reteste positivo e o teste negativo de 01/11, são **E09, E10 e E11**. A classificação `ALERTA`/`SEM ALERTA` em E09 foi produzida por `eval` em uma busca manual; ela não substitui o histórico do alerta automático (E10) nem o registro do agendador (E11). E04 e E05 pertencem à etapa anterior da configuração e não comprovam a regra final.

O horário exato do comando Nmap de **29/10** não foi registrado em captura de terminal. Em **01/11**, foi observado um novo scan de 200 portas às **00h57**, seguido do alerta às **01h05**. Também foi observado um teste negativo de três portas na janela de **01h15–01h20**, com busca agendada das **01h25** sem resultados acima do limiar. A captura específica do terminal Nmap de 01/11 não faz parte deste conjunto de três novas imagens.

## Integridade

Calculei e registrei no arquivo [SHA256SUMS.txt](SHA256SUMS.txt) os hashes SHA-256 **das onze imagens E01–E11** desta pasta, a partir dos arquivos presentes no GitHub.

A integridade dos arquivos pode ser conferida no diretório `evidence/` com:

```bash
sha256sum -c SHA256SUMS.txt
```

As capturas permanecem como evidências do experimento. A inspeção visual final de dados sensíveis nos arquivos e no histórico do repositório ainda não foi concluída.
