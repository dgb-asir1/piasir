#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Ejecutar como root" && exit 1

# variables 
INTERFAZ_RED=ens33
PUERTO_VPN=42069
RED_VPN=10.0.0.0
MASCARA_VPN_CIDR=16    
IP_GATEWAY_VPN=10.0.0.1
PUERTO_JELLYFIN=8096

# instalar
apt update
apt install -y wireguard qrencode

# crear carpeta config
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

# crear claves solo si no existen ya
if [ ! -f /etc/wireguard/piasir_vpn_private.key ]; then
    CLAVE_PRIVADA=$(wg genkey)
    CLAVE_PUBLICA=$(echo "$CLAVE_PRIVADA" | wg pubkey)
    echo "$CLAVE_PRIVADA" > /etc/wireguard/piasir_vpn_private.key
    echo "$CLAVE_PUBLICA"  > /etc/wireguard/piasir_vpn_public.key
    chmod 600 /etc/wireguard/piasir_vpn_private.key
    chmod 644 /etc/wireguard/piasir_vpn_public.key
else
    CLAVE_PRIVADA=$(cat /etc/wireguard/piasir_vpn_private.key)
    CLAVE_PUBLICA=$(cat /etc/wireguard/piasir_vpn_public.key)
fi

# activar reenvio de paquetes
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -p

# variables reglas wireguard
REGLA1="FORWARD -i wg0 -o $INTERFAZ_RED -j ACCEPT"                                       # vpn -> internet
REGLA2="FORWARD -i $INTERFAZ_RED -o wg0 -m state --state ESTABLISHED,RELATED -j ACCEPT"  # internet -> vpn, solo respuestas
REGLA3="POSTROUTING -o $INTERFAZ_RED -j MASQUERADE"                                       # nat, cambia ip vpn por ip publica

# escribir fichero config
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = $IP_GATEWAY_VPN/$MASCARA_VPN_CIDR
ListenPort = $PUERTO_VPN
PrivateKey = $CLAVE_PRIVADA
MTU = 1420

PostUp = iptables -A $REGLA1; \
         iptables -A $REGLA2; \
         iptables -t nat -A $REGLA3

PostDown = iptables -D $REGLA1; \
           iptables -D $REGLA2; \
           iptables -t nat -D $REGLA3
EOF

chmod 600 /etc/wireguard/wg0.conf

# habilitar e iniciar wireguard
systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

wg show