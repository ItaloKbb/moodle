#!/bin/bash
set -euo pipefail

MOODLE_DIR=${MOODLE_DIR:-/var/www/moodle}
MOODLE_DATA=${MOODLE_DATA:-/var/www/moodledata}
ROLE=${MOODLE_ROLE:-web}

run_php() { su -s /bin/bash www-data -c "php $*"; }

mkdir -p "$MOODLE_DATA" "$MOODLE_DATA/phptmp"
chown www-data:www-data "$MOODLE_DATA" "$MOODLE_DATA/phptmp"
# Pasta para subir .mbz grandes e restaurar via CLI (bind mount do host)
if [ -d /var/www/mbz ]; then chmod 755 /var/www/mbz || true; fi

export PGPASSWORD="${MOODLE_DB_PASSWORD:-}"
PSQL=(psql -h "${MOODLE_DB_HOST:-db}" -p "${MOODLE_DB_PORT:-5432}" -U "${MOODLE_DB_USER:-moodle}" -d "${MOODLE_DB_NAME:-moodle}" -tAc)

echo "[moodle] aguardando o banco de dados..."
until "${PSQL[@]}" "SELECT 1" >/dev/null 2>&1; do sleep 2; done
echo "[moodle] banco disponível."

is_installed() {
    [ "$("${PSQL[@]}" "SELECT to_regclass('${MOODLE_DB_PREFIX:-mdl_}config') IS NOT NULL" 2>/dev/null)" = "t" ]
}

if [ "$ROLE" = "cron" ]; then
    echo "[moodle] modo cron: executando admin/cli/cron.php a cada minuto"
    while true; do
        if is_installed; then
            run_php "$MOODLE_DIR/admin/cli/cron.php" || true
        fi
        sleep 60
    done
fi

if is_installed; then
    echo "[moodle] Moodle já instalado — aplicando upgrade (se houver)."
    run_php "$MOODLE_DIR/admin/cli/upgrade.php --non-interactive" || true
elif [ -n "${MOODLE_ADMIN_PASSWORD:-}" ]; then
    echo "[moodle] primeira execução — instalando o banco do Moodle..."
    su -s /bin/bash www-data -c "php '$MOODLE_DIR/admin/cli/install_database.php' \
        --agree-license \
        --lang='${MOODLE_LANG:-en}' \
        --adminuser='${MOODLE_ADMIN_USER:-admin}' \
        --adminpass='${MOODLE_ADMIN_PASSWORD}' \
        --adminemail='${MOODLE_ADMIN_EMAIL:-admin@example.com}' \
        --fullname='${MOODLE_SITE_NAME:-Moodle}' \
        --shortname='${MOODLE_SITE_SHORTNAME:-moodle}'"
    echo "[moodle] instalação concluída."
else
    echo "[moodle] MOODLE_ADMIN_PASSWORD vazio — conclua a instalação pelo navegador."
fi

# Limite de upload do site (0 = usar o limite do servidor/PHP)
if [ -n "${MOODLE_MAXBYTES:-}" ] && is_installed; then
    run_php "$MOODLE_DIR/admin/cli/cfg.php --name=maxbytes --set=${MOODLE_MAXBYTES}" || true
    echo "[moodle] maxbytes=${MOODLE_MAXBYTES}"
fi

exec "$@"
