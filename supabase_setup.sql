-- RV Truck Fleet Management Database Setup
-- Run these commands in Supabase SQL Editor

-- Note: We cannot modify auth.users table directly as it's owned by Supabase
-- Instead, we'll create a separate user_profiles table that references auth.users

-- Create user_profiles table
CREATE TABLE user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    phone_number TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    address TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'traffic_manager', 'driver', 'accountant', 'pump_partner')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create vehicles table
CREATE TABLE vehicles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    registration_number TEXT UNIQUE NOT NULL,
    vehicle_type TEXT NOT NULL,
    capacity TEXT NOT NULL,
    driver_id UUID REFERENCES user_profiles(id),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'inactive', 'retired')),
    rc_number TEXT,
    permit_number TEXT,
    insurance_number TEXT,
    insurance_expiry DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create drivers table (separate from user_profiles for detailed driver info)
CREATE TABLE drivers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) UNIQUE,
    license_number TEXT UNIQUE NOT NULL,
    license_expiry DATE,
    assigned_vehicle_id UUID REFERENCES vehicles(id),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'on_trip', 'on_leave', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create brokers table
CREATE TABLE brokers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    company TEXT,
    contact_number TEXT NOT NULL,
    email TEXT,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trips table
CREATE TABLE trips (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vehicle_id UUID REFERENCES vehicles(id) NOT NULL,
    driver_id UUID REFERENCES user_profiles(id) NOT NULL,
    broker_id UUID REFERENCES brokers(id),
    lr_number TEXT UNIQUE NOT NULL,
    from_location TEXT NOT NULL,
    to_location TEXT NOT NULL,
    tonnage DECIMAL(10,2) NOT NULL,
    rate_per_ton DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) GENERATED ALWAYS AS (tonnage * rate_per_ton) STORED,
    commission_percentage DECIMAL(5,2) DEFAULT 0,
    commission_amount DECIMAL(10,2) GENERATED ALWAYS AS (tonnage * rate_per_ton * commission_percentage / 100) STORED,
    status TEXT NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned', 'in_progress', 'completed', 'cancelled')),
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    odometer_start INTEGER,
    odometer_end INTEGER,
    distance_km INTEGER GENERATED ALWAYS AS (odometer_end - odometer_start) STORED,
    diesel_issued DECIMAL(10,2) DEFAULT 0,
    advance_given DECIMAL(10,2) DEFAULT 0,
    silak_amount DECIMAL(10,2) DEFAULT 0,
    is_settled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create diesel_records table
CREATE TABLE diesel_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    vehicle_id UUID REFERENCES vehicles(id) NOT NULL,
    trip_id UUID REFERENCES trips(id),
    amount DECIMAL(10,2) NOT NULL,
    liters DECIMAL(10,2) NOT NULL,
    rate_per_liter DECIMAL(10,2) GENERATED ALWAYS AS (amount / liters) STORED,
    pump_name TEXT,
    pump_partner_id UUID REFERENCES user_profiles(id),
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    receipt_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create expenses table
CREATE TABLE expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id),
    vehicle_id UUID REFERENCES vehicles(id),
    category TEXT NOT NULL CHECK (category IN ('toll', 'parking', 'maintenance', 'food', 'accommodation', 'other')),
    amount DECIMAL(10,2) NOT NULL,
    description TEXT NOT NULL,
    receipt_url TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES user_profiles(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create odometer_photos table
CREATE TABLE odometer_photos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) NOT NULL,
    photo_type TEXT NOT NULL CHECK (photo_type IN ('start', 'end')),
    photo_url TEXT NOT NULL,
    odometer_reading INTEGER NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    taken_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_vehicles_registration ON vehicles(registration_number);
CREATE INDEX idx_vehicles_driver ON vehicles(driver_id);
CREATE INDEX idx_trips_vehicle ON trips(vehicle_id);
CREATE INDEX idx_trips_driver ON trips(driver_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_diesel_records_vehicle ON diesel_records(vehicle_id);
CREATE INDEX idx_diesel_records_trip ON diesel_records(trip_id);
CREATE INDEX idx_expenses_trip ON expenses(trip_id);
CREATE INDEX idx_expenses_vehicle ON expenses(vehicle_id);

-- Row Level Security Policies

-- User profiles can only see their own data
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Admin and Traffic Manager can see all vehicles
CREATE POLICY "Admin and Traffic Manager can view all vehicles" ON vehicles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'traffic_manager')
        )
    );

-- Drivers can only see their assigned vehicle
CREATE POLICY "Drivers can view assigned vehicle" ON vehicles
    FOR SELECT USING (
        driver_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'traffic_manager')
        )
    );

-- Similar policies for other tables...
-- (Add more policies as needed based on your security requirements)

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE brokers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE diesel_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE odometer_photos ENABLE ROW LEVEL SECURITY;

-- Create function to handle user profile creation
-- This function will be called when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, phone_number, name, email, address, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.phone, ''),
        COALESCE(NEW.raw_user_meta_data->>'name', ''),
        COALESCE(NEW.email, ''),
        COALESCE(NEW.raw_user_meta_data->>'address', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'driver')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: The trigger on auth.users will be created automatically by Supabase
-- when you enable the function in the dashboard, or you can create it manually
-- if you have the proper permissions
