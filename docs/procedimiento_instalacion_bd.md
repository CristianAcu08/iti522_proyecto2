# Procedimiento de Instalación y Configuración de la Base de Datos

Este documento detalla los pasos seguidos para instalar, configurar y asegurar el motor de base de datos PostgreSQL 15 en una máquina virtual Ubuntu 22.04 en Azure, cumpliendo con la restricción legal de mantener el control administrativo del motor.

## Requisitos previos
- Suscripción a Azure con acceso para crear máquinas virtuales
- Máquina virtual Ubuntu LTS 22.04 (recomendado tamaño B2s para fines académicos)
- Acceso SSH a la VM con privilegios de sudo
- (Opcional) Azure CLI o AzCopy instalado localmente para gestionar recursos de storage

## Paso 1: Aprovisionar la Máquina Virtual en Azure
1. En el portal de Azure, crear una nueva máquina virtual.
2. Imagen: Ubuntu Server 22.04 LTS
3. Tamaño: B2s (1 vCPU, 2 GiB RAM) - adecuado para desarrollo y pruebas
4. Grupo de recursos: crear uno nuevo (ej: `tiendacomputo-rg`)
5. Nombre de la VM: `bd-inventario-vm`
6. Región: elegir la más cercana a los usuarios esperados
7. Autenticación: usar clave SSH (recomendado) o contraseña segura
8. Redes:
   - Grupo de seguridad de red (NSG): crear uno nuevo o usar existente
   - Puertos de entrada permitidos inicialmente: SSH (22), se añadirán PostgreSQL (5432) después de configurar
9. Discos: dejar el predeterminado (SSD estándar)
10. Revisar y crear.

Una vez creada, anotar:
- Dirección IP pública de la VM
- Nombre de usuario SSH
- Método de autenticación

## Paso 2: Conexión inicial y actualización del sistema
Desde una terminal local, conectarse por SSH:
```bash
ssh <usuario>@<ip_publica>
```
Luego ejecutar:
```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y
sudo apt-get autoclean -y
```

## Paso 3: Instalación de PostgreSQL 15
Ejecutar el script de instalación proporcionado:
```bash
wget https://raw.githubusercontent.com/<tu-repo>/iti522_proyecto2/main/scripts/install_db.sh
# O copiar el script directamente
chmod +x install_db.sh
sudo ./install_db.sh
```

El script realiza:
- Actualización de listas de paquetes
- Instalación de `postgresql` y `postgresql-contrib`
- Configuración de `postgresql.conf` para escuchar en todas las interfaces (`listen_addresses = '*'`)
- Configuración de `pg_hba.conf` para permitir conexiones desde cualquier IP usando autenticación md5 (NOTA: en producción, restringir a rangos de IP específicos y considerar scram-sha-256 o SSL)
- Creación de la base de datos `inventario_db`
- Creación del usuario `app_user` con contraseña temporal
- Concesión de todos los privilegios sobre la base de datos al usuario
- Creación de una tabla de ejemplo `articulos`

## Paso 4: Endurecimiento de seguridad básico
Ejecutar el script de hardening:
```bash
wget https://raw.githubusercontent.com/<tu-repo>/iti522_proyecto2/main/scripts/harden_vm.sh
chmod +x harden_vm.sh
sudo ./harden_vm.sh
```

El script realiza:
- Actualización completa del sistema
- Instalación y configuración de UFW (firewall):
  - Política predeterminada: denegar entrada, permitir salida
  - Puertos abiertos: 22 (SSH), 5432 (PostgreSQL)
- Instalación y configuración de `fail2ban` para proteger SSH
- Deshabilitación del login root vía SSH
- Actualización del mensaje del día (motd) con advertencia de monitoreo

## Paso 5: Prueba de conexión desde otra máquina
Desde una máquina local o desde el entorno donde se desplegará la aplicación, probar la conexión:
```bash
# Instalar cliente de PostgreSQL si no está presente
# En Ubuntu/Debian: sudo apt-get install postgresql-client
# En macOS: brew install libpq
# En Windows: usar el instalador de PostgreSQL y usar psql.exe

psql -h <IP_DE_LA_VM> -p 5432 -U app_user -d inventario_db
```
Se solicitará la contraseña establecida durante la instalación (por defecto en el script: `AppPassw0rd!`).
Si la conexión es exitosa, se mostrará el prompt de `psql`.

## Paso 6: Configuración de variables de entorno para la aplicación
La aplicación web deberá acceder a la base de datos mediante las siguientes variables de entorno:
- `DB_HOST`: IP pública o privada de la VM (dependiendo de la topología de red)
- `DB_PORT`: `5432`
- `DB_NAME`: `inventario_db`
- `DB_USER`: `app_user`
- `DB_PASS`: la contraseña establecida (se recomienda cambiarla después de la primera entrada y almacenarla en un gestor de secretos como Azure Key Vault)

## Paso 7: Configuración de respaldos automatizados
Se implementó un script de backup lógico que sube los dumps comprimidos a Azure Blob Storage.

