// SUPABASE CONFIGURATION TEMPLATE
// 
// INSTRUCTIONS:
// 1. Create your Supabase project at https://supabase.com
// 2. Go to Settings → API in your Supabase dashboard
// 3. Copy your Project URL and Anon Key
// 4. Replace the placeholder values below
// 5. Rename this file to 'supabase_config.dart' (remove '_template')
// 6. Set isDevelopment to false

class SupabaseConfig {
  // TODO: Replace with your actual Supabase project URL
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  
  // TODO: Replace with your actual Supabase anon key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  // Set to false when you have real Supabase credentials
  static const bool isDevelopment = true;
  
  // Database table names
  static const String userProfilesTable = 'user_profiles';
  static const String vehiclesTable = 'vehicles';
  static const String driversTable = 'drivers';
  static const String brokersTable = 'brokers';
  static const String tripsTable = 'trips';
  static const String dieselRecordsTable = 'diesel_records';
  static const String expensesTable = 'expenses';
  static const String odometerPhotosTable = 'odometer_photos';
}
