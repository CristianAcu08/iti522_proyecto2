# Justificación de la Selección de Servicios

## Resumen
La selección de servicios para el Proyecto 2 se basa en cumplir rigurosamente con los requisitos académicos, las restricciones legales y contractuales, y los nuevos escenarios de negocio, optimizando por operabilidad, costo y claridad en la demostración de conceptos de computación en la nube.

## Detalle por Componente

### 1. Máquina Virtual para Base de Datos
- **Servicio elegido**: Azure Virtual Machine (Ubuntu LTS 22.04) con tamaño B2s
- **Justificación**:
  - **Restricción Legal**: Es la única forma de garantizar el control administrativo del motor de base de datos, tal como lo exige el departamento legal.
  - **Control Total**: Permite al grupo instalar, configurar, parchear y administrar el motor de base de datos según las mejores prácticas y los requisitos del curso.
  - **Costo Adecuado**: El tamaño B2s es económico para fines académicos y de prueba, encajando dentro de los créditos de Azure for Students.
  - **Aprendizaje**: Instalar y administrar una base de datos en una VM cubre directamente los contenidos de la Unidad VI (desarrollo de aplicaciones en la nube) y VII (disponibilidad e integridad) al responsabilizarse del grupo de tareas operativas como backup y recuperación.

### 2. Servicio de Aplicación Web
- **Servicio elegido**: Azure App Service (plan B1: Basic)
- **Justificación**:
  - **Equilibrio Control/Facilidad**: Aunque se podría usar otra VM, App Service reduce la carga operativa en la capa web, permitiendo al grupo enfocarse en la restricción crítica (la BD). 
  - **Despliegue Sencillo**: Integración directa con repositorios Git (GitHub/Azure DevOps) facilita la entrega continua y el historial de commits requerido.
  - **Escalabilidad Básica**: El plan B1 permite escalado manual y métricas de rendimiento suficientes para demostrar el concepto.
  - **Seguridad por Defecto**: Incluye gestión de certificados TLS, restricciones de IP y integración con Azure Active Directory (opcional).
  - **Costo**: Muy bajo dentro del plan gratuito o básico de Azure for Students.

### 3. Almacenamiento de Objetos para Respaldos
- **Servicio elegido**: Azure Blob Storage (estándar, LRS)
- **Justificación**:
  - **Durabilidad y Disponibilidad**: Ofrece 99.9% de disponibilidad anual y replicación local suficiente para fines académicos.
  - **Costo Óptimo**: Es uno de los servicios más económicos de Azure, ideal para almacenar backups lógicos que se escreben raramente y se leen aún menos (solo en caso de restore).
  - **Facilidad de Integración**: Se puede acceder mediante SDK, REST o herramientas como AzCopy, simplificando los scripts de backup.
  - **Cumplimiento de Requisitos**: Permite demostrar una estrategia de respaldo automatizada hacia almacenamiento de objetos, tal como se pide en la sección 4.3.

### 4. Grupo de Seguridad de Red (NSG)
- **Servicio elegido**: Azure Network Security Group
- **Justificación**:
  - **Aislamiento y Control**: Permite definir reglas precisas de tráfico hacia la VM (solo SSH y PostgreSQL desde la App Service o IPs de administración) y hacia la App Service (solo HTTP/HTTPS).
  - **Gratuito**: No hay costo adicional por usar NSG, solo por los recursos que protege.
  - **Relevante para el Curso**: Refuerza conceptos de seguridad de red y defensa en profundidad, alineados con la integridad de la información (Unidad VII).

### 5. Mecanismo de Respaldos Lógicos
- **Enfoque**: Scripts personalizados (no servicio gestionado de backup de Azure para BD)
- **Justificación**:
  - **Restricción de Gestión**: Al no poder usar un servicio de BD gestionado, tampoco esperaríamos que el grupo use un servicio de backup gestionado para la BD (sería inconsistente con el espíritu de asumir la responsabilidad operativa).
  - **Aprendizaje Práctico**: Escribir y programar scripts de `pg_dump`, compresión, subida a Blob Storage y limpieza enseña directamente sobre automatización, manejo de errores y responsabilidad operativa.
  - **Demostrable**: Es trivial producir evidencia de un backup y su restore, lo cual es un entregable clave.
