-- RV Truck Fleet Management Database Setup (Fixed RLS Policies)
-- Run these commands in Supabase SQL Editor

-- Drop existing tables if they exist (in reverse dependency order)
DROP TABLE IF EXISTS odometer_photos CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS diesel_records CASCADE;
DROP TABLE IF EXISTS trips CASCADE;
DROP TABLE IF EXISTS brokers CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Drop existing functions and triggers if they exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Create user_profiles table (references auth.users but doesn't modify it)
CREATE TABLE user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    phone_number TEXT,
    address TEXT,
    role TEXT CHECK (role IN ('admin', 'trafficManager', 'driver', 'accountant', 'pumpPartner')),
    approval_status TEXT CHECK (approval_status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    approved_by UUID REFERENCES user_profiles(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create vehicles table
CREATE TABLE vehicles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registration_number TEXT UNIQUE NOT NULL,
    vehicle_type TEXT NOT NULL,
    capacity TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create drivers table
CREATE TABLE drivers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    license_number TEXT UNIQUE NOT NULL,
    license_expiry DATE,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create brokers table
CREATE TABLE brokers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    commission_rate DECIMAL(5,2) DEFAULT 0.00,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trips table
CREATE TABLE trips (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_number TEXT UNIQUE NOT NULL,
    vehicle_id UUID REFERENCES vehicles(id),
    driver_id UUID REFERENCES drivers(id),
    broker_id UUID REFERENCES brokers(id),
    pickup_location TEXT NOT NULL,
    delivery_location TEXT NOT NULL,
    pickup_date TIMESTAMP WITH TIME ZONE NOT NULL,
    delivery_date TIMESTAMP WITH TIME ZONE,
    status TEXT NOT NULL DEFAULT 'scheduled',
    freight_amount DECIMAL(10,2),
    advance_amount DECIMAL(10,2) DEFAULT 0.00,
    balance_amount DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create diesel_records table
CREATE TABLE diesel_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vehicle_id UUID REFERENCES vehicles(id),
    trip_id UUID REFERENCES trips(id),
    pump_partner_id UUID REFERENCES user_profiles(id),
    date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    quantity_liters DECIMAL(8,2) NOT NULL,
    rate_per_liter DECIMAL(6,2) NOT NULL,
    odometer_reading INTEGER,
    location TEXT,
    receipt_number TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create expenses table
CREATE TABLE expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id),
    vehicle_id UUID REFERENCES vehicles(id),
    category TEXT NOT NULL,
    description TEXT,
    amount DECIMAL(10,2) NOT NULL,
    date DATE NOT NULL,
    receipt_url TEXT,
    created_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create odometer_photos table
CREATE TABLE odometer_photos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id),
    vehicle_id UUID REFERENCES vehicles(id),
    photo_url TEXT NOT NULL,
    odometer_reading INTEGER NOT NULL,
    location TEXT,
    taken_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, name, phone_number, address, role, approval_status)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone_number', ''),
        COALESCE(NEW.raw_user_meta_data->>'address', ''),
        NULL, -- No default role - must be set during profile completion
        'pending' -- Default approval status is pending
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to auto-approve admin users and prevent multiple admins
CREATE OR REPLACE FUNCTION auto_approve_admin()
RETURNS TRIGGER AS $$
BEGIN
    -- If role is admin, check if admin already exists
    IF NEW.role = 'admin' THEN
        -- Check if there's already an approved admin
        IF EXISTS (SELECT 1 FROM user_profiles WHERE role = 'admin' AND approval_status = 'approved') THEN
            RAISE EXCEPTION 'Only one admin account is allowed. An admin already exists.';
        END IF;
        
        -- Auto-approve the admin
        NEW.approval_status = 'approved';
        NEW.approved_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to auto-approve admin users
CREATE TRIGGER auto_approve_admin_trigger
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION auto_approve_admin();

-- Create trigger to automatically create user profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE brokers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE diesel_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE odometer_photos ENABLE ROW LEVEL SECURITY;

-- SIMPLIFIED RLS POLICIES (No Recursion)
-- Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow all authenticated users to view all profiles (for now)
-- This can be restricted later based on business requirements
CREATE POLICY "Authenticated users can view all profiles" ON user_profiles
    FOR SELECT USING (auth.role() = 'authenticated');

-- Vehicle policies - allow all authenticated users for now
CREATE POLICY "Authenticated users can manage vehicles" ON vehicles
    FOR ALL USING (auth.role() = 'authenticated');

-- Trip policies - allow all authenticated users for now
CREATE POLICY "Authenticated users can manage trips" ON trips
    FOR ALL USING (auth.role() = 'authenticated');

-- Diesel record policies - allow all authenticated users for now
CREATE POLICY "Authenticated users can manage diesel records" ON diesel_records
    FOR ALL USING (auth.role() = 'authenticated');

-- Expense policies - allow all authenticated users for now
CREATE POLICY "Authenticated users can manage expenses" ON expenses
    FOR ALL USING (auth.role() = 'authenticated');

-- Odometer photo policies - allow all authenticated users for now
CREATE POLICY "Authenticated users can manage odometer photos" ON odometer_photos
    FOR ALL USING (auth.role() = 'authenticated');

-- Insert sample data
INSERT INTO vehicles (registration_number, vehicle_type, capacity) VALUES
('KA01AB1234', 'Truck', '9 Tons'),
('KA02CD5678', 'Truck', '12 Tons'),
('KA03EF9012', 'Truck', '16 Tons');

INSERT INTO brokers (name, contact_person, phone, email, commission_rate) VALUES
('ABC Logistics', 'John Doe', '+91-9876543210', 'john@abclogistics.com', 5.00),
('XYZ Transport', 'Jane Smith', '+91-9876543211', 'jane@xyztransport.com', 4.50);

-- Create indexes for better performance
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_trips_vehicle_id ON trips(vehicle_id);
CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_diesel_records_vehicle_id ON diesel_records(vehicle_id);
CREATE INDEX idx_diesel_records_date ON diesel_records(date);
CREATE INDEX idx_expenses_trip_id ON expenses(trip_id);
CREATE INDEX idx_expenses_date ON expenses(date);

-- Create unique constraint to ensure only one admin account
CREATE UNIQUE INDEX idx_unique_admin ON user_profiles(role) WHERE role = 'admin' AND approval_status = 'approved';
