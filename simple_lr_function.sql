-- Simple LR number generation function
-- This version doesn't depend on the trips table

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS generate_simple_lr_number() CASCADE;

-- Create simple LR number generation function
CREATE OR REPLACE FUNCTION generate_simple_lr_number()
RETURNS TEXT AS $$
DECLARE
    current_year TEXT;
    sequence_num INTEGER;
    lr_number TEXT;
BEGIN
    current_year := EXTRACT(YEAR FROM NOW())::TEXT;
    
    -- Use timestamp for uniqueness (simple approach)
    sequence_num := EXTRACT(EPOCH FROM NOW())::INTEGER % 100000;
    
    -- Format: LR-YYYY-XXXXX
    lr_number := 'LR-' || current_year || '-' || LPAD(sequence_num::TEXT, 5, '0');
    
    RETURN lr_number;
END;
$$ LANGUAGE plpgsql;

-- Test the function
SELECT generate_simple_lr_number() as test_lr_number;

-- Success message
SELECT 'Simple LR number function created successfully!' as message;
