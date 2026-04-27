#!/bin/bash
set -e

DESTINO="/mnt/backups"
LOG="/var/log/backup.log"

echo "$(date "+%Y-%m-%d %H:%M:%S") - Comienzo copia seguridad con BDDD" > "$LOG"

rsync -avz --delete /srv/media/ "$DESTINO/media/" >> "$LOG" 2>&1
rsync -avz --delete /srv/docker/wordpress/ "$DESTINO/wordpress/" >> "$LOG" 2>&1
rsync -avz --delete /srv/docker/jellyfin/ "$DESTINO/jellyfin/" >> "$LOG" 2>&1

# dump mysql
echo "$(date "+%Y-%m-%d %H:%M:%S") - Dump MySQL" >> "$LOG"

docker exec docker-mysql-1 \
  mysqldump -u root -p$(docker exec docker-mysql-1 printenv MYSQL_ROOT_PASSWORD) --all-databases \
  > "$DESTINO/mysql_dump.sql" 2>> "$LOG"