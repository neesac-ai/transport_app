-- Check existing RLS policies for drivers table
-- Run this in Supabase SQL Editor

-- Check if RLS is enabled on drivers table
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'drivers';

-- Check existing policies on drivers table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'drivers';

-- Test the exact query that Flutter is making
SELECT 'Testing drivers query as current user' as test_name;
SELECT id, user_id, license_number, status, created_at FROM drivers LIMIT 5;

-- Test with current user context
SELECT 'Testing with auth context' as test_name;
SELECT 
    auth.uid() as current_user_id,
    auth.role() as current_role,
    (SELECT role FROM user_profiles WHERE id = auth.uid()) as user_role;
