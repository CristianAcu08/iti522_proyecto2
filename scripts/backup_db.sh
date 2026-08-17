#!/bin/bash
# Script de backup lógico de PostgreSQL a Azure Blob Storage
# Requiere: azcopy o Azure CLI instalado y autenticado
# Variables de entorno esperadas:
#   BLOB_ACCOUNT_NAME: nombre de la cuenta de almacenamiento
#   BLOB_CONTAINER_NAME: nombre del contenedor (ej: db-backups)
#   BLOB_SAS_TOKEN o AZURE_STORAGE_KEY: para autenticación
#   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS: para conexión a PostgreSQL

set -euo pipefail

echo "=== Iniciando backup lógico de base de datos ==="

# Configuración (pueden sobrescribirse con variables de entorno)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-inventario_db}"
DB_USER="${DB_USER:-app_user}"
DB_PASS="${DB_PASS:-AppPassw0rd!}"

BLOB_ACCOUNT_NAME="${BLOB_ACCOUNT_NAME:-tiendacomputostorage}"
BLOB_CONTAINER_NAME="${BLOB_CONTAINER_NAME:-db-backups}"
# Autenticación: preferir SAS token, luego clave
BLOB_SAS_TOKEN="${BLOB_SAS_TOKEN:-}"
AZURE_STORAGE_KEY="${AZURE_STORAGE_KEY:-}"

# Timestamp para nombre de archivo
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/tmp/${DB_NAME}_backup_${TIMESTAMP}.sql"
COMPRESSED_FILE="${BACKUP_FILE}.gz"

echo "Parámetros:"
echo "  - Base de datos: $DB_NAME@$DB_HOST:$DB_PORT"
echo "  - Usuario: $DB_USER"
echo "  - Archivo de backup temporal: $BACKUP_FILE"
echo "  - Contenedor de Blob: $BLOB_ACCOUNT_NAME/$BLOB_CONTAINER_NAME"

# 1. Crear dump de la base de datos
echo "Creando dump de la base de datos..."
export PGPASSWORD="$DB_PASS"
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -F p -b -v -f "$BACKUP_FILE" "$DB_NAME"

# 2. Comprimir el dump
echo "Comprimiendo el backup..."
gzip -f "$BACKUP_FILE"
echo "Backup comprimido: $COMPRESSED_FILE"

# 3. Subir a Azure Blob Storage
echo "Subiendo a Azure Blob Storage..."
if [ -n "$BLOB_SAS_TOKEN" ]; then
    BLOB_URL="https://${BLOB_ACCOUNT_NAME}.blob.core.windows.net/${BLOB_CONTAINER_NAME}/${COMPRESSED_FILE##*/}?${BLOB_SAS_TOKEN}"
    azcopy copy "$COMPRESSED_FILE" "$BLOB_URL" --overwrite=true
elif [ -n "$AZURE_STORAGE_KEY" ]; then
    export AZURE_STORAGE_ACCOUNT="$BLOB_ACCOUNT_NAME"
    export AZURE_STORAGE_KEY="$AZURE_STORAGE_KEY"
    azcopy copy "$COMPRESSED_FILE" "https://${BLOB_ACCOUNT_NAME}.blob.core.windows.net/${BLOB_CONTAINER_NAME}/${COMPRESSED_FILE##*/}" --overwrite=true
else
    echo "Error: No se proporcionó método de autenticación para Blob Storage (BLOB_SAS_TOKEN o AZURE_STORAGE_KEY)"
    exit 1
fi

echo "Backup subido exitosamente."

# 4. Limpiar archivos locales antiguos (mantener últimos 7 días)
echo "Limpiando backups locales antiguos (más de 7 días)..."
find /tmp -name "${DB_NAME}_backup_*.sql.gz" -mtime +7 -delete -print

# 5. Opcional: eliminar el dump comprimido local si no se necesita conservar
# rm -f "$COMPRESSED_FILE"

echo "=== Backup completado ==="
echo "Resumen:"
echo "  - Archivo original: $BACKUP_FILE"
echo "  - Archivo comprimido y subido: $COMPRESSED_FILE"
echo "  - Destino: $BLOB_ACCOUNT_NAME/$BLOB_CONTAINER_NAME/"
echo "  - Hora de finalización: $(date)"
