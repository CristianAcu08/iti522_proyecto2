# Arquitectura Revisada (Versión 2)

A continuación se describe la arquitectura propuesta para el Proyecto 2, cumpliendo con las restricciones y nuevos requisitos.

## Diagrama de Arquitectura (Mermaid)

```mermaid
graph TD
    subgraph Azure[Azure Cloud]
        subgroup RG[Grupo de Recursos: tiendacomputo-rg]
            direction TB
            subgraph AppService[Servicio de Aplicación]
                WebApp[Aplicación Web: Inventario]:::webservice
            end
            subgraph VMDB[Máquina Virtual: Base de Datos]
                direction TB
                VM[Ubuntu VM: bd-inventario-vm]:::vm
                subgraph BD[Base de Datos]
                    PostgreSQL[PostgreSQL 15]:::db
                end
            end
            subgraph Storage[Almacenamiento]
                BlobStorage[(Blob Storage: backups)]:::storage
            end
            subgraph Monitoring[Monitoreo y Seguridad]
                NSG[Grupo de Seguridad de Red]:::network
                AzureBackup[Azure Backup]:::backup
            end
        end
    end

    subgraph Usuarios[Usuarios]
        direction TB
        Admin[Administrador]:::user
        Empleados[Empleados (Transportistas, Gerencia)]:::user
        Clientes[Clientes (Consulta pública)]:::user
    end

    %% Conexiones
    Usuario -->|HTTPS (443)| WebApp
    WebApp -->|Conexión segura (PostgreSQL)| BD
    VM -->|HTTPS/SSH| Admin
    WebApp -->|Lectura/Escritura de blobs| BlobStorage
    AzureBackup -->|Configura y ejecuta| BlobStorage
    NSG -->|Protege| VM
    NSG -->|Protege| WebApp

    classDef webservice fill:#0066cc,color:#fff,stroke:#004c99,stroke-width:2px;
    classDef vm fill:#009900,color:#fff,stroke:#006600,stroke-width:2px;
    classDef db fill:#ff6600,color:#fff,stroke:#cc5200,stroke-width:2px;
    classDef storage fill:#6600cc,color:#fff,stroke:#4c0099,stroke-width:2px;
    classDef network fill:#cc0000,color:#fff,stroke:#990000,stroke-width:2px;
    classDef backup fill:#006699,color:#fff,stroke:#004c66,stroke-width:2px;
    classDef user fill:#666666,color:#fff,stroke:#333333,stroke-width:1px;
```

## Componentes y Responsabilidades

| Componente | Servicio/Azure | Responsabilidad del Grupo |
|------------|----------------|---------------------------|
| Grupo de Recursos | `tiendacomputo-rg` | Crear y gestionar recursos dentro de este grupo |
| Aplicación Web | Azure App Service (plan B1) | Desplegar código, configurar variables de entorno, escalado básico |
| Máquina Virtual | Ubuntu LTS B2s | Instalar PostgreSQL, configurar seguridad, administrar accesos |
| Base de Datos | PostgreSQL 15 (en VM) | Instalación, creación de usuario/DB, tuning básico, monitoring |
| Almacenamiento de Respaldos | Azure Blob Storage (tipo estándar, LRS) | Configurar contenedor, scripts de subida, políticas de retención |
| Grupo de Seguridad de Red | Azure NSG | Definir reglas de entrada/salida para VM y App Service |
| Azure Backup | Servicio nativo (opcional) o scripts propios | Configurar backup de discos (opcional) o usar scripts para lógicos |

## Justificación de Selección de Servicios

- **Azure App Service**: Ofrece equilibrio entre control y facilidad de despliegue. Permite publicar desde repositorio, escalado automático básico y gestión de certificados TLS. Es suficiente para una aplicación web de inventario con carga moderada.
- **Máquina Virtual para BD**: Cumple estrictamente con la restricción legal de mantener el control administrativo del motor. Aunque implica más trabajo operativo, es la única opción viable bajo las condiciones dadas.
- **Azure Blob Storage**: Servicio de objetos altamente duradero y económico para almacenar respaldos lógicos. Soporta versionamiento y políticas de ciclo de vida.
- **NSG y Azure Backup**: Capacidades nativas de Azure para mejorar la postura de seguridad y disponibilidad sin costo adicional significativo o complejidad excesiva.

## Acceso Móvil
La aplicación web será diseñada con principios de diseño responsivo (CSS media queries, unidades fluidas) para ser usable en navegadores de teléfonos inteligentes y tablets. No se requiere una PWA o aplicación nativa según las especificaciones.
