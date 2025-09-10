-- Fix RLS policies for drivers table
-- Run this in Supabase SQL Editor

-- ==============================================
-- 1. DRIVERS TABLE POLICIES
-- ==============================================

-- Drop existing driver policies
DROP POLICY IF EXISTS "Allow all authenticated users to view drivers" ON drivers;
DROP POLICY IF EXISTS "Allow admins to manage drivers" ON drivers;
DROP POLICY IF EXISTS "Allow drivers to view own record" ON drivers;

-- Allow all authenticated users to view drivers
CREATE POLICY "Allow all authenticated users to view drivers" ON drivers
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow admins and trip managers to manage drivers
CREATE POLICY "Allow admins and managers to manage drivers" ON drivers
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager')
        )
    );

-- Allow drivers to view their own record
CREATE POLICY "Allow drivers to view own record" ON drivers
    FOR SELECT USING (
        auth.role() = 'authenticated' AND
        user_id = auth.uid()
    );

-- ==============================================
-- 2. USER_PROFILES TABLE POLICIES (if needed)
-- ==============================================

-- Drop existing user_profiles policies
DROP POLICY IF EXISTS "Allow all authenticated users to view user profiles" ON user_profiles;
DROP POLICY IF EXISTS "Allow admins to manage user profiles" ON user_profiles;

-- Allow all authenticated users to view user profiles
CREATE POLICY "Allow all authenticated users to view user profiles" ON user_profiles
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow admins and trip managers to manage user profiles
CREATE POLICY "Allow admins and managers to manage user profiles" ON user_profiles
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager')
        )
    );

-- ==============================================
-- 3. VEHICLES TABLE POLICIES (if needed)
-- ==============================================

-- Drop existing vehicle policies
DROP POLICY IF EXISTS "Allow all authenticated users to view vehicles" ON vehicles;
DROP POLICY IF EXISTS "Allow admins to manage vehicles" ON vehicles;

-- Allow all authenticated users to view vehicles
CREATE POLICY "Allow all authenticated users to view vehicles" ON vehicles
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow admins and trip managers to manage vehicles
CREATE POLICY "Allow admins and managers to manage vehicles" ON vehicles
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager')
        )
    );

-- ==============================================
-- 4. BROKERS TABLE POLICIES (if needed)
-- ==============================================

-- Drop existing broker policies
DROP POLICY IF EXISTS "Allow all authenticated users to view brokers" ON brokers;
DROP POLICY IF EXISTS "Allow admins to manage brokers" ON brokers;

-- Allow all authenticated users to view brokers
CREATE POLICY "Allow all authenticated users to view brokers" ON brokers
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow admins and trip managers to manage brokers
CREATE POLICY "Allow admins and managers to manage brokers" ON brokers
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager')
        )
    );

-- Success message
SELECT 'RLS policies for drivers, vehicles, and brokers updated successfully!' as message;