-- Test script for business logic schema
-- Run this after business_logic_schema.sql to verify everything works

-- Test 1: Insert a broker
INSERT INTO brokers (name, company, contact_number, email, commission_rate) 
VALUES ('Test Broker', 'Test Company', '+91-9999999999', 'test@test.com', 5.0);

-- Test 2: Insert a trip (should auto-generate LR number)
INSERT INTO trips (
    vehicle_id, 
    driver_id, 
    broker_id, 
    from_location, 
    to_location, 
    tonnage, 
    rate_per_ton
) VALUES (
    (SELECT id FROM vehicles LIMIT 1),  -- Use existing vehicle
    (SELECT id FROM drivers LIMIT 1),   -- Use existing driver
    (SELECT id FROM brokers WHERE name = 'Test Broker'),  -- Use the broker we just created
    'Mumbai',
    'Delhi',
    20.0,
    5000.0
);

-- Test 3: Verify the trip was created with auto-generated LR number
SELECT 
    lr_number,
    from_location,
    to_location,
    tonnage,
    rate_per_ton,
    total_rate,
    commission_amount
FROM trips 
WHERE from_location = 'Mumbai' AND to_location = 'Delhi';

-- Test 4: Insert another trip to verify LR number sequence
INSERT INTO trips (
    vehicle_id, 
    driver_id, 
    broker_id, 
    from_location, 
    to_location, 
    tonnage, 
    rate_per_ton
) VALUES (
    (SELECT id FROM vehicles LIMIT 1),
    (SELECT id FROM drivers LIMIT 1),
    (SELECT id FROM brokers WHERE name = 'Test Broker'),
    'Delhi',
    'Bangalore',
    15.0,
    4500.0
);

-- Test 5: Verify both trips have sequential LR numbers
SELECT 
    lr_number,
    from_location,
    to_location,
    created_at
FROM trips 
ORDER BY created_at DESC
LIMIT 2;

-- Success message
SELECT 'Business logic schema test completed successfully!' as message;


