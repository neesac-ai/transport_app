-- Test script for trip creation
-- Run this after business_logic_schema_minimal.sql and simple_lr_function.sql

-- First, let's check what data we have
SELECT 'Available brokers:' as info;
SELECT id, name, company FROM brokers;

-- Check if we have any vehicles and drivers from the main schema
SELECT 'Available vehicles:' as info;
SELECT id, registration_number, vehicle_type FROM vehicles LIMIT 5;

SELECT 'Available drivers:' as info;
SELECT d.id, up.name, d.license_number 
FROM drivers d 
JOIN user_profiles up ON d.user_id = up.id 
LIMIT 5;

-- Test 1: Create a trip with a real broker (from our sample data)
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
    (SELECT id FROM vehicles LIMIT 1),  -- Use first available vehicle
    (SELECT id FROM drivers LIMIT 1),   -- Use first available driver
    (SELECT id FROM brokers WHERE name = 'Rajesh Kumar'),  -- Use our sample broker
    'Mumbai',
    'Delhi',
    20.0,
    5000.0,
    100000.0,  -- 20 * 5000
    5000.0     -- 5% commission
);

-- Test 2: Create another trip
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
    (SELECT id FROM vehicles LIMIT 1 OFFSET 1),  -- Use second vehicle if available
    (SELECT id FROM drivers LIMIT 1 OFFSET 1),   -- Use second driver if available
    (SELECT id FROM brokers WHERE name = 'Priya Sharma'),  -- Use different broker
    'Delhi',
    'Bangalore',
    15.0,
    4500.0,
    67500.0,  -- 15 * 4500
    3037.5    -- 4.5% commission
);

-- Test 3: Verify the trips were created
SELECT 'Created trips:' as info;
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
ORDER BY created_at DESC;

-- Test 4: Create a diesel entry for the first trip
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

-- Test 5: Create an expense for the trip
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

-- Test 6: Verify all data
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
SELECT 'Trip creation test completed successfully!' as message;
