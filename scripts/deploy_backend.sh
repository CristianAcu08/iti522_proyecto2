#!/bin/bash
# Script para desplegar el backend en Azure App Service
# Requisitos: Azure CLI instalado y autenticado (az login)
# Variables de entorno esperadas (o modificar directamente):
#   RESOURCE_GROUP: nombre del grupo de recursos
#   APP_SERVICE_NAME: nombre único para el App Service
#   LOCATION: región de Azure (ej: eastus)
#   SKU: plan de precios (ej: B1 para Basic)
#   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS: credenciales de la base de datos
#   FRONTEND_URL: opcional, para CORS

set -euo pipefail

echo "=== Despliegue de Backend en Azure App Service ==="

# Configuración (pueden ser variables de entorno o modificarse aquí)
RESOURCE_GROUP="${RESOURCE_GROUP:-tiendacomputo-rg}"
APP_SERVICE_NAME="${APP_SERVICE_NAME:-tiendacomputo-api}"
LOCATION="${LOCATION:-eastus}"
SKU="${SKU:-B1}"  # Basic B1

# 1. Crear grupo de recursos si no existe
echo "Creando grupo de recursos: $RESOURCE_GROUP en $LOCATION"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# 2. Crear plan de App Service
echo "Creando plan de App Service: ${APP_SERVICE_NAME}-plan"
az appservice plan create   --name "${APP_SERVICE_NAME}-plan"   --resource-group "$RESOURCE_GROUP"   --location "$LOCATION"   --sku "$SKU"   --is-linux   --output none

# 3. Crear la aplicación web
echo "Creando App Service: $APP_SERVICE_NAME"
az webapp create   --resource-group "$RESOURCE_GROUP"   --plan "${APP_SERVICE_NAME}-plan"   --name "$APP_SERVICE_NAME"   --runtime "NODE|18-lts"   --output none

# 4. Configurar despliegue desde repositorio local (Git)
#    Asumimos que el código está en el subdirectorio app/backend
echo "Configuring local Git deployment..."
# Obtener la URL de despliegue
DEPLOYMENT_URL=$(az webapp deployment source config-local-git   --resource-group "$RESOURCE_GROUP"   --name "$APP_SERVICE_NAME"   --query url   --output tsv)

if [ -z "$DEPLOYMENT_URL" ]; then
  echo "Error: No se pudo obtener la URL de despliegue Git."
  exit 1
fi

echo "URL de despliegue Git: $DEPLOYMENT_URL"

# 5. Añadir remoto de Azure y empujar
cd app/backend
if [ ! -d ".git" ]; then
  git init
  git add .
  git config user.name "Equipo ITI-522"
  git config user.email "iti522@example.com"
  git commit -m "Preparar despliegue inicial"
fi

# Eliminar remoto azure si existe para evitar conflictos
git remote remove azure 2>/dev/null || true
git remote add azure "$DEPLOYMENT_URL"
echo "Empujando código a Azure App Service..."
git push azure master --force

# 6. Configurar variables de entorno en la App Service
echo "Configurando variables de entorno..."
az webapp config appsettings set   --resource-group "$RESOURCE_GROUP"   --name "$APP_SERVICE_NAME"   --settings     DB_HOST="$DB_HOST"     DB_PORT="$DB_PORT"     DB_NAME="$DB_NAME"     DB_USER="$DB_USER"     DB_PASS="$DB_PASS"     PUERTO="$PUERTO"     FRONTEND_URL="${FRONTEND_URL:-}"   --output none

# 7. Habilitar logs de contenedor para depuración (opcional)
az webapp log config   --resource-group "$RESOURCE_GROUP"   --name "$APP_SERVICE_NAME"   --application-logging true   --detailed-error-messages true   --failed-request-tracing true   --output none

# 8. Obtener la URL de la aplicación
APP_URL=$(az webapp show   --resource-group "$RESOURCE_GROUP"   --name "$APP_SERVICE_NAME"   --query defaultHostName   --output tsv)

echo "=== Despliegue completado ==="
echo "Grupo de recursos: $RESOURCE_GROUP"
echo "App Service: $APP_SERVICE_NAME"
echo "URL de la API: https://$APP_URL"
echo ""
echo "Próximos pasos:"
echo "  1. Probar la API: curl https://$APP_URL/health"
echo "  2. Ver logs: az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME"
echo "  3. Configurar el frontend para consumir esta URL (actualizar FRONTEND_URL en el backend o en el frontend)"
