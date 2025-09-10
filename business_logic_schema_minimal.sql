-- RV Truck Fleet Management - Minimal Business Logic Schema
-- This script creates tables one by one to avoid dependency issues
-- Run this step by step if needed

-- Step 1: Drop everything first
DROP TABLE IF EXISTS silak_calculations CASCADE;
DROP TABLE IF EXISTS odometer_photos CASCADE;
DROP TABLE IF EXISTS advances CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS diesel_entries CASCADE;
DROP TABLE IF EXISTS trips CASCADE;
DROP TABLE IF EXISTS brokers CASCADE;

-- Step 2: Create brokers table (no dependencies)
CREATE TABLE brokers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    company TEXT,
    contact_number TEXT,
    email TEXT,
    address TEXT,
    commission_rate DECIMAL(5,2) DEFAULT 0.00,
    status TEXT CHECK (status IN ('active', 'inactive')) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create trips table (depends on brokers)
CREATE TABLE trips (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lr_number TEXT UNIQUE NOT NULL,
    vehicle_id UUID NOT NULL, -- Will reference vehicles table
    driver_id UUID NOT NULL,  -- Will reference drivers table
    broker_id UUID REFERENCES brokers(id) ON DELETE SET NULL,
    assigned_by UUID, -- Will reference user_profiles table
    from_location TEXT NOT NULL,
    to_location TEXT NOT NULL,
    distance_km DECIMAL(10,2),
    tonnage DECIMAL(10,2),
    rate_per_ton DECIMAL(10,2),
    total_rate DECIMAL(10,2),
    commission_amount DECIMAL(10,2) DEFAULT 0.00,
    advance_given DECIMAL(10,2) DEFAULT 0.00,
    diesel_issued DECIMAL(10,2) DEFAULT 0.00,
    silak_amount DECIMAL(10,2) DEFAULT 0.00,
    status TEXT CHECK (status IN ('assigned', 'in_progress', 'completed', 'settled', 'cancelled')) DEFAULT 'assigned',
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create other tables
CREATE TABLE diesel_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL,
    entry_type TEXT CHECK (entry_type IN ('credit_pump', 'random_pump', 'diesel_card')) NOT NULL,
    pump_partner_id UUID,
    quantity_liters DECIMAL(10,2) NOT NULL,
    rate_per_liter DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    pump_location TEXT,
    pump_name TEXT,
    odometer_reading DECIMAL(10,2),
    entry_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    entered_by UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    vehicle_id UUID,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    receipt_url TEXT,
    expense_date DATE NOT NULL,
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    entered_by UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE odometer_photos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL,
    photo_type TEXT CHECK (photo_type IN ('start', 'end')) NOT NULL,
    photo_url TEXT NOT NULL,
    odometer_reading DECIMAL(10,2) NOT NULL,
    location TEXT,
    uploaded_by UUID,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_by UUID,
    verified_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE advances (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    driver_id UUID NOT NULL,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    amount DECIMAL(10,2) NOT NULL,
    advance_type TEXT CHECK (advance_type IN ('trip_advance', 'general_advance', 'emergency')) DEFAULT 'trip_advance',
    purpose TEXT,
    given_by UUID,
    given_date DATE NOT NULL,
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE silak_calculations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL,
    calculation_type TEXT CHECK (calculation_type IN ('per_km', 'per_liter')) NOT NULL,
    rate DECIMAL(10,2) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    calculated_amount DECIMAL(10,2) NOT NULL,
    advance_deducted DECIMAL(10,2) DEFAULT 0.00,
    diesel_deducted DECIMAL(10,2) DEFAULT 0.00,
    net_amount DECIMAL(10,2) NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    calculated_by UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Insert sample data
INSERT INTO brokers (name, company, contact_number, email, commission_rate) VALUES
('Rajesh Kumar', 'RK Logistics', '+91-9876543210', 'rajesh@rklogistics.com', 5.00),
('Priya Sharma', 'PS Transport', '+91-9876543211', 'priya@pstransport.com', 4.50),
('Amit Singh', 'AS Freight', '+91-9876543212', 'amit@asfreight.com', 6.00)
ON CONFLICT DO NOTHING;

-- Step 6: Enable RLS
ALTER TABLE brokers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE diesel_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE odometer_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE silak_calculations ENABLE ROW LEVEL SECURITY;

-- Step 7: Create basic RLS policies
CREATE POLICY "Allow all authenticated users to view brokers" ON brokers
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all authenticated users to view trips" ON trips
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all authenticated users to view diesel entries" ON diesel_entries
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all authenticated users to view expenses" ON expenses
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all authenticated users to view odometer photos" ON odometer_photos
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all authenticated users to view advances" ON advances
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all authenticated users to view silak calculations" ON silak_calculations
    FOR SELECT USING (auth.role() = 'authenticated');

-- Success message
SELECT 'Minimal business logic schema created successfully!' as message;
