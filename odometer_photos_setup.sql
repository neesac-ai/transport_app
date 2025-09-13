-- Check if the bucket exists and its status
SELECT * FROM storage.buckets WHERE id = 'odometer-photos';

-- Create RLS policies for odometer photos storage
-- We'll use DROP POLICY IF EXISTS to avoid errors if policies already exist
DO $$
BEGIN
    -- Try to drop existing policies first (will do nothing if they don't exist)
    EXECUTE 'DROP POLICY IF EXISTS "Allow drivers to upload odometer photos" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow drivers to view odometer photos" ON storage.objects';
    EXECUTE 'DROP POLICY IF EXISTS "Allow drivers to delete odometer photos" ON storage.objects';
    
    -- Create upload policy
    EXECUTE $policy$
    CREATE POLICY "Allow drivers to upload odometer photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'odometer-photos' AND
        auth.role() IN ('authenticated', 'driver', 'tripManager', 'admin')
    );
    $policy$;
    
    -- Create view policy
    EXECUTE $policy$
    CREATE POLICY "Allow drivers to view odometer photos" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'odometer-photos' AND
        auth.role() IN ('authenticated', 'driver', 'tripManager', 'admin')
    );
    $policy$;
    
    -- Create delete policy
    EXECUTE $policy$
    CREATE POLICY "Allow drivers to delete odometer photos" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'odometer-photos' AND
        auth.role() IN ('authenticated', 'driver', 'tripManager', 'admin')
    );
    $policy$;
END
$$;

-- Create RLS policies for odometer_photos table
-- First drop existing policies to avoid errors
DO $$
BEGIN
    -- Try to drop existing policies first (will do nothing if they don't exist)
    EXECUTE 'DROP POLICY IF EXISTS "Allow drivers to insert odometer photos" ON public.odometer_photos';
    EXECUTE 'DROP POLICY IF EXISTS "Allow drivers to view odometer photos" ON public.odometer_photos';
    EXECUTE 'DROP POLICY IF EXISTS "Allow drivers to delete odometer photos" ON public.odometer_photos';
    
    -- Create insert policy
    EXECUTE $policy$
    CREATE POLICY "Allow drivers to insert odometer photos" ON public.odometer_photos
    FOR INSERT WITH CHECK (
        auth.role() IN ('authenticated', 'driver', 'tripManager', 'admin')
    );
    $policy$;
    
    -- Create select policy
    EXECUTE $policy$
    CREATE POLICY "Allow drivers to view odometer photos" ON public.odometer_photos
    FOR SELECT USING (
        auth.role() IN ('authenticated', 'driver', 'tripManager', 'admin')
    );
    $policy$;
    
    -- Create delete policy
    EXECUTE $policy$
    CREATE POLICY "Allow drivers to delete odometer photos" ON public.odometer_photos
    FOR DELETE USING (
        auth.role() IN ('authenticated', 'driver', 'tripManager', 'admin')
    );
    $policy$;
END
$$;

-- Enable RLS on odometer_photos table if not already enabled
ALTER TABLE public.odometer_photos ENABLE ROW LEVEL SECURITY;