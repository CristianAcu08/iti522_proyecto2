#!/bin/bash
# Script de restauración de base de datos desde un backup en Blob Storage
# Requiere: azcopy o Azure CLI, y acceso a la base de datos destino
# Variables de entorno:
#   BLOB_ACCOUNT_NAME, BLOB_CONTAINER_NAME, BLOB_SAS_TOKEN or AZURE_STORAGE_KEY
#   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS
#   BACKUP_FILE_NAME: nombre exacto del archivo .gz en el contenedor (ej: inventario_db_backup_20260817_023000.sql.gz)

set -euo pipefail

echo "=== Iniciando restauración de base de datos ==="

# Configuración
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-inventario_db}"
DB_USER="${DB_USER:-app_user}"
DB_PASS="${DB_PASS:-AppPassw0rd!}"

BLOB_ACCOUNT_NAME="${BLOB_ACCOUNT_NAME:-tiendacomputostorage}"
BLOB_CONTAINER_NAME="${BLOB_CONTAINER_NAME:-db-backups}"
BLOB_SAS_TOKEN="${BLOB_SAS_TOKEN:-}"
AZURE_STORAGE_KEY="${AZURE_STORAGE_KEY:-}"
BACKUP_FILE_NAME="${BACKUP_FILE_NAME:-}"

if [ -z "$BACKUP_FILE_NAME" ]; then
    echo "Error: Se debe especificar la variable de entorno BACKUP_FILE_NAME con el nombre del archivo de backup en Blob Storage."
    exit 1
fi

# Archivos temporales
TEMP_DIR="/tmp/restore_$$"
mkdir -p "$TEMP_DIR"
ENCRYPTED_FILE="$TEMP_DIR/${BACKUP_FILE_NAME}"
DECOMPRESSED_FILE="$TEMP_DIR/$(basename "$BACKUP_FILE_NAME" .gz)"

echo "Parámetros:"
echo "  - Base de datos destino: $DB_NAME@$DB_HOST:$DB_PORT"
echo "  - Usuario: $DB_USER"
echo "  - Archivo de backup en Blob: $BLOB_ACCOUNT_NAME/$BLOB_CONTAINER_NAME/$BACKUP_FILE_NAME"
echo "  - Directorio temporal: $TEMP_DIR"

# 1. Descargar el backup desde Blob Storage
echo "Descargando backup desde Blob Storage..."
if [ -n "$BLOB_SAS_TOKEN" ]; then
    BLOB_URL="https://${BLOB_ACCOUNT_NAME}.blob.core.windows.net/${BLOB_CONTAINER_NAME}/${BACKUP_FILE_NAME}?${BLOB_SAS_TOKEN}"
    azcopy copy "$BLOB_URL" "$ENCRYPTED_FILE" --overwrite=true
elif [ -n "$AZURE_STORAGE_KEY" ]; then
    export AZURE_STORAGE_ACCOUNT="$BLOB_ACCOUNT_NAME"
    export AZURE_STORAGE_KEY="$AZURE_STORAGE_KEY"
    azcopy copy "https://${BLOB_ACCOUNT_NAME}.blob.core.windows.net/${BLOB_CONTAINER_NAME}/${BACKUP_FILE_NAME}" "$ENCRYPTED_FILE" --overwrite=true
else
    echo "Error: No se proporcionó método de autenticación para Blob Storage"
    exit 1
fi

echo "Backup descargado: $ENCRYPTED_FILE"

# 2. Descomprimir el backup
echo "Descomprimiendo el backup..."
gunzip -f "$ENCRYPTED_FILE"
echo "Backup descomprimido: $DECOMPRESSED_FILE"

# 3. Detener conexiones y eliminar base de datos existente (opcional, según política)
echo "Preparando base de datos destino..."
export PGPASSWORD="$DB_PASS"

# Opción 1: Eliminar y crear nueva base de datos (más limpio para pruebas)
echo "Eliminando base de datos existente (si existe)..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;" || echo "No se pudo eliminar la base de datos (quizás tenga conexiones activas)"

echo "Creando nueva base de datos..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "GRANT ALL ON SCHEMA public TO $DB_USER;"

# Opción 2: Solo limpiar el esquema público (mantener la base de datos)
# sudo -u postgres psql -d $DB_NAME -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO $DB_USER;"

# 4. Restaurar el dump
echo "Restaurando el dump..."
export PGPASSWORD="$DB_PASS"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$DECOMPRESSED_FILE"

echo "Restauración completada."

# 5. Opcional: vacuum analyze para actualizar estadísticas
echo "Ejecutando VACUUM ANALYZE..."
sudo -u postgres psql -d $DB_NAME -c "VACUUM ANALYZE;"

# 6. Limpiar archivos temporales
rm -rf "$TEMP_DIR"

echo "=== Restauración completada ==="
echo "Resumen:"
echo "  - Backup restaurado: $BACKUP_FILE_NAME"
echo "  - Base de datos: $DB_NAME"
echo "  - Hora de finalización: $(date)"
echo ""
echo "Próximos pasos:"
echo "  1. Verificar que los datos estén íntegros (contar filas, chequear muestras)"
echo "  2. Probar la aplicación con la base de datos restaurada"
echo "  3. Documentar el tiempo de restauración (RTO) y la puntualidad del backup (RPO)"
