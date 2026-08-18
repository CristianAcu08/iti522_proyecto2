#!/bin/bash
# Script para instalar y configurar la base de datos en la VM
# Proyecto 2 - ITI-522 Computación en la Nube

set -euo pipefail

echo "=== Instalando Motor de Base de Datos en la VM ==="

# Actualizar repositorios e instalar paquetes necesarios
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib

# Asegurar que el servicio de PostgreSQL esté corriendo
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Crear usuario y base de datos iniciales
sudo -u postgres psql -c "CREATE USER app_user WITH PASSWORD 'AppPassw0rd!';" || echo "Usuario ya existe"
sudo -u postgres psql -c "CREATE DATABASE inventario_db OWNER app_user;" || echo "BD ya existe"

# Ejecutar script de inicialización de tablas
sudo -u postgres psql -d inventario_db -f /home/unti/iti522_proyecto2/scripts/init_db.sql
sudo -u postgres psql -d inventario_db -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;"
sudo -u postgres psql -d inventario_db -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_user;"

echo "=== Base de datos instalada y lista ==="
