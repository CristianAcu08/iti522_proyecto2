# Despliegue en la Nube y Configuración de Alta Disponibilidad

Este documento describe los pasos para desplegar la solución en Azure, configurar los servicios necesarios y establecer medidas de alta disponibilidad y recuperación, cumpliendo con los requisitos del Proyecto 2 de ITI-522.

## Arquitectura desplegada

La solución se despliega utilizando los siguientes servicios de Azure:

| Componente | Servicio Azure | Propósito |
|------------|----------------|-----------|
| Grupo de Recursos | `tiendacomputo-rg` | Contenedor lógico para todos los recursos |
| Base de Datos | Máquina Virtual Ubuntu 22.04 (B2s) con PostgreSQL 15 | Motor de base de datos auto-administrado (restricción legal) |
| API REST | Azure App Service (plan B1, Linux, Node.js 18) | Alojamiento de la API Node.js/Express |
| Frontend | Azure Static Web Apps (o App Service opcional) | Alojamiento de la interfaz HTML/CSS/JS |
| Almacenamiento de Respaldos | Azure Blob Storage (estándar, LRS) | Contenedor `db-backups` para dumps lógicos comprimidos |
| Seguridad | Grupo de Seguridad de Red (NSG) | Reglas de entrada/salida para VM y App Service |
| Monitoreo | Azure Monitor (logs y métricas básicas) | Visibilidad de salud y rendimiento |

## Paso a paso del despliegue

### Prerrequisitos
1. Suscripción a Azure con permisos para crear recursos.
2. Azure CLI instalado y autenticado (`az login`).
3. Git instalado.
4. (Opcional) Para el backend: Node.js y npm para probar localmente.
5. (Opcional) Para el frontend: un servidor estático sencillo (como `serve`) para pruebas.

### Fase 1: Preparar el grupo de recursos
```bash
az group create --name tiendacomputo-rg --location eastus
```
*Se puede cambiar el nombre y la región según preferencia.*

### Fase 2: Desplegar la Base de Datos en una VM
La base de datos requiere una VM bajo administración total del grupo. Siga estos pasos:

1. **Crear la VM**
```bash
az vm create   --resource-group tiendacomputo-rg   --name bd-inventario-vm   --image UbuntuLTS   --size B2s   --admin-username azureuser   --generate-ssh-keys
```
2. **Anotar la IP pública** que se muestra en la salida (o obtenerla después con `az vm list-ip-addresses`).

3. **Conectarse por SSH y ejecutar los scripts de instalación y hardening**
   ```bash
   ssh azureuser@<IP_PUBLICA>
   # Dentro de la VM:
   wget https://raw.githubusercontent.com/<tu-repo>/iti522_proyecto2/main/scripts/install_db.sh
   wget https://raw.githubusercontent.com/<tu-repo>/iti522_proyecto2/main/scripts/harden_vm.sh
   chmod +x install_db.sh harden_vm.sh
   sudo ./install_db.sh
   sudo ./harden_vm.sh
   ```
   *Los scripts crean la base de datos `inventario_db`, usuario `app_user`, y configuran seguridad básica.*

4. **Configurar la regla de NSG para permitir conexiones desde el App Service**
   - Opcional: crear un NSG específico y asociarlo a la subnet de la VM.
   - Para simplificar en esta fase, se puede permitir el puerto 5432 desde cualquier IP (no recomendado para producción).
   - En producción, restringir a la IP del App Service o usar una VNet con peering.

### Fase 3: Desplegar el Backend (API) en Azure App Service
Ejecutar el script de despliegue proporcionado:
```bash
# Variables de entorno (ejemplar, reemplazar con valores reales)
export RESOURCE_GROUP=tiendacomputo-rg
export APP_SERVICE_NAME=tiendacomputo-api
export LOCATION=eastus
export SKU=B1
export DB_HOST=<IP_DE_LA_VM>
export DB_PORT=5432
export DB_NAME=inventario_db
export DB_USER=app_user
export DB_PASS=<CONTRASEÑA_SEGURA>
export PUERTO=5000
# Opcional: si el frontend está en un dominio distinto, establecer FRONTEND_URL
export FRONTEND_URL=https://<nombre-de-tu-frontend>.azurestaticapps.net

./scripts/deploy_backend.sh
```
El script:
- Crea el grupo de recursos (si no existe).
- Crea un plan de App Service (Linux, B1).
- Crea la aplicación web con runtime Node.js 18.
- Configura despliegue local Git y empuja el código desde `app/backend`.
- Configura las variables de entorno de conexión a la BD y otras.
- Habilita logs de aplicación.

