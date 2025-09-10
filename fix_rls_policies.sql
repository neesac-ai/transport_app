-- Fix RLS policies to allow admin operations
-- Run this in Supabase SQL Editor

-- Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON user_profiles;

-- Create new policies that allow admin operations
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow admins to view and update all profiles
CREATE POLICY "Admins can view all profiles" ON user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin' 
            AND approval_status = 'approved'
        )
    );

CREATE POLICY "Admins can update all profiles" ON user_profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role = 'admin' 
            AND approval_status = 'approved'
        )
    );

-- Allow all authenticated users to view profiles (for now)
CREATE POLICY "Authenticated users can view all profiles" ON user_profiles
    FOR SELECT USING (auth.role() = 'authenticated');
