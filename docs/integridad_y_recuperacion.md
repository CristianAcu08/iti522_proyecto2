# Documentación Técnica: Disponibilidad, Integridad y Recuperación ante Desastres
## Proyecto 2 - ITI-522 Computación en la Nube

### 1. Plan de Recuperación ante Desastres (DRP)

Para garantizar la continuidad del negocio de la empresa de logística, se han definido los siguientes objetivos de recuperación basados en la arquitectura implementada:

*   **RPO (Recovery Point Objective): 24 Horas.**
    *   **Justificación:** Dado que el mecanismo de respaldo automático está configurado para ejecutarse diariamente a las 02:00 AM, el punto máximo de pérdida de datos tolerable es de un día de transacciones. Para este modelo de negocio, un RPO de 24 horas es un equilibrio aceptable entre costo operativo y riesgo.
*   **RTO (Recovery Time Objective): 45 Minutos.**
    *   **Justificación:** El tiempo estimado para detectar una falla, descargar el último respaldo comprimido desde Azure Blob Storage a la VM y ejecutar el script de restauración (`restore_db.sh`) es de aproximadamente 30 a 45 minutos. Esto permite que el sistema vuelva a estar operativo rápidamente tras un desastre en la base de datos.

### 2. Estrategia de Respaldo y Disponibilidad
*   **Automatización:** Se utiliza una tarea programada (Cron) en la VM que ejecuta el script `backup_db.sh` todas las madrugadas.
*   **Almacenamiento de Objetos:** Los respaldos se exportan fuera del servidor local hacia un Azure Storage Account (`tiendacomputostorage`), asegurando que, si la VM falla o se destruye, los datos permanezcan seguros en un sistema de alta durabilidad.
*   **Seguimiento:** El script genera logs locales en `/tmp` y verifica la integridad del archivo `.sql.gz` antes de subirlo.

### 3. Integridad de los Datos
*   **En Tránsito:**
    *   La comunicación entre el Frontend (SWA) y el Backend (App Service) se realiza exclusivamente bajo el protocolo **HTTPS (TLS 1.2+)**, cifrando los datos entre el cliente y el servidor.
    *   La conexión entre el Backend y la VM de base de datos viaja protegida por las reglas de red de Azure y, de ser necesario, túneles seguros.
*   **En Reposo:**
    *   **Azure Blob Storage:** Los archivos de respaldo se cifran automáticamente mediante *Azure Storage Service Encryption* (AES-256) al ser almacenados en la nube.
    *   **Disco de la VM:** Se recomienda el uso de discos administrados con cifrado SSE para proteger la base de datos activa.

### 4. Justificación de la Arquitectura (Decisión Legal)
En cumplimiento con la restricción legal sobre el licenciamiento, el motor PostgreSQL se administra directamente sobre una VM Linux. Aunque esto aumenta la carga operativa (mantenimiento de parches, seguridad y respaldos manuales), garantiza que la empresa conserve el control administrativo total del motor, evitando sobrecostos de re-licenciamiento en modelos PaaS.
