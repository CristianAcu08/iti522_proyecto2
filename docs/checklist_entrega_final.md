# Checklist de Entrega Final - Proyecto 2 ITI-522

Use este checklist para verificar que todos los requisitos y entregables estén completos antes de la defensa técnica.

## ✅ Entregables Obligatorios

### 1. Documento Técnico (PDF)
- [ ] Título claro: "Proyecto 2: Implementación y Operación de una Solución en la Nube - ITI-522"
- [ ] Nombre del grupo y miembros
- [ ] Sección 4.1: Arquitectura Revisada
    - [ ] Diagrama de arquitectura actualizado (legible, con todos los componentes)
    - [ ] Tabla de cambios respecto al Proyecto 1 (elemento, decisión, justificación técnica)
    - [ ] Justificación de la selección de servicios (en función de disponibilidad y operación)
- [ ] Sección 4.2: Implementación del Sistema de Inventario
    - [ ] Descripción de la aplicación web funcional (endpoints, tecnologías usadas)
    - [ ] Evidencia de que la base de datos está instalada y administrada por el grupo sobre una VM
    - [ ] Procedimiento de instalación y configuración aplicada (detallado, reproducible)
    - [ ] Acceso desde dispositivos móviles: descripción del diseño responsivo o PWA
    - [ ] Enlace al repositorio de código (público o accesible con credenciales)
- [ ] Sección 4.3: Disponibilidad e Integridad de la Información
    - [ ] Estrategia de respaldo automatizada de la base de datos hacia almacenamiento de objetos
    - [ ] Prueba de restauración documentada (evidencia de que un backup fue restaurado y el sistema volvió a operar)
    - [ ] Plan de recuperación ante desastres con RTO y RPO declarados y justificados según el impacto en el negocio
    - [ ] Descripción de los mecanismos que protegen la integridad de los datos en tránsito y en reposo
- [ ] Formato: PDF, bien estructurado, sin errores de ortografía o formato excesivo.

### 2. URL de la Aplicación Desplegada y Funcionando
- [ ] La aplicación web está accesible mediante una URL pública (ej: .azurewebsites.net o .azurestaticapps.net)
- [ ] El frontend se carga correctamente y muestra la lista de productos (o mensaje de vacío si no hay datos).
- [ ] Las operaciones CRUD funcionan:
    - [ ] Puede crear un nuevo producto.
    - [ ] Puede editar un producto existente.
    - [ ] Puede eliminar un producto.
    - [ ] Los cambios se persisten en la base de datos.
- [ ] La aplicación es utilizable desde un teléfono inteligente (prueba real o en emulator de dispositivo).
    - [ ] Se ve correctamente en pantalla pequeña.
    - [ ] Los botones y formularios son fáciles de usar.
- [ ] Nota: La URL debe estar funcionando **al momento de la defensa**. Tener un plan de redoble (ej: reiniciar App Service si falla).

### 3. Repositorio de Código
- [ ] Historial de commits que evidencie el trabajo de todos los integrantes (al menos 2-3 commits por miembro en las últimas semanas).
- [ ] Estructura clara: `/docs`, `/app/backend`, `/app/frontend`, `/scripts`, `/evidencias`.
- [ ] No hay credenciales reales en el repositorio (usar .env.example o similares).
- [ ] README principal que explique el proyecto y cómo ejecutarlo localmente.

### 4. Carpeta de Evidencias
Organizar en `/evidencias` o similar:
- [ ] `/evidencias/arquitectura`
    - [ ] Diagrama de arquitectura (PNG, SVG, o PDF)
    - [ ] Tabla de cambios (opcional, si no está en el documento)
- [ ] `/evidencias/app_movil`
    - [ ] Capturas de pantalla de la aplicación funcionando en un dispositivo móvil real o emulator (al menos 2-3 vistas: lista, formulario, modal).
    - [ ] Opcional: video corto de uso.
