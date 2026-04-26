#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Ejecutar como root" && exit 1

IP_PRINCIPAL="192.168.200.150"

# instalar
apt update
apt install -y ufw

# reset
ufw --force reset

# políticas por defecto
ufw default deny incoming
ufw default allow outgoing

ufw allow 22/tcp

# permitir TODO desde el servidor principal
ufw allow from $IP_PRINCIPAL

# habilitar
ufw --force enable

# ver estado
ufw status verbose