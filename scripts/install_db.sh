#!/bin/bash
# Script de instalación y configuración básica de PostgreSQL 15 en Ubuntu 22.04
# Diseñado para ser ejecutado como root o con sudo

set -euo pipefail

echo "=== Iniciando instalación de PostgreSQL 15 ==="

# Actualizar paquetes
apt-get update -y

# Instalar PostgreSQL 15 y contrib
apt-get install -y postgresql postgresql-contrib

# Detener servicio para configurar
systemctl stop postgresql

# Configurar postgresql.conf para escuchar en todas las interfaces (necesario para conexión desde App Service)
# NOTA: En producción, restringir a rangos de IP específicos o usar SSL/VPN.
CONF_FILE="/etc/postgresql/15/main/postgresql.conf"
if [ -f "$CONF_FILE" ]; then
    # Hacer copia de seguridad
    cp "$CONF_FILE" "${CONF_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    # Cambiar listen_addresses
    sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" "$CONF_FILE"
    # Si ya estaba descomentado pero con otro valor, forzamos a '*'
    sed -i "s/^listen_addresses = .*/listen_addresses = '*'/" "$CONF_FILE"
    echo "Configurado postgresql.conf para escuchar en todas las IP (listen_addresses = '*')"
else
    echo "Advertencia: No se encontró $CONF_FILE"
fi

# Configurar pg_hba.conf para permitir conexiones desde la App Service y administración
# NOTA: En producción, usar rangos de IP más restringidos y autenticación fuerte (md5 o scram-sha-256)
HBA_FILE="/etc/postgresql/15/main/pg_hba.conf"
if [ -f "$HBA_FILE" ]; then
    cp "$HBA_FILE" "${HBA_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    # Añadir líneas para permitir conexiones desde cualquier IP (para simplificar en academia)
    # En producción, reemplazar 0.0.0.0/0 por el rango de la App Service o VNet
    echo "" >> "$HBA_FILE"
    echo "# ==== AÑADIDO POR SCRIPT DE INSTALACIÓN ==== " >> "$HBA_FILE"
    echo "# Permitir conexiones desde cualquier IP usando md5 (cambiar en producción)" >> "$HBA_FILE"
    echo "host    all             all             0.0.0.0/0               md5" >> "$HBA_FILE"
    echo "# =========================================== " >> "$HBA_FILE"
    echo "Configurado pg_hba.conf para permitir conexiones desde cualquier IP (md5)"
else
    echo "Advertencia: No se encontró $HBA_FILE"
fi

# Iniciar servicio
systemctl start postgresql
systemctl enable postgresql

# Esperar a que PostgreSQL esté listo
sleep 5

# Crear base de datos y usuario de aplicación
DB_NAME="inventario_db"
DB_USER="app_user"
DB_PASS="AppPassw0rd!"  # En producción, usar una contraseña fuerte y manejarla como secreto

echo "Creando base de datos '$DB_NAME' y usuario '$DB_USER'..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "GRANT ALL ON SCHEMA public TO $DB_USER;"

echo "Base de datos y usuario creados."

# Opcional: crear tabla de ejemplo para pruebas
sudo -u postgres psql -d $DB_NAME <<SQL
CREATE TABLE IF NOT EXISTS articulos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SQL

echo "Tabla de ejemplo 'articulos' asegurada."

echo "=== Instalación de PostgreSQL completada ==="
echo "Resumen:"
echo "  - Servicio: postgresql (puerto 5432)"
echo "  - Base de datos: $DB_NAME"
echo "  - Usuario: $DB_USER"
echo "  - Contraseña: $DB_PASS  (¡CAMBIAR EN PRODUCCIÓN!)"
echo "  - Conexión permitida desde: 0.0.0.0/0 (ajustar pg_hba.conf para producción)"
echo ""
echo "Próximos pasos:"
echo "  1. Probar conexión desde otra máquina: psql -h <IP_VM> -U $DB_USER -d $DB_NAME"
echo "  2. Revisar y endurecer configuración de firewall (UFW/Núcleo) y pg_hba.conf"
echo "  3. Considerar habilitar SSL para conexiones a la BD"
