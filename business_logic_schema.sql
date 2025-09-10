-- RV Truck Fleet Management - Business Logic Database Schema
-- Phase 1: Additional tables for business operations
-- Run this in Supabase SQL Editor after the main setup
-- 
-- UPDATED: Added DROP statements and fixed trigger order
-- This script can be run multiple times safely

-- Drop existing tables if they exist (in reverse dependency order)
DROP TABLE IF EXISTS silak_calculations CASCADE;
DROP TABLE IF EXISTS odometer_photos CASCADE;
DROP TABLE IF EXISTS advances CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS diesel_entries CASCADE;
DROP TABLE IF EXISTS trips CASCADE;
DROP TABLE IF EXISTS brokers CASCADE;

-- Drop existing functions and triggers if they exist
DROP TRIGGER IF EXISTS set_trip_lr_number ON trips CASCADE;
DROP TRIGGER IF EXISTS update_trips_updated_at ON trips CASCADE;
DROP TRIGGER IF EXISTS update_brokers_updated_at ON brokers CASCADE;
DROP TRIGGER IF EXISTS update_diesel_entries_updated_at ON diesel_entries CASCADE;
DROP TRIGGER IF EXISTS update_expenses_updated_at ON expenses CASCADE;
DROP TRIGGER IF EXISTS update_advances_updated_at ON advances CASCADE;
DROP FUNCTION IF EXISTS set_lr_number() CASCADE;
DROP FUNCTION IF EXISTS generate_lr_number() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Create updated_at trigger function (needed for all tables)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create brokers table
CREATE TABLE IF NOT EXISTS brokers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    company TEXT,
    contact_number TEXT,
    email TEXT,
    address TEXT,
    commission_rate DECIMAL(5,2) DEFAULT 0.00, -- Commission percentage
    status TEXT CHECK (status IN ('active', 'inactive')) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trips table
