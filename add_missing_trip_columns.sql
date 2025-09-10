-- Add missing columns to trips table for proper date tracking

-- Add cancelled_at column
ALTER TABLE trips 
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- Add settled_at column  
ALTER TABLE trips 
ADD COLUMN IF NOT EXISTS settled_at TIMESTAMPTZ;

-- Update the updated_at trigger to include new columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Ensure the trigger exists for trips table
DROP TRIGGER IF EXISTS update_trips_updated_at ON trips;
CREATE TRIGGER update_trips_updated_at
    BEFORE UPDATE ON trips
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON COLUMN trips.cancelled_at IS 'Timestamp when the trip was cancelled';
COMMENT ON COLUMN trips.settled_at IS 'Timestamp when the trip was settled';
COMMENT ON COLUMN trips.start_date IS 'Timestamp when the trip was started (status changed to in_progress)';
COMMENT ON COLUMN trips.end_date IS 'Timestamp when the trip was completed (status changed to completed)';
COMMENT ON COLUMN trips.assigned_by IS 'User ID who assigned/created the trip';
