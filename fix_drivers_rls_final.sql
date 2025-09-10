-- Final fix for drivers RLS policy
-- Run this in Supabase SQL Editor

-- Drop existing policies that might be too restrictive
DROP POLICY IF EXISTS "Allow admins to manage drivers" ON drivers;
DROP POLICY IF EXISTS "Allow admins and managers to manage drivers" ON drivers;
DROP POLICY IF EXISTS "Allow all authenticated users to view drivers" ON drivers;

-- Create a simple policy that allows all authenticated users to view drivers
CREATE POLICY "Allow all authenticated users to view drivers" ON drivers
    FOR SELECT USING (auth.role() = 'authenticated');

-- Create a policy that allows admins and trip managers to manage drivers
CREATE POLICY "Allow admins and trip managers to manage drivers" ON drivers
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'tripManager')
        )
    );

-- Test the policy
SELECT 'Testing drivers query after policy fix' as test_name;
SELECT id, user_id, license_number, status FROM drivers LIMIT 5;

-- Success message
SELECT 'Drivers RLS policy fixed successfully!' as message;
