# Plan de Recuperación ante Desastres (DR) y Gestión de la Continuidad

Este documento describe el plan de recuperación para la base de datos del sistema de inventario, incluyendo los objetivos de tiempo de recuperación (RTO) y punto de recuperación (RPO), los procedimientos de backup y restore, y las consideraciones para minimizar el impacto de un desastre en el negocio.

## Objetivos de Recuperación

| Objetivo | Valor | Justificación |
|----------|-------|---------------|
| **RTO (Recovery Time Objective)** | < 30 minutos | Tiempo máximo tolerable para restaurar el servicio tras un desastre. Basado en el impacto económico de paradas prolongadas (pérdida de contratos según especificación del proyecto). Un RTO de 30 minutos permite recuperar el servicio dentro de la misma jornada laboral si el incidente ocurre por la mañana. |
| **RPO (Recovery Point Objective)** | < 24 horas | Cantidad máxima de datos que se pueden perder tras un incidente. Un RPO de 24 horas significa que se pueden perder hasta un día de transacciones. Este valor se justifica por la frecuencia de backup diario y la naturaleza del inventario (actualizaciones no son tan críticas como en sistemas financieros). En un entorno de producción real, se podría reducir a 4 horas con backups más frecuentes. |

## Estrategia de Respaldo

### Tipo de backup
- **Backup lógico**: se utilizan dumps SQL comprimidos (`pg_dump` + `gzip`) en lugar de backups físicos o snapshots, por portabilidad y facilidad de versionamiento.

### Frecuencia
- **Diario**: a las 02:00 AM (hora baja de actividad) mediante cron job.
- **Retención**: 7 días en Blob Storage (política de ciclo de vida opcional para eliminar automáticamente después de este período).

### Almacenamiento
- **Azure Blob Storage** (tipo estándar, LRS) en el contenedor `db-backups` de la cuenta de almacenamiento dedicada.
- Justificación: alta durabilidad (99.9% anual), bajo costo, acceso sencillo mediante API o herramientas como AzCopy.

### Seguridad de los backups
- Los backups se transfieren mediante conexión HTTPS (AzCopy usa TLS por defecto).
- El contenedor deBlob Storage puede configurarse con políticas de acceso privado y autenticación mediante SAS token con tiempo de vida limitado o clave de cuenta almacenada en Azure Key Vault (en producción).

## Procedimientos de Backup

### Backup manual
Ejecutar el script `scripts/backup_db.sh` con las variables de entorno adecuadas (ver documento de procedimiento).

### Backup automático (cron)
El cron job está configurado para ejecutarse diario a las 02:00 AM:
```cron
0 2 * * * /home/<usuario>/iti522_proyecto2/scripts/backup_db.sh >> /var/log/db_backup.log 2>&1
```
El script registra su salida en `/var/log/db_backup.log` para auditoría.

### Verificación de backups
Se recomienda verificar mensualmente que:
1. El archivo de backup exista en Blob Storage.
2. El tamaño del archivo sea razonable (no vacío).
3. Se pueda descargar y descomprimir sin errores.
(Opcional) intentar una restauración en un entorno de prueba.

## Procedimientos de Restauración

### Escenarios de restauración
1. **Recuperación por fallo lógico**: datos corruptos o eliminados por error humano (ej: sentencia `DROP TABLE` o `DELETE` sin `WHERE`).
2. **Recuperación por fallo de hardware**: disco dañado o VM inaccesible (requiere provisionar una nueva VM y restaurar el backup).
3. **Recuperación por desastre regional**: pérdida total del centro de datos de Azure (poco probable con LRS, pero se asume que se tendría una copia en otra región si se usa GRS o ZRS).

### Pasos de restauración (ver script `scripts/restore_db.sh`)
1. **Notificación y diagnóstico**: confirmar que se necesita una restauración y identificar el punto de restauración adecuado (último backup bueno).
2. **Preparación del entorno**:
   - Si se trata de fallo de hardware, provisionar una nueva VM con las mismas especificaciones.
   - Instalar el sistema operativo y las dependencias necesarias (opcional: usar imágenes customizadas).
   - Asegurar conectividad de red y acceso a Blob Storage.
3. **Ejecución de la restauración**:
   - Descargar el backup desde Blob Storage.
   - Descomprimir el archivo.
   - Eliminar la base de datos dañada (si existe) y crear una nueva.
   - Restaurar el dump SQL.
   - Ejecutar `VACUUM ANALYZE` para optimizar estadísticas.
4. **Validación**:
   - Conectar a la base de datos y realizar consultas de muestra.
   - Verificar integridad de datos (restricciones de clave foránea, unicidad, etc.).
   - Notificar a los stakeholders que el servicio está listo para reanudar operaciones.
5. **Reconexión de la aplicación**:
   - Actualizar las variables de entorno de la aplicación web si cambió la IP de la VM.
   - Reiniciar o volver a desplegar la aplicación web si es necesario.
   - Confirmar que la aplicación puede leer y escribir correctamente.

