#!/bin/bash
# Script para desplegar el frontend en Azure Static Web Apps

set -euo pipefail

echo "=== Despliegue de Frontend en Azure Static Web Apps ==="

# Configuración de variables
RESOURCE_GROUP="${RESOURCE_GROUP:-tiendacomputo-rg}"
STATIC_APP_NAME="${STATIC_APP_NAME:-tiendacomputo-frontend}"
RG_LOCATION="eastus"         # Ubicación del grupo de recursos existente
APP_LOCATION="centralus"     # Región habilitada para Static Web Apps según políticas

# 1. Asegurar grupo de recursos en su ubicación original (eastus)
echo "Asegurando grupo de recursos: $RESOURCE_GROUP en $RG_LOCATION"
az group create --name "$RESOURCE_GROUP" --location "$RG_LOCATION" --output none

# 2. Crear Static Web App en la región permitida (centralus)
echo "Creando Static Web App: $STATIC_APP_NAME en $APP_LOCATION"
az staticwebapp create \
  --name "$STATIC_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$APP_LOCATION"

# 3. Obtener URL pública asignada por Azure
STATIC_URL=$(az staticwebapp show \
  --name "$STATIC_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "defaultHostname" \
  --output tsv)

echo "=== Despliegue de Frontend completado ==="
echo "Grupo de recursos: $RESOURCE_GROUP"
echo "Static Web App: $STATIC_APP_NAME"
echo "URL de la aplicación: https://$STATIC_URL"
