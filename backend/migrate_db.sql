-- Add new columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS languages VARCHAR[] DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS hourly_rate VARCHAR DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS company_id UUID DEFAULT NULL;

-- Create companies table
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY,
    name VARCHAR NOT NULL,
    contact_email VARCHAR UNIQUE NOT NULL,
    contact_phone VARCHAR,
    address TEXT
);

-- Add foreign key for company_id
ALTER TABLE users ADD CONSTRAINT fk_users_company 
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL;

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY,
    translator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    duration_minutes INTEGER NOT NULL,
    language VARCHAR NOT NULL,
    status VARCHAR NOT NULL DEFAULT 'PENDING',
    jitsi_room_name VARCHAR,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_bookings_translator ON bookings(translator_id);
CREATE INDEX IF NOT EXISTS idx_bookings_employee ON bookings(employee_id);
CREATE INDEX IF NOT EXISTS idx_bookings_company ON bookings(company_id);
CREATE INDEX IF NOT EXISTS idx_bookings_start_time ON bookings(start_time);
CREATE INDEX IF NOT EXISTS idx_users_company ON users(company_id);

