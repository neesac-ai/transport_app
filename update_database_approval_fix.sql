-- Update existing database to fix approval system and add admin restriction
-- Run this in Supabase SQL Editor

-- Add approval status fields if they don't exist
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS approval_status TEXT CHECK (approval_status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending';

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES user_profiles(id);

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Update existing users to have pending status (except if they're already admins)
UPDATE user_profiles 
SET approval_status = 'pending' 
WHERE approval_status IS NULL AND role != 'admin';

-- Auto-approve existing admin users
UPDATE user_profiles 
SET approval_status = 'approved', approved_at = NOW() 
WHERE role = 'admin' AND approval_status IS NULL;

-- Create function to auto-approve admin users and prevent multiple admins
CREATE OR REPLACE FUNCTION auto_approve_admin()
RETURNS TRIGGER AS $$
BEGIN
    -- If role is admin, check if admin already exists
    IF NEW.role = 'admin' THEN
        -- Check if there's already an approved admin
        IF EXISTS (SELECT 1 FROM user_profiles WHERE role = 'admin' AND approval_status = 'approved' AND id != NEW.id) THEN
            RAISE EXCEPTION 'Only one admin account is allowed. An admin already exists.';
        END IF;
        
        -- Auto-approve the admin
        NEW.approval_status = 'approved';
        NEW.approved_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_approve_admin_trigger ON user_profiles;

-- Create trigger to auto-approve admin users
CREATE TRIGGER auto_approve_admin_trigger
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION auto_approve_admin();

-- Create unique constraint to ensure only one admin account
DROP INDEX IF EXISTS idx_unique_admin;
CREATE UNIQUE INDEX idx_unique_admin ON user_profiles(role) WHERE role = 'admin' AND approval_status = 'approved';

-- Update the handle_new_user function to set approval_status
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, name, phone_number, address, role, approval_status)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone_number', ''),
        COALESCE(NEW.raw_user_meta_data->>'address', ''),
        NULL, -- No default role - must be set during profile completion
        'pending' -- Default approval status is pending
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
