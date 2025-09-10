class SupabaseConfig {
  // TODO: Replace with your actual Supabase project URL and anon key
  // Get these from: https://supabase.com → Your Project → Settings → API
  static const String supabaseUrl = 'https://jtulzwltuqcfgdmlzlgz.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_GbbN7jmCSXK2IetrFJNCDA_ixxcSPFM';
  
  // PRODUCTION MODE: Using real Supabase with username/email authentication
  static const bool isDevelopment = false;
  
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
