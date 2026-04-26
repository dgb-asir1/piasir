#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Ejecutar como root" && exit 1


read -p "Introduce el nombre del usuario sin espacios: " USUARIO


# variables 
IP_PUBLICA_SERVIDOR=192.168.200.150
PUERTO_VPN=42069
RED_VPN_OCTETOS=(10 0 0 0)
MASCARA_VPN_CIDR=16                
IP_GATEWAY_VPN="${RED_VPN_OCTETOS[0]}.${RED_VPN_OCTETOS[1]}.${RED_VPN_OCTETOS[2]}.1"
FICHERO_IPS=/etc/wireguard/ips_usadas.txt

# guardar las IPS ya usadas en un fichero
if [ ! -f "$FICHERO_IPS" ]; then
    echo "$IP_GATEWAY_VPN gateway" > "$FICHERO_IPS"
fi


# obtener la ultima ip
ULTIMA_IP=$(tail -1 "$FICHERO_IPS" | awk '{print $1}')
OCTETO3=$(echo "$ULTIMA_IP" | cut -d'.' -f3)
OCTETO4=$(echo "$ULTIMA_IP" | cut -d'.' -f4)
PREFIJO_RED=$(echo "$ULTIMA_IP" | cut -d'.' -f1-2)


# sumar 1 al cuarto o tercer octeto
OCTETO4=$((OCTETO4 + 1))
if [ $OCTETO4 -gt 255 ]; then
    OCTETO4=0
    OCTETO3=$((OCTETO3 + 1))
fi

if [ $OCTETO3 -gt 255 ]; then
    echo "Alcanzado maximo de 65.534 clientes en la VPN"
    exit 1
fi

IP_USUARIO="$PREFIJO_RED.$OCTETO3.$OCTETO4"


# crear carpeta usuario
mkdir -p /etc/wireguard/clients/$USUARIO


# crear claves usuario
CLAVE_PRIVADA=$(wg genkey)
CLAVE_PUBLICA=$(echo "$CLAVE_PRIVADA" | wg pubkey)
echo "$CLAVE_PRIVADA" > /etc/wireguard/clients/$USUARIO/${USUARIO}_private.key
echo "$CLAVE_PUBLICA"  > /etc/wireguard/clients/$USUARIO/${USUARIO}_public.key
chmod 600 /etc/wireguard/clients/$USUARIO/${USUARIO}_private.key
chmod 644 /etc/wireguard/clients/$USUARIO/${USUARIO}_public.key


# crear config usuario
RED_VPN_STR="${RED_VPN_OCTETOS[0]}.${RED_VPN_OCTETOS[1]}.${RED_VPN_OCTETOS[2]}.${RED_VPN_OCTETOS[3]}"
cat > /etc/wireguard/clients/$USUARIO/${USUARIO}.conf <<EOF
[Interface]
PrivateKey = $CLAVE_PRIVADA
Address = $IP_USUARIO/$MASCARA_VPN_CIDR
DNS = $IP_GATEWAY_VPN

[Peer]
PublicKey = $(cat /etc/wireguard/piasir_vpn_public.key)
Endpoint = $IP_PUBLICA_SERVIDOR:$PUERTO_VPN
AllowedIPs = $RED_VPN_STR/$MASCARA_VPN_CIDR
PersistentKeepalive = 25
EOF

echo "$IP_USUARIO $USUARIO" >> "$FICHERO_IPS"
echo "Archivo de configuracion creado en /etc/wireguard/clients/$USUARIO/${USUARIO}.conf"
echo "Info para el usuario:"
echo
cat /etc/wireguard/clients/$USUARIO/${USUARIO}.conf


# Añadir usuario al servidor
echo -e "\n# COMIENZO BLOQUE $USUARIO
[Peer]
PublicKey = $CLAVE_PUBLICA
AllowedIPs = $IP_USUARIO/32
# FIN BLOQUE $USUARIO" >> /etc/wireguard/wg0.conf


# Reiniciar WireGuard para aplicar cambios
systemctl restart wg-quick@wg0


# crear codigo qr para exportar .conf del usuario
if command -v qrencode >/dev/null 2>&1; then
    echo
    echo "Código QR para el usuario"
    qrencode -t ansiutf8 < /etc/wireguard/clients/$USUARIO/${USUARIO}.conf
fi

# guardar qr en archivo
qrencode -o /etc/wireguard/clients/$USUARIO/${USUARIO}.png < /etc/wireguard/clients/$USUARIO/${USUARIO}.conf
echo "QR guardado en /etc/wireguard/clients/$USUARIO/${USUARIO}.png"