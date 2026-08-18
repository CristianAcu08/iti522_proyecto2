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

echo "=== Base de datos instalada y lista ==="
