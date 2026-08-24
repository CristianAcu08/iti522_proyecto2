#!/bin/bash
# Despliega la version parcheada del frontend (app/frontend_legacy) a la Static Web App existente.
# Esta version es la copia de lo que esta en produccion con los colores corregidos:
#   - Boton Editar   -> celeste (#0ea5e9)
#   - Boton Eliminar -> rojo   (#ef4444)
#
# Requisitos: Azure CLI instalado y autenticado (az login) con la cuenta que tiene
#             acceso a los recursos del proyecto (grupo tiendacomputo-rg).

set -euo pipefail

SWA_NAME="${1:-tiendacomputo-frontend}"
RESOURCE_GROUP="${RESOURCE_GROUP:-tiendacomputo-rg}"
HOSTNAME_TARGET="thankful-beach-0672df110.7.azurestaticapps.net"

echo "=== Despliegue del parche de colores a la Static Web App ==="

# 1. Verificar autenticacion
az account show --query "user.name" -o tsv

# 2. Localizar la Static Web App (por nombre o por hostname)
if ! az staticwebapp show --name "$SWA_NAME" --resource-group "$RESOURCE_GROUP" --query "name" -o tsv >/dev/null 2>&1; then
  echo "No se encontro '$SWA_NAME' en el grupo '$RESOURCE_GROUP'. Buscando por hostname..."
  SWA_NAME=$(az staticwebapp list --query "[?properties.defaultHostname=='$HOSTNAME_TARGET'].name" -o tsv | head -1)
  if [ -z "$SWA_NAME" ]; then
    echo "ERROR: No se encontro ninguna Static Web App con hostname $HOSTNAME_TARGET."
    echo "Static Web Apps visibles para esta cuenta:"
    az staticwebapp list --query "[].{name:name, rg:resourceGroup, host:properties.defaultHostname}" -o table
    exit 1
  fi
  RESOURCE_GROUP=$(az staticwebapp show --name "$SWA_NAME" --query "resourceGroup" -o tsv)
fi

echo "Desplegando en: $SWA_NAME (grupo de recursos: $RESOURCE_GROUP)"

# 3. Subir la carpeta parcheada
cd "$(dirname "$0")/../app/frontend_legacy"
az staticwebapp deploy \
  --name "$SWA_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --source-dir . \
  --environment Production

echo "=== Despliegue completado ==="
echo "Verifica en: https://$HOSTNAME_TARGET/  (usar Ctrl+Shift+R para limpiar la cache)"
echo "Si el deploy falla por el parametro --environment, ejecutalo sin ese parametro."
