-- RV Truck Fleet Management - Business Logic Functions
-- Run this AFTER business_logic_schema.sql has been executed successfully
-- This script only creates the LR number generation functions

-- Drop existing functions and triggers if they exist
DROP TRIGGER IF EXISTS set_trip_lr_number ON trips CASCADE;
DROP FUNCTION IF EXISTS set_lr_number() CASCADE;
DROP FUNCTION IF EXISTS generate_lr_number() CASCADE;

-- Create function to auto-generate LR numbers
CREATE OR REPLACE FUNCTION generate_lr_number()
RETURNS TEXT AS $$
DECLARE
    current_year TEXT;
    sequence_num INTEGER;
    lr_number TEXT;
BEGIN
    current_year := EXTRACT(YEAR FROM NOW())::TEXT;
    
    -- Get the next sequence number for this year
    SELECT COALESCE(MAX(CAST(SUBSTRING(lr_number FROM 'LR-' || current_year || '-(\d+)') AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM trips
    WHERE lr_number LIKE 'LR-' || current_year || '-%';
    
    -- Format: LR-YYYY-XXXXX
    lr_number := 'LR-' || current_year || '-' || LPAD(sequence_num::TEXT, 5, '0');
    
    RETURN lr_number;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate LR number
CREATE OR REPLACE FUNCTION set_lr_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.lr_number IS NULL OR NEW.lr_number = '' THEN
        NEW.lr_number := generate_lr_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for LR number generation
CREATE TRIGGER set_trip_lr_number
    BEFORE INSERT ON trips
    FOR EACH ROW
    EXECUTE FUNCTION set_lr_number();

-- Test the function
SELECT generate_lr_number() as test_lr_number;

-- Success message
SELECT 'LR number generation functions created successfully!' as message;


