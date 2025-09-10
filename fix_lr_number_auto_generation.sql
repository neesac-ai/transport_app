-- Fix LR number auto-generation for trips table
-- Run this in Supabase SQL Editor

-- First, let's check if the function exists and test it
SELECT 'Testing LR function' as test_name;
SELECT generate_simple_lr_number() as test_lr_number;

-- Create a trigger function to auto-generate LR number
CREATE OR REPLACE FUNCTION set_lr_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Only set LR number if it's empty or null
    IF NEW.lr_number IS NULL OR NEW.lr_number = '' THEN
        NEW.lr_number := generate_simple_lr_number();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_set_lr_number ON trips;

-- Create trigger to auto-generate LR number on INSERT
CREATE TRIGGER trigger_set_lr_number
    BEFORE INSERT ON trips
    FOR EACH ROW
    EXECUTE FUNCTION set_lr_number();

-- Test the trigger by inserting a test record
INSERT INTO trips (
    id,
    vehicle_id,
    driver_id,
    from_location,
    to_location,
    status,
    created_at
) VALUES (
    gen_random_uuid(),
    (SELECT id FROM vehicles LIMIT 1),
    (SELECT id FROM drivers LIMIT 1),
    'Test From',
    'Test To',
    'assigned',
    NOW()
) RETURNING id, lr_number;

-- Clean up test record
DELETE FROM trips WHERE from_location = 'Test From' AND to_location = 'Test To';

-- Success message
SELECT 'LR number auto-generation fixed successfully!' as message;
