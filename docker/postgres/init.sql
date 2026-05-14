-- =============================================================================
-- ElektraLog — PostgreSQL Initialization Script
-- Creates both the main elektralog DB and the wikijs DB
-- =============================================================================

-- Create Wiki.js database (if it doesn't exist yet)
-- Note: POSTGRES_DB is already created by the official postgres image.
-- We only need to create the secondary wikijs database here.

SELECT 'CREATE DATABASE wikijs'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'wikijs'
)\gexec

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE wikijs TO elektralog;

-- Run schema migrations
\i /docker-entrypoint-initdb.d/001_initial.sql
\i /docker-entrypoint-initdb.d/002_seed_permissions.sql
