# Sensor TCP SYN do Linux Target

O sensor registra pacotes TCP SYN recebidos no endpoint e acrescenta o prefixo `SYN_PROBE` aos registros do kernel. Não bloqueia conexões.

Documentei nesta pasta uma **reconstituição do script e do serviço `systemd`** que utilizei no experimento, com base nas configurações e saídas de terminal registradas. Não extraí os arquivos diretamente da VM; por isso, ainda não confirmei se esta versão é idêntica aos arquivos instalados em `/usr/local/sbin/soc-syn-probe.sh` e `/etc/systemd/system/soc-syn-probe.service`.

## Procedimento de instalação documentado

Preparei o procedimento para um endpoint Ubuntu de teste, com `iptables` disponível em `/usr/sbin/iptables`. Os comandos configuram o logging do endpoint, sem alterar o gateway da VPN.

```bash
sudo install -m 750 soc-syn-probe.sh /usr/local/sbin/soc-syn-probe.sh
sudo install -m 644 soc-syn-probe.service /etc/systemd/system/soc-syn-probe.service
sudo systemctl daemon-reload
sudo systemctl enable --now soc-syn-probe.service
```

Para verificar a regra e o serviço, utilizei os seguintes comandos:

```bash
sudo systemctl status soc-syn-probe.service
sudo iptables -L INPUT -n -v --line-numbers
sudo iptables-save | grep -c SYN_PROBE
```

A contagem esperada é `1` enquanto uma única regra do sensor estiver configurada. Na execução documentada em 29/10/2026, o serviço retornou `status=0/SUCCESS` após reboot e uma única regra `SYN_PROBE` estava presente.

No script, implementei uma verificação de regra equivalente antes de inserir outra, para evitar duplicações em condições normais. Ele **não persiste o restante das regras do firewall** nem implementa controle de acesso. O log é limitado a 30 eventos/s, burst 200; não considero esse sensor uma fonte de cobertura integral do tráfego de rede.

Mais detalhes: [SOC-LAB-001](../../incidents/INC-0001-port-scan/README.md).
