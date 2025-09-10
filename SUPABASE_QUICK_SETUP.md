# 🚛 Supabase Quick Setup Guide

## ⚠️ Current Issue: 422 Error on Signup

The 422 error occurs because the Supabase database tables haven't been created yet. Here's how to fix it:

## 🔧 Quick Fix (2 Steps)

### Step 1: Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Sign up/Login
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - **Name**: `rv-fleet-management`
   - **Database Password**: Choose a strong password
   - **Region**: Choose closest to your location
6. Click "Create new project"
7. Wait for project to be ready (2-3 minutes)

### Step 2: Run Database Setup
1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy and paste the entire content from `supabase_setup_fixed.sql`
4. Click "Run" to execute the script
5. You should see "Success" message

### Step 3: Get Your Credentials
1. Go to **Settings** → **API**
2. Copy your **Project URL** and **anon public** key
3. Update `lib/constants/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'YOUR_PROJECT_URL';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   ```

## 🎯 What This Fixes

- ✅ **422 Error**: Database tables will exist
- ✅ **Username Auth**: Proper username/email authentication
- ✅ **User Profiles**: Complete user profile management
- ✅ **Vehicle Management**: Add/view vehicles and drivers
- ✅ **Role-based Access**: Different interfaces for each role

## 🚀 After Setup

1. **Test Signup**: Try creating a new account
2. **Test Login**: Sign in with your credentials
3. **Complete Profile**: Fill in your details
4. **Explore Dashboard**: Navigate through role-based features

## 📱 Current App Features

- **Splash Screen** → **Auth** → **Profile Setup** → **Role Dashboard**
- **Vehicle Management** (Admin/Traffic Manager)
- **Driver Management** (Admin/Traffic Manager)
- **Professional UI** with truck industry branding

## 🔄 Next Steps

After database setup, we can continue with:
- Trip Management System
- Diesel Tracking
- Expense Management
- Odometer Photo Upload
- Earnings Dashboard

---

**Need Help?** The app will work with basic authentication even without the database setup, but you'll get the 422 error on signup until the tables are created.
