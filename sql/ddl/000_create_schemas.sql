-- =====================================================
-- Project : Ecommerce Data Engineering Pipeline
-- File    : 001_create_schemas.sql
-- Author  : Felipe Sepúlveda
-- Purpose : Create schemas for the Medallion Architecture
-- =====================================================

CREATE SCHEMA IF NOT EXISTS bronze;

CREATE SCHEMA IF NOT EXISTS silver;

CREATE SCHEMA IF NOT EXISTS gold;

CREATE SCHEMA IF NOT EXISTS monitoring;