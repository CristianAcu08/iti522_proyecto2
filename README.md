# ITI-522: Proyecto 2 - Implementación y Operación de una Solución en la Nube

Sistema de Gestión de Inventario para Empresa de Logística. Despliegue en arquitectura híbrida en Microsoft Azure con Frontend en Static Web Apps, Backend en App Service y Base de Datos PostgreSQL administrada sobre Máquina Virtual IaaS.

---

## 🌐 URLs y Recursos en Producción

- **Frontend (Web/Mobile):** `https://thankful-beach-0672df110.7.azurestaticapps.net/`
- **Backend API:** `https://tiendacomputo-api.azurewebsites.net/api/articulos`
- **Health Check:** `https://tiendacomputo-api.azurewebsites.net/health`
- **Almacenamiento de Backups:** Azure Blob Storage (`tiendacomputostorage` / contenedor: `db-backups`)

---

## 🏗️ Arquitectura de la Solución

1. **Frontend (PaaS / SWA):**
   - HTML5, CSS3 moderno (diseño Glassmorphism responsivo para dispositivos móviles y transportistas) y JavaScript vanilla.
   - Alojado en **Azure Static Web Apps**.
2. **Backend (PaaS):**
   - API REST en **Node.js / Express**.
   - Alojado en **Azure App Service** (Linux).
   - CRUD completo sobre `/api/articulos`.
3. **Base de Datos (IaaS - Restricción Legal):**
   - **PostgreSQL 14+** instalado, configurado y administrado manualmente sobre una Máquina Virtual Ubuntu Linux en Azure.
   - En cumplimiento estricto con las condiciones contractuales y de licenciamiento del cliente.
4. **Almacenamiento y Respaldo:**
   - **Azure Blob Storage** para almacenamiento externo de respaldos lógicos (`pg_dump` comprimidos en `.sql.gz`).

---

## 📁 Estructura del Repositorio

```text
iti522_proyecto2/
├── app/
│   ├── frontend/          # Código del frontend (HTML, CSS, JS)
│   └── backend/           # API REST Node.js/Express
├── docs/                  # Documentación técnica, justificaciones y planes
│   ├── integridad_y_recuperacion.md
│   └── despliegue_alta_disponibilidad.md
├── evidencias/            # Capturas para la entrega final
│   ├── app_movil/         # Pruebas de visualización en smartphones
│   ├── arquitectura/      # Diagrama de arquitectura
│   ├── despliegue/        # Evidencias de Azure y servicios arriba
│   └── restauracion/      # Logs y capturas de prueba de restore
├── infra/                 # Parámetros y definiciones de infraestructura
└── scripts/               # Automatización operativa
    ├── install_db.sh      # Instalación y configuración de PostgreSQL en la VM
    ├── init_db.sql        # Esquema inicial de tablas y permisos
    ├── backup_db.sh       # Respaldo automático diario a Azure Blob Storage
    ├── restore_db.sh      # Script de restauración de contingencia
    ├── deploy_frontend.sh # Despliegue de SWA
    └── deploy_backend.sh  # Despliegue de App Service
```

---

## ⚙️ Automatización Operativa y DRP

### 1. Respaldo Automático (Backup)
Configurado vía `cron` en la VM de base de datos diariamente a las **02:00 AM**:
```bash
0 2 * * * /home/unti/iti522_proyecto2/scripts/backup_db.sh
```

### 2. Recuperación ante Desastres (DRP)
- **RPO (Recovery Point Objective):** 24 horas.
- **RTO (Recovery Time Objective):** 45 minutos.
- **Procedimiento de Restauración:**
  ```bash
  export BACKUP_FILE_NAME="manual_inventario_db_backup.sql.gz"
  sudo -E /home/unti/iti522_proyecto2/scripts/restore_db.sh
  ```

---

## 👥 Integrantes y Roles
- Estudiantes del curso ITI-522 - Computación en la Nube (UTN).
