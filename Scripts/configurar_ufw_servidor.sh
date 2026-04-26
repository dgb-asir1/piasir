#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Ejecutar como root" && exit 1

# variables
PUERTO_VPN=42069
RED_VPN=10.0.0.0
MASCARA_VPN_CIDR=16
PUERTO_JELLYFIN=8096
PUERTO_WORDPRESS=8080

# instalar
apt update
apt install -y ufw

# politica por defecto
ufw default deny incoming
ufw default allow outgoing

# reglas
ufw allow 22/tcp                                            # ssh
ufw allow $PUERTO_VPN/udp                                   # wireguard

# servicios solo accesibles desde la VPN
ufw allow from $RED_VPN/$MASCARA_VPN_CIDR to any port $PUERTO_WORDPRESS proto tcp   # wordpress
ufw allow from $RED_VPN/$MASCARA_VPN_CIDR to any port $PUERTO_JELLYFIN proto tcp    # jellyfin

# habilitar
ufw --force enable

# ver estado
ufw status verbose