**Verificación:**
```bash
curl https://<APP_SERVICE_NAME>.azurewebsites.net/health
# Debe devolver: {"estado":"OK","timestamp":"..."}
```

### Fase 4: Desplegar el Frontend
Opción A: Azure Static Web Apps (recomendado para sitios estáticos)
```bash
export RESOURCE_GROUP=tiendacomputo-rg
export STATIC_APP_NAME=tiendacomputo-frontend
export LOCATION=eastus
export APP_LOCATION=app/frontend
# Opcional: si se conoce la URL del backend, se puede pasar para documentación
export API_URL=https://tiendacomputo-api.azurewebsites.net

./scripts/deploy_frontend.sh
```
El script crea la Static Web App y despliega la carpeta `app/frontend`.

**URL resultante:** `https://<STATIC_APP_NAME>.azurestaticapps.net`

Opción B: Desplegar el frontend en el mismo App Service que el backend (alternativa)
Si se prefiere tener todo en un mismo servicio, se puede:
1. Modificar el backend para servir archivos estáticos (añadir en `server.js`):
   ```javascript
   const path = require('path');
   app.use(express.static(path.join(__dirname, '..', 'frontend')));
   ```
2. Asegurarse de que las rutas de la API (`/api/*`) no conflicten con las rutas estáticas.
3. Desplegar toda la carpeta del proyecto (o al menos `app/backend` y `app/frontend`) como una sola aplicación.

### Fase 5: Configurar almacenamiento de respaldos y backup automatizado
1. **Crear cuenta de almacenamiento**
```bash
az storage account create   --name tiendacomputostorage   --resource-group tiendacomputo-rg   --location eastus   --sku Standard_LRS
```
2. **Obtener las credenciales (para usar en los scripts)**
```bash
# Obtener la clave de la cuenta
STORAGE_KEY=$(az storage account keys list   --resource-group tiendacomputo-rg   --account-name tiendacomputostorage   --query "[0].value" -o tsv)

# O crear un SAS token con permisos de escritura en un contenedor
az storage container create   --name db-backups   --account-name tiendacomputostorage   --account-key $STORAGE_KEY   --output none

# Generar un SAS token válido por, por ejemplo, 30 días
EXPIRY=$(date -u -d "30 days" '+%Y-%m-%dT%H:%M:%SZ')
SAS_TOKEN=$(az storage account generate-sas   --account-name tiendacomputostorage   --account-key $STORAGE_KEY   --expiry $EXPIRY   --permissions acrwlu   --services b   --resource-types sco   --output tsv)
```

3. **Configurar el script de backup en la VM**
   Copie el script `scripts/backup_db.sh` a la VM y configúlelo con las variables de entorno:
   ```bash
   export DB_HOST=<IP_DE_LA_VM>
   export DB_NAME=inventario_db
   export DB_USER=app_user
   export DB_PASS=<CONTRASEÑA_SEGURA>
   export BLOB_ACCOUNT_NAME=tiendacomputostorage
   export BLOB_CONTAINER_NAME=db-backups
   export BLOB_SAS_TOKEN=<EL_SAS_TOKEN_OBTENIDO>
   # O usar AZURE_STORAGE_KEY en su lugar
   export AZURE_STORAGE_KEY=$STORAGE_KEY
   ```
   Luego probar manualmente:
   ```bash
   ./scripts/backup_db.sh
   ```
   Verificar que el archivo aparezca en el contenedor `db-backups` de la cuenta de almacenamiento.

4. **Automatizar con cron**
   Editar el crontab:
   ```bash
   sudo crontab -e
   ```
   Añadir:
   ```
   0 2 * * * /home/azureuser/iti522_proyecto2/scripts/backup_db.sh >> /var/log/db_backup.log 2>&1
   ```
   (Ajustar la ruta según el usuario y la ubicación del script.)

### Fase 6: Probar la restauración (RTO/RPO)
Para cumplir con el entregable de disponibilidad e integridad, es necesario demostrar un backup y restore exitoso.

1. **Simular un incidente** (opcional, para pruebas):
   - Detener el servicio de PostgreSQL: `sudo systemctl stop postgresql`
   - O eliminar la base de datos: `sudo -u postgres psql -c "DROP DATABASE inventario_db;"` (luego recrearla vacía).

