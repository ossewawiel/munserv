-- V001__initial_schema.sql
-- Description: Initial schema setup - enables PostGIS extension
-- Author: Claude
-- Date: 2026-01-05

-- Enable PostGIS extension (required for spatial queries)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Placeholder comment: Full schema will be added in Phase 1
-- This migration ensures Flyway baseline works correctly
