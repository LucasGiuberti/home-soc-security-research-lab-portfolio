# Ubuntu VPN Gateway — VM 102

## Objetivo

Criei uma VM Ubuntu para permitir que meu notebook alcance as VMs do SOC (`10.10.10.0/24`) por WireGuard. Configurei essa VM como roteador IPv4 e ponto de filtragem. A bridge `vmbr1` funciona como switch virtual de camada 2; o gateway faz roteamento de camada 3.

## Interfaces observadas

| Interface | Papel | Endereço observado |
|---|---|---|
| `ens18` | LAN doméstica, ligada à `vmbr0` | `192.168.6.107/24` (DHCP) |
| `ens19` | Rede LAB, ligada à `vmbr1` | `10.10.10.1/24` |
| `wg0` | Interface virtual do WireGuard | `10.200.0.1/24` |

No meu notebook, o peer utiliza `10.200.0.2`. Na captura, `wg show` apresentava interface escutando em UDP **51820**, handshake recente e tráfego recebido/transmitido. O endereço doméstico da `ens18` mudou entre observações; não deve ser tratado como estático.

## Encaminhamento e controle de acesso

Confirmei na VM `net.ipv4.ip_forward=1`. A política IPv4 da chain `FORWARD` era `DROP`, com estas regras de permissão (transcrição formatada das regras observadas, **não cópia de arquivo de persistência**):

```bash
-P FORWARD DROP
-A FORWARD -s 10.200.0.2/32 -d 10.10.10.0/24 -i wg0 -o ens19 -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s 10.10.10.0/24 -d 10.200.0.2/32 -i ens19 -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
```

Configurei a primeira regra para permitir que **meu peer VPN inicie** comunicações encaminhadas para a rede LAB. A segunda permite respostas **estabelecidas/relacionadas** da LAB ao peer. O restante dos pacotes tratados por essa chain é descartado quando não encontra outra regra correspondente.

As políticas `INPUT` e `OUTPUT` observadas eram `ACCEPT`, portanto `FORWARD DROP` **não bloqueia acesso a serviços hospedados no próprio gateway**. A saída de `iptables -t nat -S` não mostrou regras NAT para IPv4; isso não equivale a uma auditoria completa de nftables, IPv6 ou firewall do host Proxmox.

## Caminho de resposta: Linux Target → notebook

1. O Linux Target (`10.10.10.30`) cria um pacote com destino **final** `10.200.0.2`.
2. Como o destino está fora de sua sub-rede `10.10.10.0/24`, o sistema usa o próximo salto definido por sua rota, normalmente o gateway `10.10.10.1`.
3. A bridge `vmbr1` encaminha o quadro Ethernet ao MAC da interface `ens19`; **o IP de destino original continua `10.200.0.2`**.
4. O kernel do gateway consulta sua tabela de roteamento, usa `wg0` como saída e verifica a regra stateful na chain `FORWARD`.
5. O WireGuard seleciona o peer, criptografa e encapsula o pacote IP original.
6. O pacote UDP externo percorre a LAN via `ens18` até o endpoint WireGuard do notebook. O notebook decapsula e entrega o pacote original.

Os registros do Linux Target apresentaram `SRC=10.200.0.2`, consistente com encaminhamento do fluxo sem mascaramento SNAT.

## Comandos utilizados na verificação

```bash
ip -br addr
ip route
sysctl net.ipv4.ip_forward
sudo iptables -S FORWARD
sudo iptables -t nat -S
sudo wg show
```

Nas evidências públicas, mantive a documentação sem chaves privadas. Evitei incluir arquivos WireGuard completos e comandos destrutivos de firewall ou de reconfiguração de interfaces.

## Limites e hardening pendente

- Pretendo testar efetivamente o bloqueio LAB → LAN e documentar o resultado.
- Pretendo verificar as regras de firewall do Proxmox e a eventual pilha IPv6/nftables.
- Pretendo revisar os serviços acessíveis pela LAN nas VMs gateway e Splunk.
- Pretendo reservar o IP da VM gateway no DHCP; observei mudanças no endereço da LAN entre sessões.
- Ainda preciso comparar os arquivos persistidos na VM com esta documentação para demonstrar a reprodução exata da configuração.

[Arquitetura completa](../../architecture/topology.md) · [Estudo de caso](../../incidents/INC-0001-port-scan/README.md).
