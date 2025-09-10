-- Update database to support Trip Manager role
-- Run this in Supabase SQL Editor

-- Update the role constraint to include trip_manager
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_check 
    CHECK (role IN ('admin', 'trip_manager', 'driver', 'accountant', 'pump_partner'));

-- Update any existing traffic_manager records to trip_manager
UPDATE user_profiles 
SET role = 'trip_manager' 
WHERE role = 'traffic_manager';

-- Success message
SELECT 'Trip Manager role updated successfully!' as message;