CREATE TABLE IF NOT EXISTS trips (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lr_number TEXT UNIQUE NOT NULL, -- Loading Receipt number (auto-generated)
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
    broker_id UUID REFERENCES brokers(id) ON DELETE SET NULL,
    assigned_by UUID REFERENCES user_profiles(id), -- Traffic Manager who assigned
    from_location TEXT NOT NULL,
    to_location TEXT NOT NULL,
    distance_km DECIMAL(10,2),
    tonnage DECIMAL(10,2),
    rate_per_ton DECIMAL(10,2),
    total_rate DECIMAL(10,2), -- tonnage * rate_per_ton
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

-- Create diesel_entries table
CREATE TABLE IF NOT EXISTS diesel_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
    entry_type TEXT CHECK (entry_type IN ('credit_pump', 'random_pump', 'diesel_card')) NOT NULL,
    pump_partner_id UUID REFERENCES user_profiles(id), -- If credit pump
    quantity_liters DECIMAL(10,2) NOT NULL,
    rate_per_liter DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    pump_location TEXT,
    pump_name TEXT,
    odometer_reading DECIMAL(10,2),
    entry_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    entered_by UUID REFERENCES user_profiles(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL, -- NULL for general expenses
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL, -- NULL for general expenses
    category TEXT NOT NULL, -- 'trip_specific', 'general', 'maintenance', 'fuel', 'toll', etc.
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    receipt_url TEXT, -- Supabase Storage URL
    expense_date DATE NOT NULL,
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    approved_by UUID REFERENCES user_profiles(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    entered_by UUID REFERENCES user_profiles(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create odometer_photos table
CREATE TABLE IF NOT EXISTS odometer_photos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
    photo_type TEXT CHECK (photo_type IN ('start', 'end')) NOT NULL,
    photo_url TEXT NOT NULL, -- Supabase Storage URL
    odometer_reading DECIMAL(10,2) NOT NULL,
    location TEXT,
    uploaded_by UUID REFERENCES user_profiles(id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_by UUID REFERENCES user_profiles(id), -- Admin verification
    verified_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create advances table
CREATE TABLE IF NOT EXISTS advances (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL, -- NULL for general advances
    amount DECIMAL(10,2) NOT NULL,
    advance_type TEXT CHECK (advance_type IN ('trip_advance', 'general_advance', 'emergency')) DEFAULT 'trip_advance',
    purpose TEXT,
    given_by UUID REFERENCES user_profiles(id),
    given_date DATE NOT NULL,
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    approved_by UUID REFERENCES user_profiles(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create silak_calculations table
CREATE TABLE IF NOT EXISTS silak_calculations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
    calculation_type TEXT CHECK (calculation_type IN ('per_km', 'per_liter')) NOT NULL,
    rate DECIMAL(10,2) NOT NULL, -- Rate per km or per liter
    quantity DECIMAL(10,2) NOT NULL, -- Distance in km or diesel in liters
    calculated_amount DECIMAL(10,2) NOT NULL,
    advance_deducted DECIMAL(10,2) DEFAULT 0.00,
    diesel_deducted DECIMAL(10,2) DEFAULT 0.00,
    net_amount DECIMAL(10,2) NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    calculated_by UUID REFERENCES user_profiles(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_trips_vehicle_id ON trips(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_trips_driver_id ON trips(driver_id);
CREATE INDEX IF NOT EXISTS idx_trips_broker_id ON trips(broker_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_lr_number ON trips(lr_number);

CREATE INDEX IF NOT EXISTS idx_diesel_entries_trip_id ON diesel_entries(trip_id);
CREATE INDEX IF NOT EXISTS idx_diesel_entries_vehicle_id ON diesel_entries(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_diesel_entries_entry_type ON diesel_entries(entry_type);

CREATE INDEX IF NOT EXISTS idx_expenses_trip_id ON expenses(trip_id);
CREATE INDEX IF NOT EXISTS idx_expenses_vehicle_id ON expenses(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON expenses(status);

CREATE INDEX IF NOT EXISTS idx_odometer_photos_trip_id ON odometer_photos(trip_id);
CREATE INDEX IF NOT EXISTS idx_odometer_photos_vehicle_id ON odometer_photos(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_odometer_photos_photo_type ON odometer_photos(photo_type);

CREATE INDEX IF NOT EXISTS idx_advances_driver_id ON advances(driver_id);
CREATE INDEX IF NOT EXISTS idx_advances_trip_id ON advances(trip_id);
CREATE INDEX IF NOT EXISTS idx_advances_status ON advances(status);

CREATE INDEX IF NOT EXISTS idx_silak_calculations_trip_id ON silak_calculations(trip_id);
CREATE INDEX IF NOT EXISTS idx_silak_calculations_driver_id ON silak_calculations(driver_id);

-- updated_at trigger function already created above

-- Create triggers for updated_at
CREATE TRIGGER update_brokers_updated_at BEFORE UPDATE ON brokers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON trips FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_diesel_entries_updated_at BEFORE UPDATE ON diesel_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_advances_updated_at BEFORE UPDATE ON advances FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Functions and triggers will be created at the end after all tables exist

-- Enable RLS on all tables
ALTER TABLE brokers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE diesel_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE odometer_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE silak_calculations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for brokers
CREATE POLICY "Allow all authenticated users to view brokers" ON brokers
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow traffic managers and admins to manage brokers" ON brokers
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trafficManager')
        )
    );

-- Create RLS policies for trips
CREATE POLICY "Allow all authenticated users to view trips" ON trips
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow traffic managers and admins to manage trips" ON trips
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trafficManager')
        )
    );

-- Create RLS policies for diesel_entries
CREATE POLICY "Allow all authenticated users to view diesel entries" ON diesel_entries
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow traffic managers, accountants, and admins to manage diesel entries" ON diesel_entries
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trafficManager', 'accountant')
        )
    );

-- Create RLS policies for expenses
CREATE POLICY "Allow all authenticated users to view expenses" ON expenses
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow accountants and admins to manage expenses" ON expenses
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'accountant')
        )
    );

-- Create RLS policies for odometer_photos
CREATE POLICY "Allow all authenticated users to view odometer photos" ON odometer_photos
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow drivers to upload odometer photos" ON odometer_photos
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'driver'
        )
    );

CREATE POLICY "Allow admins to manage odometer photos" ON odometer_photos
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Create RLS policies for advances
CREATE POLICY "Allow all authenticated users to view advances" ON advances
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow accountants and admins to manage advances" ON advances
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'accountant')
        )
    );

-- Create RLS policies for silak_calculations
CREATE POLICY "Allow all authenticated users to view silak calculations" ON silak_calculations
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow traffic managers and admins to manage silak calculations" ON silak_calculations
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trafficManager')
        )
    );

-- Insert some sample data for testing
INSERT INTO brokers (name, company, contact_number, email, commission_rate) VALUES
('Rajesh Kumar', 'RK Logistics', '+91-9876543210', 'rajesh@rklogistics.com', 5.00),
('Priya Sharma', 'PS Transport', '+91-9876543211', 'priya@pstransport.com', 4.50),
('Amit Singh', 'AS Freight', '+91-9876543212', 'amit@asfreight.com', 6.00)
ON CONFLICT DO NOTHING;

-- ==================== FUNCTIONS AND TRIGGERS ====================
-- LR number generation functions are created in a separate script
-- Run business_logic_functions.sql after this script completes successfully

-- Success message
SELECT 'Business logic database schema created successfully!' as message;
