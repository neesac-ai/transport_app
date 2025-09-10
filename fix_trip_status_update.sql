-- Fix trip status update permissions
-- Run this in Supabase SQL Editor

-- Check existing policies on trips table
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'trips';

-- Drop existing update policies
DROP POLICY IF EXISTS "Allow only trip managers to update trips" ON trips;
DROP POLICY IF EXISTS "Allow trip managers to update trips" ON trips;
DROP POLICY IF EXISTS "Allow all authenticated users to update trips" ON trips;
DROP POLICY IF EXISTS "Allow drivers to update assigned trips" ON trips;

-- Allow trip managers to update trips
CREATE POLICY "Allow only trip managers to update trips" ON trips
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'tripManager'
        )
    );

-- Allow drivers to update their own trip status (for start/complete actions)
CREATE POLICY "Allow drivers to update assigned trips" ON trips
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM drivers 
            WHERE drivers.id = trips.driver_id 
            AND drivers.user_id = auth.uid()
        )
    );

-- Test the policies
SELECT 'Testing trip update policies' as test_name;
SELECT COUNT(*) as trip_count FROM trips;

-- Success message
SELECT 'Trip status update policies fixed successfully!' as message;
