# Lecciones aprendidas del Proyecto 1

## Qué funcionó bien
- Propuesta de arquitectura clara y basada en servicios gestionados.
- Buen trabajo de investigación de requisitos del negocio.
- Uso de diagramas y documentación estructurada.

## Qué mejorar
- La arquitectura propuesta dependía fuertemente de servicios gestionados (PaaS/SaaS) que podrían entrar en conflicto con restricciones de licenciamiento.
- Falta de consideración de restricciones legales o contractuales desde el inicio.
- Necesidad de diseñar para operabilidad y no solo para viabilidad técnica.
- Importancia de incluir planes de disponibilidad y recuperación desde la propuesta inicial.

## Decisiones para el Proyecto 2
- Mantener: Enfoque en obtener requisitos claros del negocio y validar con el cliente.
- Cambiar: Arquitectura para adaptarse a restricciones legales (BD en VM administrada por el grupo).
- Eliminar: Dependencia exclusiva de servicios de base de datos gestionados sin evaluar alternativas.
