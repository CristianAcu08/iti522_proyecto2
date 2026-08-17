# Análisis de la restricción legal sobre la base de datos

## Contexto
El departamento legal determina que el contrato de licenciamiento vigente del motor de base de datos solo es válido si la empresa conserva el control administrativo del motor. Un servicio de base de datos gestionado por el proveedor obligaría a re-licenciar, con un costo no aprobado.

## Implicaciones técnicas
- La base de datos **debe ejecutarse sobre una máquina virtual** bajo administración directa del grupo (o la empresa simulada).
- El grupo asume la responsabilidad de:
  - Instalación del motor de BD
  - Configuración de seguridad (parches, firewall, acceso)
  - Tuning de rendimiento básico
  - Respaldos y restauración
  - Monitorión de salud

## Motores evaluados (compatibles con licencia típica)
| Motor | Licencia | Comentario |
|-------|----------|------------|
| PostgreSQL | Licencia de código abierto (PostgreSQL License) | Muy permisiva, compatible con uso comercial sin costo de licenciamiento. Requiere administración pero es estable y con buena documentación. |
| MySQL Community Edition | GPLv2 | Licencia GPL requiere que obras derivadas también sean GPL si se distribuyen, pero el uso interno como servicio suele estar permitido. Verificar con legal. |
| MariaDB | GPLv2 | Similar a MySQL. |
| Microsoft SQL Server Express | Licencia gratuita con limitaciones | Ideal si ya hay acuerdo con Microsoft, pero tiene límites de tamaño y características que podrían no ser suficientes. |

## Decisión
Se seleccionará **PostgreSQL 15** por las siguientes razones:
- Licencia totalmente permisiva para uso comercial y modificaciones.
- Fuerte soporte de la comunidad y documentación excelente.
- Buen rendimiento y características avanzadas (JSONB, réplicas, etc.).
- Fácil de instalar y administrar en Linux (Ubuntu).
- No implica costos de licenciamiento adicionales.
