const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: '*'
}));
app.use(express.json());

// Configuración de PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
});

// Probar conexión al iniciar
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Error al conectar a la base de datos:', err.stack);
  } else {
    console.log('Conexión a PostgreSQL exitosa:', res.rows[0]);
  }
});

// Rutas API - Articulos
// GET /api/articulos - Listar todos los artículos
app.get('/api/articulos', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, name, description, price, stock FROM articulos ORDER BY id');
    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener artículos:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// GET /api/articulos/:id - Obtener un artículo por ID
app.get('/api/articulos/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT id, name, description, price, stock FROM articulos WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Artículo no encontrado' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener artículo:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Normaliza el cuerpo del request
function normalizarArticulo(body) {
  return {
    nombre: body.nombre || body.name || 'Sin nombre',
    descripcion: body.descripcion || body.description || '',
    precio: body.precio !== undefined ? body.precio : (body.price || 0),
    stock: body.stock !== undefined ? body.stock : 0
  };
}

// POST /api/articulos - Crear un nuevo artículo
app.post('/api/articulos', async (req, res) => {
  try {
    const { nombre, descripcion, precio, stock } = normalizarArticulo(req.body);
    
    const result = await pool.query(
      'INSERT INTO articulos (name, description, price, stock) VALUES ($1, $2, $3, $4) RETURNING id, name, description, price, stock',
      [nombre, descripcion, precio, stock]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error al crear artículo:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Restore endpoint
app.post('/api/restore', async (req, res) => {
  try {
    const { exec } = require('child_process');
    // Usamos az vm run-command que ya probamos y funciona
    const cmd = "az vm run-command invoke --resource-group SERVER1 --name server1 --command-id RunShellScript --scripts \"LATEST=$(ls -t /opt/db_backups/*.sql | head -1); PGPASSWORD='12345678' psql -U app_user -h localhost -d inventario_db -f $LATEST\"";
    
    exec(cmd, (err, stdout, stderr) => {
      if (err) return res.status(500).json({ error: 'Fallo al restaurar', detalles: stderr });
      res.json({ message: 'Restauración exitosa vía CLI' });
    });
  } catch (err) { 
    res.status(500).json({ error: 'Error interno', detalles: err.message }); 
  }
});

// DELETE /api/articulos/:id - Eliminar un artículo
app.delete('/api/articulos/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM articulos WHERE id = $1 RETURNING id, name, description, price, stock', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Artículo no encontrado' });
    }
    
    res.json({ mensaje: 'Artículo eliminado correctamente', articuloEliminado: result.rows[0] });
  } catch (error) {
    console.error('Error al eliminar artículo:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Ruta de salud
app.get('/health', (req, res) => {
  res.json({ estado: 'OK', timestamp: new Date().toISOString() });
});

// Manejo de rutas no encontradas
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor API ejecutándose en puerto ${PORT}`);
});