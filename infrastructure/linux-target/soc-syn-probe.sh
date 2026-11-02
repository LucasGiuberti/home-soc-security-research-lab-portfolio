#!/bin/bash
set -eu

# Restaura somente a regra de logging do laboratório.
# Não substitui a política de firewall do host.
if ! /usr/sbin/iptables -C INPUT \
  -p tcp --tcp-flags SYN,RST,ACK,FIN SYN \
  -m limit --limit 30/second --limit-burst 200 \
  -j LOG --log-prefix "SYN_PROBE " --log-level 4 2>/dev/null
then
  /usr/sbin/iptables -I INPUT 1 \
    -p tcp --tcp-flags SYN,RST,ACK,FIN SYN \
    -m limit --limit 30/second --limit-burst 200 \
    -j LOG --log-prefix "SYN_PROBE " --log-level 4
fi
