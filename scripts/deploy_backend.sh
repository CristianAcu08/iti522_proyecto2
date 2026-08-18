#!/bin/bash
# Script para desplegar el backend en Azure App Service

set -euo pipefail

echo "=== Despliegue de Backend en Azure App Service ==="

# Configuración de variables
RESOURCE_GROUP="${RESOURCE_GROUP:-tiendacomputo-rg}"
LOCATION="${LOCATION:-eastus}"
PLAN_NAME="${PLAN_NAME:-tiendacomputo-api-plan}"
APP_NAME="${APP_NAME:-tiendacomputo-api}"

# 1. Crear grupo de recursos si no existe
echo "Asegurando grupo de recursos: $RESOURCE_GROUP"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# 2. Crear plan de App Service
echo "Creando plan de App Service: $PLAN_NAME"
az appservice plan create \
  --name "$PLAN_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku B1 \
  --is-linux \
  --output none

# 3. Crear App Service con la versión soportada obtenida de la CLI (NODE|22-lts)
echo "Creando App Service: $APP_NAME"
az webapp create \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$PLAN_NAME" \
  --name "$APP_NAME" \
  --runtime "NODE|22-lts"

echo "=== Despliegue de Backend completado ==="
