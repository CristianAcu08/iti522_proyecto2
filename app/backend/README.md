# API de Inventario - Backend

Esta es la API RESTful desarrollada en Node.js con Express y PostgreSQL para el Proyecto 2 de ITI-522.

## Características
- Endpoints CRUD para gestión de artículos (`/api/articulos`)
- Conexión a base de datos PostgreSQL usando `pg`
- Middleware CORS habilitado
- Manejo básico de errores
- Variables de entorno mediante `.env`

## Requisitos
- Node.js (v16 o superior recomendado)
- PostgreSQL (accesible mediante las variables de entorno)
- npm o yarn

## Instalación y ejecución local

1. Clonar el repositorio y navegar a esta carpeta
2. Copiar `.env.example` a `.env` y configurar las variables de entorno:
   ```bash
   cp .env.example .env
   # Editar .env con los valores reales de su base de datos
   ```
3. Instalar dependencias:
   ```bash
   npm install
   ```
4. Iniciar el servidor:
   ```bash
   npm start
   # Para desarrollo con recarga automática:
   # npm run dev
   ```
5. La API estará disponible en `http://localhost:5000`

## Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/articulos` | Obtener lista de todos los artículos |
| GET | `/api/articulos/:id` | Obtener un artículo específico por ID |
| POST | `/api/articulos` | Crear un nuevo artículo |
| PUT | `/api/articulos/:id` | Actualizar un artículo existente |
| DELETE | `/api/articulos/:id` | Eliminar un artículo |

## Despliegue en Azure App Service

1. Asegurarse de que el repositorio tenga esta carpeta (`app/backend`) como raíz o configurar el percorso de despliegue adecuado.
2. En el portal de Azure App Service:
   - Configurar la pila de tecnología en "Node.js 18 LTS" (o la versión disponible más reciente)
   - En Configuración > Configuración general, establecer el comando de arranque si es necesario (por defecto `npm start` funciona si hay un `package.json`)
   - En Configuración > Aplicaciones, agregar las variables de entorno:
     - `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`
     - `PUERTO` (opcional, por defecto 5000)
     - `FRONTEND_URL` (opcional, para restringir CORS al dominio del frontend)
3. Habilitar el despliegue continuo desde el repositorio (GitHub Actions, Azure Pipelines, o despliegue local de Git).
4. Después del despliegue, la API estará disponible en `https://<nombre-de-tu-app>.azurewebsites.net`

## Notas de Seguridad
- Nunca confirmar el archivo `.env` con credenciales reales en un repositorio público.
- En producción, considerar:
  - Usar Azure Key Vault para almacenar secretos
  - Habilitar HTTPS (por defecto en App Service)
  - Restringir CORS solo al dominio del frontend
  - Implementar autenticación y autorización (JWT, OAuth, etc.) si el negocio lo requiere
  - Usar grupos de seguridad de red y puntos de servicio privados para aislar la comunicación entre App Service y la VM de la base de datos