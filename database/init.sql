-- Translation Platform Database Initialization Script
-- This script creates the complete database schema and sample data

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUMS
-- ============================================================================

-- User roles enum
CREATE TYPE userrole AS ENUM (
    'AGENT',
    'SUPERVISOR',
    'ADMIN',
    'TRANSLATOR',
    'EMPLOYEE',
    'COMPANY_ADMIN'
);

-- Call status enum (legacy call center feature)
CREATE TYPE callstatus AS ENUM (
    'WAITING',
    'RINGING',
    'ACTIVE',
    'ENDED',
    'MISSED'
);

-- Booking status enum
CREATE TYPE bookingstatus AS ENUM (
    'PENDING',
    'CONFIRMED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED'
);

-- Language enum (optional - currently using VARCHAR)
CREATE TYPE language AS ENUM (
    'SPANISH',
    'FRENCH',
    'GERMAN'
);

-- ============================================================================
-- TABLES
-- ============================================================================

-- Companies table
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR NOT NULL,
    contact_email VARCHAR UNIQUE NOT NULL,
    contact_phone VARCHAR,
    address TEXT
);

-- Users table (supports translators, employees, admins, and legacy roles)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR UNIQUE NOT NULL,
    name VARCHAR NOT NULL,
    hashed_password VARCHAR NOT NULL,
    role userrole NOT NULL DEFAULT 'EMPLOYEE',

    -- Translator-specific fields
    languages VARCHAR[],
    is_available BOOLEAN DEFAULT TRUE,
    hourly_rate VARCHAR,

    -- Employee-specific fields
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL
);

-- Bookings table (translation sessions)
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    translator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    duration_minutes INTEGER NOT NULL,
    language VARCHAR NOT NULL,
    status bookingstatus NOT NULL DEFAULT 'PENDING',
    jitsi_room_name VARCHAR,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Calls table (legacy call center feature)
CREATE TABLE calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_name VARCHAR UNIQUE NOT NULL,
    customer_name VARCHAR,
    customer_phone VARCHAR,
    agent_id UUID REFERENCES users(id),
    status callstatus NOT NULL DEFAULT 'WAITING',
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Queue table (legacy call center feature)
CREATE TABLE queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id UUID NOT NULL REFERENCES calls(id),
    position INTEGER NOT NULL,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Translator languages junction table (optional, currently using array)
CREATE TABLE translator_languages (
    translator_id UUID REFERENCES users(id),
    language language
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- User indexes
CREATE UNIQUE INDEX ix_users_email ON users(email);
CREATE INDEX idx_users_company ON users(company_id);

-- Booking indexes for better query performance
CREATE INDEX idx_bookings_translator ON bookings(translator_id);
CREATE INDEX idx_bookings_employee ON bookings(employee_id);
CREATE INDEX idx_bookings_company ON bookings(company_id);
CREATE INDEX idx_bookings_start_time ON bookings(start_time);

-- ============================================================================
-- SAMPLE DATA
-- ============================================================================

-- Insert default admin user
-- Password for all users: 'password123'
-- Hash: $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5QK9hF.y8kqge

INSERT INTO users (id, email, name, hashed_password, role) VALUES
    (uuid_generate_v4(), 'admin@example.com', 'Admin', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5QK9hF.y8kqge', 'ADMIN'),
    (uuid_generate_v4(), 'agent1@example.com', 'Agent One', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5QK9hF.y8kqge', 'AGENT'),
    (uuid_generate_v4(), 'agent2@example.com', 'Agent Two', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5QK9hF.y8kqge', 'AGENT'),
    (uuid_generate_v4(), 'supervisor@example.com', 'Supervisor', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5QK9hF.y8kqge', 'SUPERVISOR');

-- ============================================================================
-- USER REGISTRATION
-- ============================================================================

-- Translators can self-register via the web interface:
-- URL: http://localhost:3000/register/translator
--
-- The registration form collects:
-- - Email
-- - Full Name
-- - Password
-- - Languages (Spanish, French, German - can select multiple)
-- - Hourly Rate (optional)
--
-- After registration, translators can:
-- 1. Login with their email and password
-- 2. View their bookings on the calendar
-- 3. Update their availability status
-- 4. Update their profile (languages, hourly rate)
--
-- API Endpoint:
-- POST /translators/register
-- Body: {
--   "email": "translator@example.com",
--   "name": "Translator Name",
--   "password": "secure_password",
--   "languages": ["SPANISH", "FRENCH"],
--   "hourly_rate": "$50/hour"
-- }

-- ============================================================================
-- NOTES
-- ============================================================================

-- To seed the database with complete test data (companies, translators, employees):
-- Run: docker exec callcenter-backend python seed_data.py
--
-- This will add:
-- - 5 companies with employees
-- - 8 translators with various languages
-- - 19+ employees across all companies
--
-- For more information, see docs/TEST_ACCOUNTS.md
--
-- REGISTRATION OPTIONS:
-- - Translators: Self-service registration at /register/translator
-- - Employees: Must be registered by company admin
-- - Companies: Contact system administrator
