-- Test trips table structure and access
-- Run this in Supabase SQL Editor

-- Check if trips table exists
SELECT 'Testing trips table structure' as test_name;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'trips' 
ORDER BY ordinal_position;

-- Check if we can read from trips table
SELECT 'Testing trips table read access' as test_name;
SELECT COUNT(*) as trip_count FROM trips;

-- Check if we can insert a simple test record
SELECT 'Testing trips table insert access' as test_name;
INSERT INTO trips (
    id,
    lr_number,
    vehicle_id,
    driver_id,
    from_location,
    to_location,
    status,
    created_at
) VALUES (
    gen_random_uuid(),
    'TEST-LR-001',
    (SELECT id FROM vehicles LIMIT 1),
    (SELECT id FROM drivers LIMIT 1),
    'Test From',
    'Test To',
    'assigned',
    NOW()
) RETURNING id, lr_number;

-- Clean up test record
DELETE FROM trips WHERE lr_number = 'TEST-LR-001';

SELECT 'Trips table test completed!' as message;

