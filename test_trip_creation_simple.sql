-- Simple test script for trip creation
-- This version creates test data if none exists

-- First, let's check what data we have
SELECT 'Available brokers:' as info;
SELECT id, name, company FROM brokers;

-- Check if we have any vehicles and drivers
SELECT 'Available vehicles:' as info;
SELECT COUNT(*) as vehicle_count FROM vehicles;

SELECT 'Available drivers:' as info;
SELECT COUNT(*) as driver_count FROM drivers;

-- If no vehicles exist, create a test vehicle
INSERT INTO vehicles (registration_number, vehicle_type, capacity, status)
SELECT 'TEST-001', 'Truck', '20 tons', 'active'
WHERE NOT EXISTS (SELECT 1 FROM vehicles LIMIT 1);

-- If no drivers exist, create a test driver (we'll need a user profile first)
-- Let's check if we have any user profiles
SELECT 'Available user profiles:' as info;
SELECT COUNT(*) as user_count FROM user_profiles;

-- Create a test user profile if none exists
INSERT INTO user_profiles (id, email, name, phone_number, address, role, approval_status)
SELECT 
    gen_random_uuid(),
    'testdriver@example.com',
    'Test Driver',
    '+91-9999999999',
    'Test Address',
    'driver',
    'approved'
WHERE NOT EXISTS (SELECT 1 FROM user_profiles WHERE role = 'driver' LIMIT 1);

-- Create a test driver if none exists
INSERT INTO drivers (user_id, license_number, status)
SELECT 
    (SELECT id FROM user_profiles WHERE role = 'driver' LIMIT 1),
    'DL-TEST-001',
    'active'
WHERE NOT EXISTS (SELECT 1 FROM drivers LIMIT 1);

-- Now create a test trip
INSERT INTO trips (
    lr_number,
    vehicle_id,
    driver_id,
    broker_id,
    from_location,
    to_location,
    tonnage,
    rate_per_ton,
    total_rate,
    commission_amount
) VALUES (
    generate_simple_lr_number(),
    (SELECT id FROM vehicles LIMIT 1),
    (SELECT id FROM drivers LIMIT 1),
    (SELECT id FROM brokers LIMIT 1),
    'Mumbai',
    'Delhi',
    20.0,
    5000.0,
    100000.0,
    5000.0
);

-- Verify the trip was created
SELECT 'Created trip:' as info;
SELECT 
    lr_number,
    from_location,
    to_location,
    tonnage,
    rate_per_ton,
    total_rate,
    commission_amount,
    status,
    created_at
FROM trips 
ORDER BY created_at DESC
LIMIT 1;

-- Create a diesel entry for the trip
INSERT INTO diesel_entries (
    trip_id,
    vehicle_id,
    entry_type,
    quantity_liters,
    rate_per_liter,
    total_amount,
    pump_location,
    pump_name
) VALUES (
    (SELECT id FROM trips ORDER BY created_at DESC LIMIT 1),
    (SELECT vehicle_id FROM trips ORDER BY created_at DESC LIMIT 1),
    'credit_pump',
    100.0,
    95.0,
    9500.0,
    'Mumbai',
    'HP Pump'
);

-- Create an expense for the trip
INSERT INTO expenses (
    trip_id,
    category,
    description,
    amount,
    expense_date,
    status
) VALUES (
    (SELECT id FROM trips ORDER BY created_at DESC LIMIT 1),
    'toll',
    'Mumbai-Delhi toll charges',
    500.0,
    CURRENT_DATE,
    'pending'
);

-- Verify all data
SELECT 'Diesel entries:' as info;
SELECT 
    de.entry_type,
    de.quantity_liters,
    de.rate_per_liter,
    de.total_amount,
    de.pump_location,
    t.lr_number
FROM diesel_entries de
JOIN trips t ON de.trip_id = t.id;

SELECT 'Expenses:' as info;
SELECT 
    e.category,
    e.description,
    e.amount,
    e.status,
    t.lr_number
FROM expenses e
JOIN trips t ON e.trip_id = t.id;

-- Success message
SELECT 'Simple trip creation test completed successfully!' as message;
