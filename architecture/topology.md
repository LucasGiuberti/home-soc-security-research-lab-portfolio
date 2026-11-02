# Arquitetura do Home SOC — configuração verificada

Registrei a configuração que observei em 01/11/2026, consultando o Proxmox e as VMs. Alguns endereços são atribuídos por DHCP e podem mudar; não exportei automaticamente os arquivos de configuração das máquinas.

## Topologia lógica

~~~text
Notebook Ubuntu (WireGuard 10.200.0.2)
   | conexão UDP WireGuard (servidor: porta 51820)
LAN doméstica 192.168.6.0/24
   |
Proxmox VE — vmbr0 (192.168.6.104/24; bridge-ports nic0)
   |
   +-- VM 102 VPN Gateway (duas NICs)
   |     ens18 -> vmbr0: 192.168.6.107/24 (DHCP; observado)
   |     ens19 -> vmbr1: 10.10.10.1/24
   |     wg0   -> VPN:   10.200.0.1/24
   |
   +-- VM 101 Ubuntu Splunk (duas NICs)
         ens18 -> vmbr0: 192.168.6.102/24 (DHCP; observado)
         ens19 -> vmbr1: 10.10.10.10/24

Proxmox VE — vmbr1 (bridge-ports none; sem placa física)
   |
   +-- VM 100 Windows 11 / Sysmon — 10.10.10.20 (só vmbr1)
   +-- VM 103 Linux Target       — 10.10.10.30 (só vmbr1)
   +-- VM 101 Splunk             — 10.10.10.10 (também vmbr0)
   +-- VM 102 VPN Gateway        — 10.10.10.1 (também vmbr0)
~~~

**Importante:** VM 101 e VM 102 são *dual-homed* (conectadas às duas bridges). A ausência de placa física na `vmbr1` comprova separação em camada 2 naquele segmento, mas NÃO prova isolamento completo entre LAN e LAB.

## Configurações verificadas

| Máquina | VMID | vCPU | RAM configurada | Disco configurado | Bridges |
|---|---:|---:|---:|---:|---|
| Windows 11 | 100 | 2 | 4 GiB | 40 GB | vmbr1 |
| Ubuntu Splunk | 101 | 2 | 4 GiB | 42 GB | vmbr0, vmbr1 |
| VPN Gateway | 102 | 1 | ~1,9 GiB | 14 GB | vmbr0, vmbr1 |
| Linux Target | 103 | 2 | 2 GiB | 24 GB | vmbr1 |

Os valores são recursos **atribuídos**, não medição de consumo.

- `vmbr0` e `vmbr1`: switches virtuais L2 que encaminham quadros com base em MAC.
- Ubuntu Gateway: `net.ipv4.ip_forward=1`; `FORWARD DROP`, com regras verificadas para iniciar conexões VPN → LAB e permitir respostas estabelecidas/relacionadas LAB → VPN.
- Splunk: interface LAN e LAB; `net.ipv4.ip_forward=0`, portanto não faz encaminhamento IPv4 convencional entre as interfaces.
- A consulta `iptables -t nat -S` no gateway não revelou regras SNAT/MASQUERADE na tabela IPv4 examinada. No Linux Target, os registros mostraram `SRC=10.200.0.2`.

## Evidências e limites

**Validei:** conexão das NICs virtuais às bridges, IPs das interfaces, rotas do Splunk, WireGuard com peer ativo, regras IPv4 da chain `FORWARD` observadas e tráfego autorizado notebook → Linux Target.

**Ainda pretendo verificar:** bloqueio LAB → LAN por teste explícito, regras do firewall Proxmox, acesso a serviços do Splunk pela LAN, eventual filtragem IPv6/nftables e correspondência dos scripts documentados com os arquivos instalados nas VMs.

Uma política `FORWARD DROP` na VM Gateway não bloqueia serviços recebidos diretamente pelas interfaces da VM Gateway ou do Splunk. No gateway, as políticas `INPUT` e `OUTPUT` observadas eram `ACCEPT`.

## Hardening planejado

1. Pretendo reservar o IP DHCP do gateway no roteador, pois variou entre sessões.
2. Pretendo verificar portas e serviços acessíveis pela LAN nas duas VMs dual-homed.
3. Planejo executar um teste controlado de bloqueio LAB → LAN e registrar o resultado.
4. Pretendo revisar a configuração persistente dos firewalls e as regras do Proxmox.

[Gateway Ubuntu e caminho dos pacotes](../infrastructure/vpn-gateway/README.md) · [SOC-LAB-001](../incidents/INC-0001-port-scan/README.md).
