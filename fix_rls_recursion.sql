-- Fix infinite recursion in RLS policies
-- Run this in Supabase SQL Editor

-- Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON user_profiles;

-- Create simple, non-recursive policies
-- Allow users to view their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Allow users to insert their own profile
CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow all authenticated users to view all profiles (simple approach)
CREATE POLICY "Authenticated users can view all profiles" ON user_profiles
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow all authenticated users to update all profiles (for admin operations)
CREATE POLICY "Authenticated users can update all profiles" ON user_profiles
    FOR UPDATE USING (auth.role() = 'authenticated');
