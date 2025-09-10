-- Fix RLS policies to allow drivers to create expenses and advances
-- Run this in Supabase SQL Editor

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow drivers to create expenses" ON expenses;
DROP POLICY IF EXISTS "Allow drivers to create advances" ON advances;
DROP POLICY IF EXISTS "Allow drivers to update their own expenses" ON expenses;
DROP POLICY IF EXISTS "Allow drivers to update their own advances" ON advances;

-- Create INSERT policies for expenses
CREATE POLICY "Allow drivers to create expenses" ON expenses
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'driver'
        )
    );

-- Create INSERT policies for advances
CREATE POLICY "Allow drivers to create advances" ON advances
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'driver'
        )
    );

-- Create UPDATE policies for expenses (drivers can update their own expenses)
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

-- Create UPDATE policies for advances (drivers can update their own advances)
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

-- Also allow admins and accountants to manage expenses and advances
CREATE POLICY "Allow admins and accountants to manage expenses" ON expenses
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'accountant')
        )
    );

CREATE POLICY "Allow admins and accountants to manage advances" ON advances
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'accountant')
        )
    );

-- Success message
SELECT 'Driver RLS policies created successfully!' as message;
