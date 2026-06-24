const express = require('express');
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Helper function to read configuration from mounted volumes
function readConfig(filePath, defaultValue) {
  try {
    if (fs.existsSync(filePath)) {
      const value = fs.readFileSync(filePath, 'utf8').trim();
      console.log(`Loaded config from ${filePath}: ${filePath.includes('password') ? '***' : value}`);
      return value;
    }
  } catch (error) {
    console.warn(`Failed to read ${filePath}, using default or env variable:`, error.message);
  }
  return defaultValue;
}

// Read database configuration from mounted volumes
const DB_HOST = readConfig('/etc/config/DB_HOST', process.env.DB_HOST);
const DB_PORT = readConfig('/etc/config/DB_PORT', process.env.DB_PORT);
const DB_NAME = readConfig('/etc/config/DB_NAME', process.env.DB_NAME);
const DB_USER = readConfig('/etc/secrets/DB_USER', process.env.DB_USER);
const DB_PASSWORD = readConfig('/etc/secrets/DB_PASSWORD', process.env.DB_PASSWORD);

// Database connection pool configuration
const pool = new Pool({
  host: DB_HOST,
  port: parseInt(DB_PORT),
  database: DB_NAME,
  user: DB_USER,
  password: DB_PASSWORD,
  max: 20,                      
  idleTimeoutMillis: 30000,    
  connectionTimeoutMillis: 2000,
});

// Middleware
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'service-api',
    timestamp: new Date().toISOString()
  });
});

// Database health check endpoint
app.get('/health/db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.status(200).json({
      status: 'healthy',
      database: 'connected',
      timestamp: result.rows[0].now
    });
  } catch (error) {
    console.error('Database health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Get all employees
app.get('/api/employees', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM employees ORDER BY id ASC'
    );
    
    res.status(200).json({
      success: true,
      count: result.rows.length,
      data: result.rows,
      version: 'v2'
    });
  } catch (error) {
    console.error('Error fetching employees:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch employees',
      message: error.message
    });
  }
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: err.message
  });
});

process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing HTTP server');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT signal received: closing HTTP server');
  await pool.end();
  process.exit(0);
});

app.listen(PORT, () => {
  console.log(`Service API is running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Database Host: ${DB_HOST}`);
  console.log(`Configuration loaded from volume mounts`);
});

// Test database connection on startup
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Failed to connect to database:', err);
  } else {
    console.log('Successfully connected to database at:', res.rows[0].now);
  }
});
