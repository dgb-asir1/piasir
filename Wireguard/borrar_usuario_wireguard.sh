#!/bin/bash

[ "$EUID" -ne 0 ] && echo "Ejecutar como root" && exit 1

read -p "Introduce el nombre del usuario a eliminar: " USUARIO


# borrar carpeta del usuario
CARPETA_USUARIO="/etc/wireguard/clients/$USUARIO"
if [ -d "$CARPETA_USUARIO" ]; then
    rm -rf "$CARPETA_USUARIO"
    echo "Archivos del usuario eliminados: $CARPETA_USUARIO"
else
    echo "No existe carpeta del usuario: $CARPETA_USUARIO"
fi

# quitar del archivo de IPs usadas
FICHERO_IPS="/etc/wireguard/ips_usadas.txt"
if [ -f "$FICHERO_IPS" ]; then
    sed -i "/ $USUARIO$/d" "$FICHERO_IPS"
    echo "Entrada eliminada de $FICHERO_IPS"
fi

# quitar el bloque del usuario del servidor wg0.conf
WG_CONF="/etc/wireguard/wg0.conf"
if [ -f "$WG_CONF" ]; then
    sed -i "/# COMIENZO BLOQUE $USUARIO/,/# FIN BLOQUE $USUARIO/d" "$WG_CONF"
    echo "Bloque del usuario eliminado de $WG_CONF"
fi

# reiniciar 
systemctl restart wg-quick@wg0
echo "Usuario $USUARIO eliminado."