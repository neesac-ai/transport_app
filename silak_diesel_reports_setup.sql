-- Create silak_allowances table
CREATE TABLE IF NOT EXISTS public.silak_allowances (
    id UUID PRIMARY KEY,
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    fuel_allowance_per_km NUMERIC(10, 2) DEFAULT 0.0,
    food_allowance_per_km NUMERIC(10, 2) DEFAULT 0.0,
    stay_allowance_per_km NUMERIC(10, 2) DEFAULT 0.0,
    other_allowance_per_km NUMERIC(10, 2) DEFAULT 0.0,
    other_allowance_description TEXT,
    total_fuel_allowance NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    total_food_allowance NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    total_stay_allowance NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    total_other_allowance NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    total_allowance NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Create diesel_records table
CREATE TABLE IF NOT EXISTS public.diesel_records (
    id UUID PRIMARY KEY,
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id),
    quantity NUMERIC(10, 2) NOT NULL,
    price_per_liter NUMERIC(10, 2) NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL,
    record_type TEXT NOT NULL CHECK (record_type IN ('initial', 'refill')),
    pump_partner_id UUID REFERENCES public.user_profiles(id),
    record_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Create trip_financial_reports table
CREATE TABLE IF NOT EXISTS public.trip_financial_reports (
    id UUID PRIMARY KEY,
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    trip_lr_number TEXT NOT NULL,
    from_location TEXT NOT NULL,
    to_location TEXT NOT NULL,
    distance_km NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    tonnage NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    rate_per_ton NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    total_revenue NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    commission_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    net_revenue NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    advance_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    expenses_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    silak_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    diesel_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    other_costs NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    total_expenses NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    profit_loss NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    profit_margin_percentage NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    trip_status TEXT NOT NULL,
    is_final BOOLEAN NOT NULL DEFAULT FALSE,
    report_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Set up RLS policies for silak_allowances
ALTER TABLE public.silak_allowances ENABLE ROW LEVEL SECURITY;

-- Trip managers can create and update silak allowances
CREATE POLICY silak_insert_policy ON public.silak_allowances
    FOR INSERT
    WITH CHECK (auth.role() IN ('tripManager', 'admin'));

CREATE POLICY silak_update_policy ON public.silak_allowances
    FOR UPDATE
    USING (auth.role() IN ('tripManager', 'admin'));

-- Trip managers, drivers, accountants, and admins can view silak allowances
CREATE POLICY silak_select_policy ON public.silak_allowances
    FOR SELECT
    USING (auth.role() IN ('tripManager', 'driver', 'accountant', 'admin'));

-- Only admins and trip managers can delete silak allowances
CREATE POLICY silak_delete_policy ON public.silak_allowances
    FOR DELETE
    USING (auth.role() IN ('tripManager', 'admin'));

-- Set up RLS policies for diesel_records
ALTER TABLE public.diesel_records ENABLE ROW LEVEL SECURITY;

-- Trip managers and pump partners can create diesel records
CREATE POLICY diesel_insert_policy ON public.diesel_records
    FOR INSERT
    WITH CHECK (auth.role() IN ('tripManager', 'pumpPartner', 'admin'));

-- Trip managers and pump partners can update their own diesel records
CREATE POLICY diesel_update_policy ON public.diesel_records
    FOR UPDATE
    USING (
        auth.role() IN ('admin') OR
        (auth.role() = 'tripManager') OR
        (auth.role() = 'pumpPartner' AND pump_partner_id = auth.uid())
    );

-- Trip managers, drivers, pump partners, accountants, and admins can view diesel records
CREATE POLICY diesel_select_policy ON public.diesel_records
    FOR SELECT
    USING (auth.role() IN ('tripManager', 'driver', 'pumpPartner', 'accountant', 'admin'));

-- Only admins and trip managers can delete diesel records
CREATE POLICY diesel_delete_policy ON public.diesel_records
    FOR DELETE
    USING (auth.role() IN ('tripManager', 'admin'));

-- Set up RLS policies for trip_financial_reports
ALTER TABLE public.trip_financial_reports ENABLE ROW LEVEL SECURITY;

-- Only accountants and admins can create financial reports
CREATE POLICY report_insert_policy ON public.trip_financial_reports
    FOR INSERT
    WITH CHECK (auth.role() IN ('accountant', 'admin'));

-- Only accountants and admins can update financial reports
CREATE POLICY report_update_policy ON public.trip_financial_reports
    FOR UPDATE
    USING (auth.role() IN ('accountant', 'admin'));

-- Only accountants and admins can view financial reports
CREATE POLICY report_select_policy ON public.trip_financial_reports
    FOR SELECT
    USING (auth.role() IN ('accountant', 'admin'));

-- Only admins can delete financial reports
CREATE POLICY report_delete_policy ON public.trip_financial_reports
    FOR DELETE
    USING (auth.role() = 'admin');
