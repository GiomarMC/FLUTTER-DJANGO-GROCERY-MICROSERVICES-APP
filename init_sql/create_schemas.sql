-- Script para crear los schemas necesarios en la base de datos Neon
-- Ejecutar este script ANTES de correr las migraciones de Django

-- Crear schema para el servicio de usuarios
CREATE SCHEMA IF NOT EXISTS user_schema;

-- Crear schema para el servicio de productos
CREATE SCHEMA IF NOT EXISTS product_schema;

-- Crear schema para el servicio de listas
CREATE SCHEMA IF NOT EXISTS list_schema;

-- Verificar que los schemas se crearon correctamente
SELECT schema_name FROM information_schema.schemata 
WHERE schema_name IN ('user_schema', 'product_schema', 'list_schema');
