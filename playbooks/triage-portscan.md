# Playbook SOC — triagem de varredura de portas

Este é o procedimento de triagem que defini para investigar alertas de port scan no Home SOC. Foi preparado a partir do cenário controlado **SOC-LAB-001**; não representa um procedimento implantado em um SOC de produção.

## Fluxo de análise

1. **Validação do evento:** começo pelos logs brutos, pelo horário e pelos campos `src`, `dst` e `dpt`.
2. **Identificação da origem:** verifico se o IP pertence a um scanner autorizado, à VPN de testes ou a outro ativo conhecido.
3. **Caracterização do tráfego:** analiso o número de portas distintas, a duração, a frequência das tentativas e a quantidade de destinos.
4. **Contexto adicional:** procuro eventos relacionados, como falhas de autenticação, execuções de processos e conexões de saída.
5. **Correlação temporal:** separo atividades distintas e considero o atraso entre o horário do evento e a ingestão no Splunk.
6. **Hipóteses:** registro evidências que sustentam ou enfraquecem a hipótese de reconhecimento.
7. **Classificação:** diferencio teste autorizado, atividade benigna, comportamento suspeito e resultado inconclusivo.
8. **Registro:** documento a conclusão, as evidências disponíveis e as recomendações proporcionais ao contexto.

Uma varredura de portas, isoladamente, **não comprova comprometimento**. No SOC-LAB-001, a atividade foi gerada de forma autorizada com Nmap e serviu para validar a detecção.

[Estudo de caso e evidências](../incidents/INC-0001-port-scan/README.md)
