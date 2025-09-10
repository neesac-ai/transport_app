-- Simple fix for drivers RLS policy
-- Run this in Supabase SQL Editor

-- ==============================================
-- 1. DRIVERS TABLE - Add missing SELECT policy
-- ==============================================

-- Add policy to allow all authenticated users to view drivers
CREATE POLICY "Allow all authenticated users to view drivers" ON drivers
    FOR SELECT USING (auth.role() = 'authenticated');

-- ==============================================
-- 2. USER_PROFILES TABLE - Add missing SELECT policy
-- ==============================================

-- Add policy to allow all authenticated users to view user profiles
CREATE POLICY "Allow all authenticated users to view user profiles" ON user_profiles
    FOR SELECT USING (auth.role() = 'authenticated');

-- ==============================================
-- 3. VEHICLES TABLE - Add missing SELECT policy
-- ==============================================

-- Add policy to allow all authenticated users to view vehicles
CREATE POLICY "Allow all authenticated users to view vehicles" ON vehicles
    FOR SELECT USING (auth.role() = 'authenticated');

-- ==============================================
-- 4. BROKERS TABLE - Add missing SELECT policy
-- ==============================================

-- Add policy to allow all authenticated users to view brokers
CREATE POLICY "Allow all authenticated users to view brokers" ON brokers
    FOR SELECT USING (auth.role() = 'authenticated');

-- Success message
SELECT 'RLS SELECT policies added successfully!' as message;
