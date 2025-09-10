-- Complete RLS policies fix for all roles
-- Run this in Supabase SQL Editor after running update_trip_manager_role.sql

-- ==============================================
-- 1. TRIPS TABLE POLICIES
-- ==============================================

-- Drop existing trip policies
DROP POLICY IF EXISTS "Allow all authenticated users to view trips" ON trips;
DROP POLICY IF EXISTS "Allow trip managers to create trips" ON trips;
DROP POLICY IF EXISTS "Allow trip managers to update trips" ON trips;
DROP POLICY IF EXISTS "Allow admins to manage trips" ON trips;

-- Allow all authenticated users to view trips
CREATE POLICY "Allow all authenticated users to view trips" ON trips
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow trip managers to create trips
CREATE POLICY "Allow trip managers to create trips" ON trips
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'trip_manager'
        )
    );

-- Allow trip managers to update trips
CREATE POLICY "Allow trip managers to update trips" ON trips
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'trip_manager'
        )
    );

-- Allow admins to manage all trips
CREATE POLICY "Allow admins to manage trips" ON trips
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- ==============================================
-- 2. EXPENSES TABLE POLICIES
-- ==============================================

-- Drop existing expense policies
DROP POLICY IF EXISTS "Allow all authenticated users to view expenses" ON expenses;
DROP POLICY IF EXISTS "Allow drivers to create expenses" ON expenses;
DROP POLICY IF EXISTS "Allow drivers to update their own expenses" ON expenses;
DROP POLICY IF EXISTS "Allow admins and accountants to manage expenses" ON expenses;

-- Allow all authenticated users to view expenses
CREATE POLICY "Allow all authenticated users to view expenses" ON expenses
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow drivers to create expenses
CREATE POLICY "Allow drivers to create expenses" ON expenses
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'driver'
        )
    );

-- Allow drivers to update their own expenses
CREATE POLICY "Allow drivers to update their own expenses" ON expenses
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'driver'
        ) AND
        entered_by = auth.uid()
    );

-- Allow admins, trip managers, and accountants to manage expenses
CREATE POLICY "Allow admins and managers to manage expenses" ON expenses
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager', 'accountant')
        )
    );

-- ==============================================
-- 3. ADVANCES TABLE POLICIES
-- ==============================================

-- Drop existing advance policies
DROP POLICY IF EXISTS "Allow all authenticated users to view advances" ON advances;
DROP POLICY IF EXISTS "Allow drivers to create advances" ON advances;
DROP POLICY IF EXISTS "Allow drivers to update their own advances" ON advances;
DROP POLICY IF EXISTS "Allow admins and accountants to manage advances" ON advances;

-- Allow all authenticated users to view advances
CREATE POLICY "Allow all authenticated users to view advances" ON advances
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow drivers to create advances
CREATE POLICY "Allow drivers to create advances" ON advances
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'driver'
        )
    );

-- Allow drivers to update their own advances
CREATE POLICY "Allow drivers to update their own advances" ON advances
    FOR UPDATE USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'driver'
        ) AND
        driver_id = auth.uid()
    );

-- Allow admins, trip managers, and accountants to manage advances
CREATE POLICY "Allow admins and managers to manage advances" ON advances
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager', 'accountant')
        )
    );

-- ==============================================
-- 4. VEHICLES TABLE POLICIES
-- ==============================================

-- Drop existing vehicle policies
DROP POLICY IF EXISTS "Allow all authenticated users to view vehicles" ON vehicles;
DROP POLICY IF EXISTS "Allow admins to manage vehicles" ON vehicles;

-- Allow all authenticated users to view vehicles
CREATE POLICY "Allow all authenticated users to view vehicles" ON vehicles
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow admins and trip managers to manage vehicles
CREATE POLICY "Allow admins and managers to manage vehicles" ON vehicles
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager')
        )
    );

-- ==============================================
-- 5. BROKERS TABLE POLICIES
-- ==============================================

-- Drop existing broker policies
DROP POLICY IF EXISTS "Allow all authenticated users to view brokers" ON brokers;
DROP POLICY IF EXISTS "Allow admins to manage brokers" ON brokers;

-- Allow all authenticated users to view brokers
CREATE POLICY "Allow all authenticated users to view brokers" ON brokers
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow admins and trip managers to manage brokers
CREATE POLICY "Allow admins and managers to manage brokers" ON brokers
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager')
        )
    );

-- ==============================================
-- 6. DIESEL_ENTRIES TABLE POLICIES
-- ==============================================

-- Drop existing diesel policies
DROP POLICY IF EXISTS "Allow all authenticated users to view diesel entries" ON diesel_entries;
DROP POLICY IF EXISTS "Allow drivers to create diesel entries" ON diesel_entries;

-- Allow all authenticated users to view diesel entries
CREATE POLICY "Allow all authenticated users to view diesel entries" ON diesel_entries
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow drivers to create diesel entries
CREATE POLICY "Allow drivers to create diesel entries" ON diesel_entries
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'driver'
        )
    );

-- Allow admins and trip managers to manage diesel entries
CREATE POLICY "Allow admins and managers to manage diesel entries" ON diesel_entries
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager')
        )
    );

-- ==============================================
-- 7. ODOMETER_PHOTOS TABLE POLICIES
-- ==============================================

-- Drop existing photo policies
DROP POLICY IF EXISTS "Allow all authenticated users to view odometer photos" ON odometer_photos;
DROP POLICY IF EXISTS "Allow drivers to create odometer photos" ON odometer_photos;

-- Allow all authenticated users to view odometer photos
CREATE POLICY "Allow all authenticated users to view odometer photos" ON odometer_photos
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow drivers to create odometer photos
CREATE POLICY "Allow drivers to create odometer photos" ON odometer_photos
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'driver'
        )
    );

-- Allow admins and trip managers to manage odometer photos
CREATE POLICY "Allow admins and managers to manage odometer photos" ON odometer_photos
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager')
        )
    );

-- ==============================================
-- 8. SILAK_CALCULATIONS TABLE POLICIES
-- ==============================================

-- Drop existing silak policies
DROP POLICY IF EXISTS "Allow all authenticated users to view silak calculations" ON silak_calculations;
DROP POLICY IF EXISTS "Allow admins to manage silak calculations" ON silak_calculations;

-- Allow all authenticated users to view silak calculations
CREATE POLICY "Allow all authenticated users to view silak calculations" ON silak_calculations
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow admins and trip managers to manage silak calculations
CREATE POLICY "Allow admins and managers to manage silak calculations" ON silak_calculations
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'trip_manager')
        )
    );

-- Success message
SELECT 'Complete RLS policies created successfully!' as message;