2. **Obtener el nombre del último backup** desde Blob Storage:
   ```bash
   az storage blob list      --container-name db-backups      --account-name tiendacomputostorage      --account-key $STORAGE_KEY      --output tsv
   ```
   Tomar el nombre más reciente (ej: `inventario_db_backup_20260817_023000.sql.gz`).

3. **Ejecutar el script de restauración** en la VM:
   ```bash
   export DB_HOST=<IP_DE_LA_VM>
   export DB_NAME=inventario_db
   export DB_USER=app_user
   export DB_PASS=<CONTRASEÑA_SEGURA>
   export BLOB_ACCOUNT_NAME=tiendacomputostorage
   export BLOB_CONTAINER_NAME=db-backups
   export BLOB_SAS_TOKEN=<EL_SAS_TOKEN>
   export BACKUP_FILE_NAME=inventario_db_backup_20260817_023000.sql.gz

   ./scripts/restore_db.sh
   ```
4. **Verificar que la aplicación funcione**:
   - Esperar a que el script termine.
   - Probar la API: `curl https://<APP_SERVICE_NAME>.azurewebsites.net/api/articulos`
   - Debería devolver los datos restaurados.

5. **Documentar el tiempo**:
   - Anotar hora de inicio y fin del restore.
   - Calcular RTO = (hora fin - hora inicio).
   - Verificar que el RPO (tiempo desde el último backup hasta el incidente) sea menor a 24 horas (por backup diario).

### Consideraciones de Alta Disponibilidad
Aunque la solución no implementa alta disponibilidad completa (como clústeres de PostgreSQL o múltiples instancias de App Service en zonas), se han tomado las siguientes medidas para mejorar la resiliencia:

- **App Service**: El plan B1 permite escalado manual y reinicio automático ante fallos de nodo subyacente.
- **Blob Storage**: Almacenamiento LRS ofrece durabilidad alta dentro de una región.
- **Backup Automatizado**: Reduce el RPO a un máximo de 24 horas.
- **Procedimiento de Restauración Documentado**: Permite recuperar el servicio en un tiempo predecible (RTO).
- **NSG y Hardening Básico**: Reduce la superficie de ataque y la probabilidad de compromiso.
- **Logs y Monitoreo**: Habilitados para detección temprana de problemas.

Para mejorar aún más la disponibilidad en un entorno de producción, se podría considerar:
- Usar Azure SQL Database en modo sin servidor o con réplicas geográficas (si la restricción legal lo permitiera).
- Implementar App Service en modo escalado automático (plan estándar o superior).
- Usar Azure Zone Redundant Storage (ZRS) o Geo-Redundant Storage (GRS) para los backups.
- Implementar un segundo nodo de PostgreSQL en espera (standby) o usar réplicas de lectura.
- Usar Azure Front Door o Application Gateway para balanceo de carga y conmutación por error.
- Implementar health checks y automatizar el escalado o reinicio basado en métricas.

## Evidencias requeridas para la entrega
Para cumplir con los criterios de evaluación, el grupo debe proporcionar:

1. **URL de la aplicación desplegada y funcionando** (frontend y backend).
2. **Historial de commits** en el repositorio que muestre trabajo sostenido.
3. **Documento técnico** que incluya:
   - Arquitectura revisada (diagrama y tabla de cambios).
   - Justificación de servicios.
   - Procedimiento de instalación y configuración de la BD.
   - Plan de recuperación con RTO/RPO y evidencia de restore.
4. **Carpeta de evidencias** con:
   - Capturas de la arquitectura desplegada en el portal de Azure.
   - Capturas de la aplicación funcionando en un dispositivo móvil (o emulator).
   - Capturas del proceso de backup y restore (terminales, logs, Blob Storage).
   - Capturas de la API respondiendo (ej: `/health` y `/api/articulos`).
5. **Defensa técnica oral** donde todos los integrantes expliquen su parte.

## Conclusión
Siguiendo este plan, el grupo podrá desplegar una solución completa en la nube que cumple con:
- La restricción legal de mantener el control administrativo del motor de base de datos.
- Los requisitos de funcionalidad (CRUD de inventario, acceso móvil mediante diseño responsivo).
- Los requisitos de disponibilidad e integridad (backup automático, restore demostrable, plan de recuperación).
- Los entregables académicos (documento, URL, repositorio, evidencias, defensa).

El énfasis en la documentación y la prueba de restauración asegura que el grupo no solo despliegue, sino que también comprenda y pueda operar la solución en un entorno real.
