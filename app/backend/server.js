const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors({
  origin: process.env.FRONTEND_URL || '*', // En producción, especificar el dominio del frontend
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type']
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
    const result = await pool.query('SELECT * FROM articulos ORDER BY id');
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
    const result = await pool.query('SELECT * FROM articulos WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Artículo no encontrado' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener artículo:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// POST /api/articulos - Crear un nuevo artículo
app.post('/api/articulos', async (req, res) => {
  try {
    const { nombre, descripcion, precio, stock } = req.body;
    
    // Validación básica
    if (!nombre || precio === undefined || stock === undefined) {
      return res.status(400).json({ error: 'Nombre, precio y stock son requeridos' });
    }
    
    const result = await pool.query(
      'INSERT INTO articulos (nombre, descripcion, precio, stock) VALUES ($1, $2, $3, $4) RETURNING *',
      [nombre, descripcion || null, precio, stock]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error al crear artículo:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// PUT /api/articulos/:id - Actualizar un artículo existente
app.put('/api/articulos/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, descripcion, precio, stock } = req.body;
    
    // Validación básica
    if (!nombre || precio === undefined || stock === undefined) {
      return res.status(400).json({ error: 'Nombre, precio y stock son requeridos' });
    }
    
    const result = await pool.query(
      'UPDATE articulos SET nombre = $1, descripcion = $2, precio = $3, stock = $4 WHERE id = $5 RETURNING *',
      [nombre, descripcion || null, precio, stock, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Artículo no encontrado' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al actualizar artículo:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// DELETE /api/articulos/:id - Eliminar un artículo
app.delete('/api/articulos/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM articulos WHERE id = $1 RETURNING *', [id]);
    
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