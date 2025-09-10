-- Test drivers query to see what's happening
-- Run this in Supabase SQL Editor

-- Test 1: Check if we can read drivers table at all
SELECT 'Test 1: Basic drivers query' as test_name;
SELECT id, user_id, license_number, status FROM drivers LIMIT 5;

-- Test 2: Check if we can read active drivers
SELECT 'Test 2: Active drivers query' as test_name;
SELECT id, user_id, license_number, status FROM drivers WHERE status = 'active' LIMIT 5;

-- Test 3: Check if we can read user_profiles
SELECT 'Test 3: User profiles query' as test_name;
SELECT id, name, email, role FROM user_profiles LIMIT 5;

-- Test 4: Check current user context
SELECT 'Test 4: Current user context' as test_name;
SELECT auth.uid() as current_user_id, auth.role() as current_role;

-- Test 5: Check if current user has trip_manager role
SELECT 'Test 5: Current user role check' as test_name;
SELECT 
    up.id,
    up.name,
    up.role,
    up.approval_status
FROM user_profiles up
WHERE up.id = auth.uid();
