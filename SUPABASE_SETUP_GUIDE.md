# 🚀 Supabase Setup Guide for RV Truck Fleet Management

## Step 1: Create Supabase Project

1. **Visit Supabase**: Go to [https://supabase.com](https://supabase.com)
2. **Sign up/Login**: Create an account or login with GitHub/Google
3. **Create New Project**:
   - Click "New Project"
   - **Organization**: Select or create one
   - **Project Name**: `rv-truck-fleet-management`
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to your location
   - Click "Create new project"

## Step 2: Get Project Credentials

1. **Go to Settings** → **API** in your Supabase dashboard
2. **Copy these values**:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon/Public Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## Step 3: Setup Database

1. **Go to SQL Editor** in your Supabase dashboard
2. **Copy and paste** the contents of `supabase_setup.sql` file
3. **Click "Run"** to create all tables and policies

## Step 4: Configure Flutter App

1. **Copy** `lib/constants/supabase_config_template.dart`
2. **Rename** it to `lib/constants/supabase_config.dart`
3. **Replace** the placeholder values:
   ```dart
   static const String supabaseUrl = 'YOUR_ACTUAL_PROJECT_URL';
   static const String supabaseAnonKey = 'YOUR_ACTUAL_ANON_KEY';
   static const bool isDevelopment = false;
   ```

## Step 5: Enable Phone Authentication

1. **Go to Authentication** → **Settings** in Supabase dashboard
2. **Enable Phone Auth**:
   - Toggle "Enable phone confirmations"
   - Configure SMS provider (Twilio recommended)
3. **Add your phone number** for testing

## Step 6: Test the Integration

1. **Run the Flutter app**: `flutter run -d chrome`
2. **Test phone authentication** with your registered number
3. **Verify data** is being saved to Supabase tables

## Database Tables Created

- ✅ `user_profiles` - User information and roles
- ✅ `vehicles` - Fleet vehicle management
- ✅ `drivers` - Driver information and assignments
- ✅ `brokers` - Broker/Client information
- ✅ `trips` - Trip management and tracking
- ✅ `diesel_records` - Fuel consumption tracking
- ✅ `expenses` - Expense management
- ✅ `odometer_photos` - Odometer photo storage

## Security Features

- ✅ Row Level Security (RLS) enabled
- ✅ Role-based access control
- ✅ User can only access their own data
- ✅ Admin/Traffic Manager have full access

## Next Steps

After setup:
1. Test authentication flow
2. Add sample data through the app
3. Verify data appears in Supabase dashboard
4. Configure SMS provider for production
5. Set up storage for file uploads (photos, receipts)

## Troubleshooting

**Common Issues**:
- **Phone auth not working**: Check SMS provider configuration
- **Database errors**: Verify SQL script ran successfully
- **Permission errors**: Check RLS policies
- **Connection issues**: Verify URL and API key

**Need Help?**
- Check Supabase documentation: https://supabase.com/docs
- Flutter Supabase guide: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter



