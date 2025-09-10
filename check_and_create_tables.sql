-- Check if business logic tables exist and create them if needed
-- Run this in Supabase SQL Editor

-- Check if tables exist
SELECT 
  table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('expenses', 'advances', 'trips', 'brokers', 'diesel_entries', 'odometer_photos', 'silak_calculations');

-- If the above query returns empty results, run the business_logic_schema.sql script
-- to create all the necessary tables for the business logic functionality.

