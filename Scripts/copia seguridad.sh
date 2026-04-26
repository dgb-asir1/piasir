
#!/bin/bash

ORIGEN="/srv/media/"
DESTINO="/mnt/backups/"
LOG="/var/log/backup.log"

echo "$(date "+%Y-%m-%d %H:%M:%S") - Comienzo copia seguridad" > "$LOG"

rsync -avz --delete "$ORIGEN" "$DESTINO" >> "$LOG" 2>&1

# Código de salida con fecha
if [ $? -eq 0 ]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Copia realizada  correctamente" >> "$LOG"
else
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Error en copia" >> "$LOG"
fi







