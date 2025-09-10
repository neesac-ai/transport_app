-- Simple fix for trips RLS policy - allow all authenticated users
-- Run this in Supabase SQL Editor

-- Drop existing trip policies
DROP POLICY IF EXISTS "Allow all authenticated users to view trips" ON trips;
DROP POLICY IF EXISTS "Allow trip managers to create trips" ON trips;
DROP POLICY IF EXISTS "Allow trip managers to update trips" ON trips;
DROP POLICY IF EXISTS "Allow admins to manage trips" ON trips;

-- Allow all authenticated users to view trips
CREATE POLICY "Allow all authenticated users to view trips" ON trips
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow all authenticated users to create trips (for now)
CREATE POLICY "Allow all authenticated users to create trips" ON trips
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow all authenticated users to update trips (for now)
CREATE POLICY "Allow all authenticated users to update trips" ON trips
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Test the policy
SELECT 'Testing trips table access' as test_name;
SELECT COUNT(*) as trip_count FROM trips;

-- Success message
SELECT 'Trips RLS policy simplified successfully!' as message;