### Requisitos para el backup
- Una cuenta de almacenamiento de Azure (tipo estándar, LRS es suficiente)
- Un contenedor de blobs dentro de dicha cuenta (ej: `db-backups`)
- Autenticación mediante SAS token o clave de cuenta
- `azcopy` o Azure CLI instalado en la VM

### Ejecución manual (para pruebas)
```bash
export DB_HOST=<ip_de_la_vm>
export DB_NAME=inventario_db
export DB_USER=app_user
export DB_PASS=<tu_contraseña_segura>
export BLOB_ACCOUNT_NAME=<nombre_de_tu_cuenta>
export BLOB_CONTAINER_NAME=db-backups
export BLOB_SAS_TOKEN=<tu_sas_token_aqui>  # o usar AZURE_STORAGE_KEY
./scripts/backup_db.sh
```

### Automatización con cron
Editar el crontab de root:
```bash
sudo crontab -e
```
Añadir línea para ejecutar el backup diario a las 2:00 AM:
```
0 2 * * * /home/<usuario>/iti522_proyecto2/scripts/backup_db.sh >> /var/log/db_backup.log 2>&1
```
Asegurarse de que las variables de entorno estén disponibles en el contexto de cron (puede ser necesario sourcear un archivo o definirlas directamente en la línea).

## Paso 8: Procedimiento de restauración (para pruebas de recuperación)
Para demostrar la capacidad de restauración, seguir estos pasos:

1. Identificar el archivo de backup a restaurar en Blob Storage (por nombre o fecha).
2. Establecer las variables de entorno necesarias:
   ```bash
   export DB_HOST=<ip_de_la_vm>
   export DB_NAME=inventario_db
   export DB_USER=app_user
   export DB_PASS=<tu_contraseña_segura>
   export BLOB_ACCOUNT_NAME=<nombre_de_tu_cuenta>
   export BLOB_CONTAINER_NAME=db-backups
   export BLOB_SAS_TOKEN=<tu_sas_token_aqui>  # o AZURE_STORAGE_KEY
   export BACKUP_FILE_NAME=inventario_db_backup_20260817_023000.sql.gz  # ejemplo
   ```
3. Ejecutar el script de restauración:
   ```bash
   ./scripts/restore_db.sh
   ```
4. El script:
   - Descargará el backup desde Blob Storage
   - Lo descomprimirá
   - Eliminará y recreará la base de datos `inventario_db`
   - Restaurará el dump
   - Ejecutará `VACUUM ANALYZE`
   - Limpiará archivos temporales

5. Verificar la restauración:
   - Conectarse a la base de datos y comprobar que los datos estén presentes
   - Ejecutar consultas de muestra
   - Notar el tiempo de inicio a fin del proceso para calcular el RTO (Recovery Time Objective)

## Consideraciones de producción
Aunque este procedimiento es adecuado para un entorno académico, en producción se debería considerar:

### Seguridad
- Restringir `pg_hba.conf` a rangos de IP específicos (por ejemplo, solo la subnet de la App Service o una VNet con peering)
- Usar autenticación basada en certificados SSL o scram-sha-256 en lugar de md5
- Habilitar el cifrado de trasiego (SSL) para las conexiones a la base de datos
- Implementar rotación regular de contraseñas y uso de Azure Key Vault para almacenar secretos
- Deshabilitar el acceso público a la VM y usar únicamente IP privada o Azure Bastion para administración
- Aplicar parches de seguridad del sistema operativo y de PostgreSQL de forma regular

### Alta disponibilidad y recuperación de desastres
- Implementar un servidor en espera (standby) o replicación lógica si el presupuesto lo permite
- Probar periódicamente el procedimiento de restauración (al menos mensualmente)
- Definir y documentar RTO y RPO basado en pruebas reales y necesidades del negocio
- Considerar usar Azure Site Recovery o similares para replicar la VM completa

### Monitoreo
- Instalar y configurar agentes de monitoreo (ej: Azure Monitor para VMs, o herramientas como Prometheus + Grafana)
- Monitorear uso de CPU, memoria, I/O de disco y conexiones a la base de datos
- Configurar alertas para umbrales críticos (ej: CPU > 80% por 5 minutos, espacio de disco < 15%)

### Escalabilidad
- Aunque la VM puede escalarse verticalmente (cambiando el tamaño), considerar particionamiento o escalado horizontal si la carga crece significativamente
- Evaluar el uso de lecturas replicadas si la carga de lectura es alta

## Conclusión
Este procedimiento permite cumplir con la restricción legal de mantener el control administrativo del motor de base de datos mientras se demuestra competencia en:
- Instalación y configuración de un servicio crítico en la nube
- Aplicación de buenas prácticas de seguridad básica
- Implementación de estrategias de respaldo y restauración
- Documentación rigurosa de los procesos operativos

Los scripts y configuraciones proporcionados son un punto de partida que debe ser revisado, probado y adaptado según los requisitos específicos de seguridad y rendimiento del entorno de producción.
