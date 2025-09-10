-- Test Trip Manager access to trips
-- This query should show all trips that the current user (Trip Manager) can access

-- First, check current user and role
SELECT 
  auth.uid() as current_user_id,
  up.role as current_role
FROM user_profiles up 
WHERE up.id = auth.uid();

-- Test query to get all trips (this is what the app should be doing)
SELECT 
  id,
  lr_number,
  status,
  from_location,
  to_location,
  created_at
FROM trips 
ORDER BY created_at DESC;

-- Count total trips
SELECT COUNT(*) as total_trips FROM trips;

-- Check if there are any RLS policy issues
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'trips';