## Plan de Comunicación

| Rol | Responsabilidad | Medio de comunicación |
|-----|-----------------|----------------------|
| Líder del Grupo | Declarar el incidente, activar el plan de DR, comunicar estado a stakeholders | Correo electrónico, teléfono, mensajería instantánea |
| DevOps | Ejecutar procedimientos de restauración, verificar infraestructura | Llamada telefónica, sesión compartida de pantalla |
| Backend | Validar la base de datos restaurada, probar conexión desde la aplicación | Correo, mensajería instantánea |
| Frontend | Verificar que la aplicación web funcione correctamente con los datos restaurados | Correo, mensajería instantánea |
| QA/Documentación | Registrar tiempos de inicio y fin de cada fase, actualizar documentación post-incidente | Documento compartido |

## Pruebas del Plan de DR

Para asegurar la efectividad del plan, se deben realizar pruebas periódicas:

### Prueba de restauración trimestral
1. Anunciar la prueba con antelación (no afectar operaciones reales si se usa una copia).
2. Seleccionar un backup reciente.
3. Restaurar en un entorno de aislado (VM de prueba).
4. Validar que los datos estén íntegros y que la aplicación funcione.
5. Documentar:
   - Tiempo de inicio de la restauración
   - Tiempo de finalización
   - Problemas encontrados
   - Lecciones aprendidas
6. Archivos de evidencia: capturas de pantalla, logs, timestamps.

### Simulación de fallo
1. En un entorno de staging, simular un fallo al detener el servicio de PostgreSQL o corromper intencionalmente los datos.
2. Activar el plan de DR y medir el RTO real.
3. Comparar con el RTO objetivo (<30 minutos) y ajustar procedimientos si es necesario.

## Consideraciones para mejorar el RPO y RTO

### Para reducir el RPO (menos pérdida de datos)
- **Backups más frecuentes**: pasar de diario a cada 4 horas o incluso horario (con cargo adicional de almacenamiento y costo de operaciones).
- **Replicación lógica**: usar soluciones como pglogical o replicación incorporada de PostgreSQL para mantener una copia casi en tiempo real.
- **Archivado de WAL**: habilitar el archivado de registros de anticipo de escritura (WAL) y almacenarlos en Blob Storage para permitir recuperación punto-a-punto (PITR).

### Para reducir el RTO (recuperación más rápida)
- **Backups físicos o snapshots**: usar snapshots de disco gestionado de Azure (si se usa almacenamiento premium) para restaurar todo el disco en minutos.
- **VM preparada**: mantener una VM en estado "stopped" pero lista para arrancar, con el SO y dependencias preinstaladas.
- **Orquestación**: usar herramientas como Azure Automation o runbooks para ejecutar los pasos de restauración de forma automática o semi-automática.
- **Mejorar el rendimiento de red**: asegurar que la VM tenga suficiente ancho de banda para descargar backups grandes rápidamente (considerar tamaños de VM mayores o aceleradores de red).

## Evidencias requeridas para la entrega del proyecto

Para cumplir con el criterio de disponibilidad e integridad de la información, se debe proporcionar:

1. **Evidencia de backup automatizado**:
   - Captura de pantalla del contenedor `db-backups` en Azure Blob Storage mostrando al menos un archivo de backup con timestamp reciente.
   - Opcional: log del cron job mostrando ejecución exitosa.

2. **Evidencia de restauración demostrada**:
   - Captura de pantalla del proceso de restauración en curso (terminal ejecutando `scripts/restore_db.sh`).
   - Captura de pantalla de la base de datos después de la restauración mostrando datos (ej: `SELECT COUNT(*) FROM articulos;`).
   - Captura de pantalla de la aplicación web funcionando con los datos restaurados.
   - Documento que indique:
     - Hora de inicio de la restauración
     - Hora de finalización
     - RTO calculado (hora fin - hora inicio)
     - Comentario sobre si cumplió con el objetivo (<30 minutos)

3. **Plan de recuperación documentado**:
   - Este documento (`docs/plan_recuperacion.md`) debe estar incluido en la carpeta de evidencias o enlazado desde el documento técnico principal.

## Conclusión

El plan de recuperación descrito cumple con los requisitos académicos del Proyecto 2:
- Define claramente un RTO (<30 min) y RPO (<24h) justificados según el impacto en el negocio.
- Describe una estrategia de backup automatizada hacia almacenamiento de objetos (Azure Blob Storage).
- Proporciona un procedimiento de restauración demostrable y testeable.
- Incluye consideraciones para mejorar la recuperación en entornos de producción.
- Se alinea con los contenidos de la Unidad VII (disponibilidad de sistemas e integridad de la información) al responsabilizar al grupo de la implementación y prueba de mecanismos de recuperación.

Al implementar y probar este plan, el grupo demostrará no solo la capacidad de desplegar una solución en la nube, sino también de mantenerla operativa y recuperar el servicio ante incidentes, lo cual es esencial para la confianza del cliente y la continuidad del negocio.
