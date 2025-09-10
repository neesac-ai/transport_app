-- Simple verification script for business logic schema
-- Run this after business_logic_schema.sql to verify tables exist

-- Check if all tables exist
SELECT 
    table_name,
    'Table exists' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'brokers', 
    'trips', 
    'diesel_entries', 
    'expenses', 
    'odometer_photos', 
    'advances', 
    'silak_calculations'
)
ORDER BY table_name;

-- Check if sample broker data exists
SELECT 
    name,
    company,
    commission_rate
FROM brokers
ORDER BY name;

-- Success message
SELECT 'Schema verification completed successfully!' as message;


