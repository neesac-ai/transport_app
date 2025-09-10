-- Fix RLS policies for trips table
-- Run this in Supabase SQL Editor

-- Drop existing trip policies
DROP POLICY IF EXISTS "Allow all authenticated users to view trips" ON trips;
DROP POLICY IF EXISTS "Allow trip managers to create trips" ON trips;
DROP POLICY IF EXISTS "Allow trip managers to update trips" ON trips;
DROP POLICY IF EXISTS "Allow admins to manage trips" ON trips;

-- Allow all authenticated users to view trips
CREATE POLICY "Allow all authenticated users to view trips" ON trips
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow trip managers to create trips
CREATE POLICY "Allow trip managers to create trips" ON trips
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'tripManager'
        )
    );

-- Allow trip managers to update trips
CREATE POLICY "Allow trip managers to update trips" ON trips
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'tripManager'
        )
    );

-- Allow admins to manage all trips
CREATE POLICY "Allow admins to manage trips" ON trips
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Test the policy
SELECT 'Testing trips table access' as test_name;
SELECT COUNT(*) as trip_count FROM trips;

-- Success message
SELECT 'Trips RLS policy fixed successfully!' as message;