- [ ] `/evidencias/restauracion`
    - [ ] Captura del proceso de backup (ej: ejecutando `scripts/backup_db.sh` o mostrando el log).
    - [ ] Captura del Blob Storage mostrando el archivo de backup.
    - [ ] Captura del proceso de restore (ej: ejecutando `scripts/restore_db.sh`).
    - [ ] Captura de la base de datos después del restore (ej: `SELECT COUNT(*) FROM articulos;`).
    - [ ] Captura de la aplicación funcionando con los datos restaurados.
    - [ ] Documento que indique:
        - Hora de inicio de la restauración
        - Hora de finalización
        - RTO calculado
        - Comentario sobre si cumplió con el objetivo (<30 minutos)
- [ ] `/evidencias/despliegue`
    - [ ] Capturas del portal de Azure mostrando los recursos creados (Grupo de Recursos, App Service, VM, Static Web App o Storage).
    - [ ] Capturas de la URL de la API responding to `/health`.
    - [ ] Capturas de la URL del frontend cargando.

### 5. Defensa Técnica Oral
- [ ] Todos los integrantes pueden explicar cualquier parte del sistema.
- [ ] Preparación:
    - [ ] Arquitecto: explica el diagrama, las decisiones de arquitectura y la justificación de servicios.
    - [ ] DevOps: explica la infraestructura (VM, App Service, Storage, NSG), los scripts de instalación, backup y restore, y cómo se aseguró la disponibilidad.
    - [ ] Backend: explica la API, los endpoints, la conexión a la base de datos, y el manejo de errores.
    - [ ] Frontend: explica el diseño responsivo, el consumo de la API, los modales, y la interacción de usuario.
    - [ ] QA/Documentación: explica el proceso de documentación, cómo se elaboró el evidencias, y el plan de recuperación.
- [ ] Cronometrado: intervención de 2-3 minutos por miembro, total menos de 10 minutos.
- [ ] Respuestas claras y técnicas a las preguntas del docente.

### 6. Condiciones Críticas (¡No pasar por alto!)
- [ ] **La aplicación debe estar en funcionamiento al momento de la defensa.** Un despliegue caído se evalúa como no entregado.
- [ ] **La prueba de restauración es obligatoria.** Sin evidencia de restore, el criterio de disponibilidad e integridad se califica en cero.
- [ ] **Presupuesto controlado:** No se ha excedido el presupuesto disponible (usar Azure for Students o capa gratuita). Si se perdió el entorno por exceso, no es justificación válida.

## ✅ Preparación Adicional (Recomendado)

### Antes de la defensa
- [ ] Probar la URL de la aplicación 1 hora antes de la defensa para asegurarse de que está funcionando.
- [ ] Tener a mano una copia de respaldo del documento técnico y las evidencias en caso de problemas de conexión.
- [ ] Ensayar la defensa técnica con el grupo al menos una vez.
- [ ] Preparar respuestas a posibles preguntas difíciles:
    - "¿Qué harían si el RTO de 30 minutos no fuera suficiente para el negocio?"
    - "¿Cómo reducirían el RPO a menos de 4 horas sin aumentar demasiado el costo?"
    - "¿Qué pasaría si la VM de la base de datos se pierde por completo? ¿Cómo recuperarían el disco?"
    - "¿Por qué eligieron esta configuración en lugar de una completamente gestionada?"
    - "¿Cómo garantizan que los backups no se corrupten o se pierden?"

### Último minuto
- [ ] Laptop cargada y con adaptador de red si es necesario.
- [ ] Navegador abierto con la URL de la aplicación lista para mostrar.
- [ ] Documento técnico impreso o en dispositivo para referencia rápida.
- [ ] Notas personales para cada miembro.

## ✅ Estado Actual (Llenar durante el proyecto)

| Ítem | Estado (✅/❌/⚠️) | Comentarios / Próximos pasos |
|------|-------------------|------------------------------|
| Documento Técnico |  |  |
| URL Funcionando |  |  |
| Repositorio con Commits |  |  |
| Evidencias de Arquitectura |  |  |
| Evidencias de App Móvil |  |  |
| Evidencias de Restauración |  |  |
| Evidencias de Despliegue |  |  |
| Defensa Técnica Preparada |  |  |
| Condición Crítica: App Funcionando |  |  |
| Condición Crítica: Prueba de Restauración |  |  |
| Presupuesto Controlado |  |  |

---
*Marque cada casilla a medida que avanzan. Antes de la defensa, asegúrese de que todas las casillas críticas estén en ✅.*
