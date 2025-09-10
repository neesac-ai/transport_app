import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';
import '../models/user_model.dart';
import '../models/broker_model.dart';
import '../models/trip_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../models/expense_model.dart';
import '../models/advance_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    if (SupabaseConfig.isDevelopment) {
      // For development, we'll simulate Supabase functionality
      print('Supabase initialized in development mode');
      return;
    }
    
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    print('Supabase initialized with real project');
    
    // Handle auth state changes
    client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      print('Auth state changed: $event');
      if (session != null) {
        print('User authenticated: ${session.user.email}');
      } else {
        print('User signed out');
      }
    });
  }

  // Authentication methods
  static Future<AuthResponse?> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse?> signUpWithEmail(String email, String password) async {
    final authResponse = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': '',
        'phone_number': '',
        'address': '',
        'role': 'driver',
      },
    );

    // The handle_new_user trigger should automatically create the user profile
    // If it doesn't work, we'll create it manually
    if (authResponse.user != null) {
      try {
        // Wait a moment for the trigger to fire
        await Future.delayed(const Duration(seconds: 1));
        
        // Check if profile was created by trigger
        final existingProfile = await client
            .from(SupabaseConfig.userProfilesTable)
            .select()
            .eq('id', authResponse.user!.id)
            .maybeSingle();
        
        // If no profile exists, create it manually
        if (existingProfile == null) {
          await client
              .from(SupabaseConfig.userProfilesTable)
              .insert({
                'id': authResponse.user!.id,
                'username': null, // No username for email signup
                'email': email,
                'name': '',
                'phone_number': '',
                'address': '',
                'role': 'driver',
              });
        }
      } catch (e) {
        print('Error creating user profile: $e');
        // Don't throw here - user is still authenticated
      }
    }

    return authResponse;
  }

  // Removed signInWithUsername - using email-only authentication

  // Removed signUpWithUsername - using email-only authentication

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // User profile methods
  static Future<UserModel?> getUserProfile(String userId) async {
    if (SupabaseConfig.isDevelopment) {
      // Return null for development - user needs to complete profile
      return null;
    }
    
    try {
      final response = await client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('id', userId)
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null; // Return null if table doesn't exist or user not found
    }
  }

  static Future<UserModel> saveUserProfile(UserModel user) async {
    if (SupabaseConfig.isDevelopment) {
      // In development, just return the user
      return user;
    }
    
    try {
      print('=== SUPABASE SERVICE: Saving user profile ===');
      print('User data: ${user.toJson()}');
      print('Current user ID: ${client.auth.currentUser?.id}');
      print('Current user email: ${client.auth.currentUser?.email}');
      
      // First try to update existing profile
      print('Attempting to update existing profile...');
      final updateResponse = await client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'name': user.name,
            'phone_number': user.phoneNumber,
            'address': user.address,
            'role': user.role?.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id)
          .select()
          .maybeSingle();
      
      if (updateResponse != null) {
        print('Profile updated successfully: $updateResponse');
        return UserModel.fromJson(updateResponse);
      } else {
        // If update failed, try to insert
        print('Update failed, trying to insert new profile...');
        final insertResponse = await client
            .from(SupabaseConfig.userProfilesTable)
            .insert(user.toJson())
            .select()
            .single();
        
        print('Profile inserted successfully: $insertResponse');
        return UserModel.fromJson(insertResponse);
      }
    } catch (e) {
      print('=== SUPABASE SERVICE: Error saving user profile ===');
      print('Error details: $e');
      print('Error type: ${e.runtimeType}');
      // Return the user object even if save fails
      return user;
    }
  }

  // Vehicle management methods
  static Future<List<VehicleModel>> getVehicles() async {
    if (SupabaseConfig.isDevelopment) {
      // Return sample data for development - only active vehicles
      return [
        VehicleModel(
          id: '1',
          registrationNumber: 'KA01AB1234',
          vehicleType: 'Truck',
          capacity: '10 tons',
          driverId: 'driver1',
          status: 'active',
          createdAt: DateTime.now(),
        ),
        VehicleModel(
          id: '2',
          registrationNumber: 'KA02CD5678',
          vehicleType: 'Truck',
          capacity: '15 tons',
          driverId: 'driver2',
          status: 'active',
          createdAt: DateTime.now(),
        ),
        VehicleModel(
          id: '3',
          registrationNumber: 'KA03EF9012',
          vehicleType: 'Truck',
          capacity: '12 tons',
          driverId: null,
          status: 'active',
          createdAt: DateTime.now(),
        ),
      ];
    }
    
    // Only get active vehicles for trip assignment
    final response = await client
        .from('vehicles')
        .select()
        .eq('status', 'active')  // Only get active vehicles
        .order('created_at', ascending: false);
    
    return response.map((json) => VehicleModel.fromJson(json)).toList();
  }

  // Get all vehicles (for fleet management)
  static Future<List<VehicleModel>> getAllVehicles() async {
    print('=== SUPABASE SERVICE: Getting all vehicles ===');
    
    try {
      final response = await client
          .from('vehicles')
          .select()
          .order('created_at', ascending: false);
      
      print('Raw vehicles response: $response');
      
      final vehicles = response.map((json) => VehicleModel.fromJson(json)).toList();
      print('Parsed vehicles count: ${vehicles.length}');
      
      return vehicles;
    } catch (e) {
      print('Error getting all vehicles: $e');
      rethrow;
    }
  }

  // Trip management methods
  static Future<List<Map<String, dynamic>>> getTrips() async {
    if (SupabaseConfig.isDevelopment) {
      // Return sample data for development
      return [
        {
          'id': '1',
          'vehicle_id': '1',
          'driver_id': 'driver1',
          'broker_name': 'ABC Logistics',
          'from_location': 'Bangalore',
          'to_location': 'Mumbai',
          'tonnage': 10.0,
          'rate_per_ton': 5000.0,
          'status': 'in_progress',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
    }
    
    final response = await client
        .from('trips')
        .select()
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Diesel management methods
  static Future<List<Map<String, dynamic>>> getDieselRecords() async {
    if (SupabaseConfig.isDevelopment) {
      // Return sample data for development
      return [
        {
          'id': '1',
          'vehicle_id': '1',
          'amount': 5000.0,
          'liters': 100.0,
          'pump_name': 'HP Petrol Pump',
          'date': DateTime.now().toIso8601String(),
        },
      ];
    }
    
    final response = await client
        .from('diesel_records')
        .select()
        .order('date', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Expense management methods
  static Future<List<Map<String, dynamic>>> getExpenses() async {
    if (SupabaseConfig.isDevelopment) {
      // Return sample data for development
      return [
        {
          'id': '1',
          'trip_id': '1',
          'category': 'toll',
          'amount': 500.0,
          'description': 'Highway toll charges',
          'date': DateTime.now().toIso8601String(),
        },
      ];
    }
    
    final response = await client
        .from('expenses')
        .select()
        .order('date', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Vehicle management methods
  static Future<Map<String, dynamic>> saveVehicle(Map<String, dynamic> vehicleData) async {
    if (SupabaseConfig.isDevelopment) {
      // In development, just return the vehicle data with an ID
      return {
        ...vehicleData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'created_at': DateTime.now().toIso8601String(),
      };
    }
    
    final response = await client
        .from('vehicles')
        .insert(vehicleData)
        .select()
        .single();
    
    return response;
  }

  // Update vehicle status
  static Future<void> updateVehicleStatus(String vehicleId, String status) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Vehicle $vehicleId status updated to $status');
      return;
    }

    try {
      await client
          .from('vehicles')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vehicleId);
      
      print('Vehicle status updated successfully');
    } catch (e) {
      print('Error updating vehicle status: $e');
      throw Exception('Failed to update vehicle status: $e');
    }
  }

  // Driver management methods
  static Future<Map<String, dynamic>> saveDriver(Map<String, dynamic> driverData) async {
    if (SupabaseConfig.isDevelopment) {
      // In development, just return the driver data with an ID
      return {
        ...driverData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'created_at': DateTime.now().toIso8601String(),
      };
    }
    
    final response = await client
        .from('drivers')
        .insert(driverData)
        .select()
        .single();
    
    return response;
  }

  static Future<List<DriverModel>> getDrivers() async {
    if (SupabaseConfig.isDevelopment) {
      // Return sample data for development - only active drivers
      return [
        DriverModel(
          id: '1',
          name: 'Rajesh Kumar',
          phoneNumber: '+91 9876543210',
          email: 'rajesh@example.com',
          licenseNumber: 'DL123456789',
          status: 'active',
          address: 'Bangalore, Karnataka',
          createdAt: DateTime.now(),
        ),
        DriverModel(
          id: '3',
          name: 'Amit Patel',
          phoneNumber: '+91 9876543212',
          email: 'amit@example.com',
          licenseNumber: 'DL123456791',
          status: 'active',
          address: 'Delhi, NCR',
          createdAt: DateTime.now(),
        ),
      ];
    }
    
    print('=== SUPABASE SERVICE: Getting active drivers ===');
    
    // Check authentication status
    final currentUser = client.auth.currentUser;
    final currentSession = client.auth.currentSession;
    print('Current user: ${currentUser?.id}');
    print('Current session: ${currentSession != null ? "exists" : "null"}');
    print('User email: ${currentUser?.email}');
    
    try {
      // Try to get drivers first - without status filter to test
      print('Step 1: Getting all drivers (no filter)...');
      final allDriversResponse = await client
          .from('drivers')
          .select('id, user_id, license_number, status, created_at');
      
      print('All drivers response: $allDriversResponse');
      print('All drivers count: ${allDriversResponse.length}');
      
      // Now try with status filter
      print('Step 1b: Getting active drivers...');
      final driversResponse = await client
          .from('drivers')
          .select('id, user_id, license_number, status, created_at')
          .eq('status', 'active');
      
      print('Active drivers response: $driversResponse');
      print('Active drivers count: ${driversResponse.length}');
      
      if (driversResponse.isEmpty) {
        print('No drivers found with active status');
        return [];
      }
      
      // Now get user profiles for each driver
      print('Step 2: Getting user profiles...');
      final List<DriverModel> drivers = [];
      
      for (final driverData in driversResponse) {
        try {
          print('Getting profile for user_id: ${driverData['user_id']}');
          final userProfile = await client
              .from('user_profiles')
              .select('name, phone_number, email, address')
              .eq('id', driverData['user_id'])
              .maybeSingle();
          
          print('User profile for ${driverData['user_id']}: $userProfile');
          
          drivers.add(DriverModel(
            id: driverData['id'],
            name: userProfile?['name'] ?? 'Unknown Driver',
            phoneNumber: userProfile?['phone_number'] ?? '',
            email: userProfile?['email'] ?? '',
            licenseNumber: driverData['license_number'] ?? '',
            licenseExpiry: null,
            assignedVehicleId: null,
            status: driverData['status'],
            address: userProfile?['address'] ?? '',
            createdAt: DateTime.parse(driverData['created_at']),
            updatedAt: null,
          ));
        } catch (e) {
          print('Error getting profile for driver ${driverData['id']}: $e');
          // Add driver with minimal info
          drivers.add(DriverModel(
            id: driverData['id'],
            name: 'Driver ${driverData['license_number']}',
            phoneNumber: '',
            email: '',
            licenseNumber: driverData['license_number'] ?? '',
            licenseExpiry: null,
            assignedVehicleId: null,
            status: driverData['status'],
            address: '',
            createdAt: DateTime.parse(driverData['created_at']),
            updatedAt: null,
          ));
        }
      }
      
      print('Final drivers list: ${drivers.length} drivers');
      return drivers;
      
    } catch (e) {
      print('Error in getDrivers: $e');
      return [];
    }
  }

  // Get all drivers (for driver management)
  static Future<List<DriverModel>> getAllDrivers() async {
    print('=== SUPABASE SERVICE: Getting all drivers ===');
    
    try {
      final response = await client
          .from('drivers')
          .select('''
            id, user_id, license_number, status, created_at,
            user_profiles!inner(name, phone_number, email, address)
          ''')
          .order('created_at', ascending: false);
      
      print('Raw drivers response: $response');
      
      final drivers = response.map((json) {
        final userProfile = json['user_profiles'] as Map<String, dynamic>?;
        return DriverModel(
          id: json['id'],
          name: userProfile?['name'] ?? 'Unknown',
          phoneNumber: userProfile?['phone_number'],
          email: userProfile?['email'],
          licenseNumber: json['license_number'],
          status: json['status'] ?? 'active',
          address: userProfile?['address'],
          createdAt: DateTime.parse(json['created_at']),
        );
      }).toList();
      
      print('Parsed drivers count: ${drivers.length}');
      
      return drivers;
    } catch (e) {
      print('Error getting all drivers: $e');
      rethrow;
    }
  }

  // Save driver license details
  static Future<void> saveDriverLicense(String userId, String licenseNumber, DateTime expiryDate) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Driver license saved for user $userId');
      return;
    }

    try {
      print('=== SUPABASE SERVICE: Saving driver license ===');
      print('User ID: $userId');
      print('License Number: $licenseNumber');
      print('Expiry Date: $expiryDate');
      
      // Check if driver record already exists
      final existingDriver = await client
          .from('drivers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existingDriver != null) {
        // Update existing driver record
        await client
            .from('drivers')
            .update({
              'license_number': licenseNumber,
              'license_expiry': expiryDate.toIso8601String().split('T')[0], // Date only
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
        
        print('Driver license updated successfully');
      } else {
        // Create new driver record
        await client
            .from('drivers')
            .insert({
              'user_id': userId,
              'license_number': licenseNumber,
              'license_expiry': expiryDate.toIso8601String().split('T')[0], // Date only
              'status': 'active',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
        
        print('Driver license created successfully');
      }
    } catch (e) {
      print('Error saving driver license: $e');
      throw Exception('Failed to save driver license: $e');
    }
  }

  // Admin approval methods
  static Future<List<UserModel>> getPendingUsers() async {
    if (SupabaseConfig.isDevelopment) {
      return []; // Return empty list in development
    }

    try {
      final response = await client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('approval_status', 'pending')
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting pending users: $e');
      throw Exception('Failed to get pending users: $e');
    }
  }

  static Future<List<UserModel>> getAllUsers() async {
    if (SupabaseConfig.isDevelopment) {
      return [
        UserModel(
          id: '1',
          name: 'John Doe',
          phoneNumber: '+1234567890',
          email: 'john@example.com',
          address: '123 Main St',
          role: UserRole.driver,
          approvalStatus: ApprovalStatus.approved,
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: '2',
          name: 'Jane Smith',
          phoneNumber: '+1234567891',
          email: 'jane@example.com',
          address: '456 Oak Ave',
          role: UserRole.tripManager,
          approvalStatus: ApprovalStatus.pending,
          createdAt: DateTime.now(),
        ),
      ];
    }

    try {
      final response = await client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      throw Exception('Failed to get all users: $e');
    }
  }

  static Future<void> approveUser(String userId) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Skipping approval');
      return; // Do nothing in development
    }

    try {
      print('=== SUPABASE SERVICE: Approving user ===');
      print('User ID to approve: $userId');
      
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }
      
      print('Current admin user: ${currentUser.id}');

      final updateData = {
        'approval_status': 'approved',
        'approved_by': currentUser.id,
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('Update data: $updateData');

      // First, let's check if the user exists and get current status
      final userToApprove = await client
          .from(SupabaseConfig.userProfilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      print('User data before update: $userToApprove');

      final response = await client
          .from(SupabaseConfig.userProfilesTable)
          .update(updateData)
          .eq('id', userId)
          .select();
          
      print('Approval response: $response');
      
      if (response.isEmpty) {
        print('WARNING: No rows were updated!');
        throw Exception('No rows were updated - user might not exist or update failed');
      }
      
      print('User approved successfully');
    } catch (e) {
      print('Error approving user: $e');
      throw Exception('Failed to approve user: $e');
    }
  }

  static Future<void> rejectUser(String userId, String reason) async {
    if (SupabaseConfig.isDevelopment) {
      return; // Do nothing in development
    }

    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await client
          .from(SupabaseConfig.userProfilesTable)
          .update({
            'approval_status': 'rejected',
            'approved_by': currentUser.id,
            'approved_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Error rejecting user: $e');
      throw Exception('Failed to reject user: $e');
    }
  }

  // ==================== BROKER MANAGEMENT ====================
  
  // Get all brokers
  static Future<List<BrokerModel>> getBrokers() async {
    if (SupabaseConfig.isDevelopment) {
      // Return mock data for development
      return [
        BrokerModel(
          id: '1',
          name: 'Rajesh Kumar',
          company: 'RK Logistics',
          contactNumber: '+91-9876543210',
          email: 'rajesh@rklogistics.com',
          commissionRate: 5.0,
          status: 'active',
          createdAt: DateTime.now(),
        ),
        BrokerModel(
          id: '2',
          name: 'Priya Sharma',
          company: 'PS Transport',
          contactNumber: '+91-9876543211',
          email: 'priya@pstransport.com',
          commissionRate: 4.5,
          status: 'active',
          createdAt: DateTime.now(),
        ),
      ];
    }
    
    final response = await client
        .from('brokers')
        .select()
        .order('name');
    
    return response.map((json) => BrokerModel.fromJson(json)).toList();
  }

  // Create new broker
  static Future<BrokerModel> createBroker(BrokerModel broker) async {
    if (SupabaseConfig.isDevelopment) {
      return broker.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
      );
    }
    
    final response = await client
        .from('brokers')
        .insert(broker.toJson())
        .select()
        .single();
    
    return BrokerModel.fromJson(response);
  }

  // Create broker from Map (for foundation data setup)
  static Future<Map<String, dynamic>> createBrokerFromMap(Map<String, dynamic> brokerData) async {
    if (SupabaseConfig.isDevelopment) {
      return {
        ...brokerData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'created_at': DateTime.now().toIso8601String(),
      };
    }
    
    final response = await client
        .from('brokers')
        .insert(brokerData)
        .select()
        .single();
    
    return response;
  }

  // ==================== TRIP MANAGEMENT ====================
  
  // Get all trips
  static Future<List<TripModel>> getAllTrips() async {
    print('=== SUPABASE SERVICE: Getting all trips ===');
    print('Current user: ${client.auth.currentUser?.id}');
    print('Current user email: ${client.auth.currentUser?.email}');
    
    try {
      final response = await client
          .from('trips')
          .select()
          .order('created_at', ascending: false);
      
      print('Raw trips response: $response');
      
      final trips = response.map((json) => TripModel.fromJson(json)).toList();
      print('Parsed trips count: ${trips.length}');
      
      return trips;
    } catch (e) {
      print('Error getting all trips: $e');
      rethrow;
    }
  }

  // Create new trip
  static Future<TripModel> createTrip(TripModel trip) async {
    if (SupabaseConfig.isDevelopment) {
      return trip.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        lrNumber: 'LR-2024-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        createdAt: DateTime.now(),
      );
    }
    
    print('=== SUPABASE SERVICE: Creating trip ===');
    print('Trip data: ${trip.toJson()}');
    print('Current user: ${client.auth.currentUser?.id}');
    print('Current user email: ${client.auth.currentUser?.email}');
    
    try {
      // Create a copy of the JSON without the id field since database will auto-generate it
      final tripJson = trip.toJson();
      tripJson.remove('id');
      
      // Check for empty string UUIDs and convert them to null
      final fieldsToCheck = ['broker_id', 'assigned_by'];
      for (final field in fieldsToCheck) {
        if (tripJson[field] == '') {
          print('Converting empty string to null for field: $field');
          tripJson[field] = null;
        }
      }
      
      print('Trip JSON after cleanup: $tripJson');
      
      final response = await client
          .from('trips')
          .insert(tripJson)
          .select()
          .single();
      
      print('Trip created successfully: $response');
      return TripModel.fromJson(response);
    } catch (e) {
      print('=== SUPABASE SERVICE: Error creating trip ===');
      print('Error details: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Update trip status with proper date tracking
  static Future<TripModel> updateTripStatus(String tripId, String status) async {
    print('=== SUPABASE SERVICE: Updating trip status ===');
    print('Trip ID: $tripId');
    print('New status: $status');
    print('Current user: ${client.auth.currentUser?.id}');
    
    try {
      final currentTime = DateTime.now().toIso8601String();
      final currentUserId = client.auth.currentUser?.id;
      
      // Prepare update data based on status
      Map<String, dynamic> updateData = {
        'status': status,
        'updated_at': currentTime,
      };
      
      // Add specific date fields based on status
      switch (status) {
        case 'in_progress':
          updateData['start_date'] = currentTime;
          break;
        case 'completed':
          updateData['end_date'] = currentTime;
          break;
        case 'cancelled':
          updateData['cancelled_at'] = currentTime;
          break;
        case 'settled':
          updateData['settled_at'] = currentTime;
          break;
      }
      
      // Add assigned_by if not already set (for initial assignment)
      if (currentUserId != null) {
        updateData['assigned_by'] = currentUserId;
      }
      
      print('Update data: $updateData');
      
      final response = await client
          .from('trips')
          .update(updateData)
          .eq('id', tripId)
          .select()
          .single();
      
      print('Trip status update response: $response');
      
      return TripModel.fromJson(response);
    } catch (e) {
      print('Error updating trip status: $e');
      rethrow;
    }
  }

  // Driver-specific methods
  static Future<List<TripModel>> getDriverTrips(String driverId) async {
    if (SupabaseConfig.isDevelopment) {
      // Mock data for development
      return [
        TripModel(
          id: 'trip-1',
          lrNumber: 'LR-001',
          vehicleId: 'vehicle-1',
          driverId: driverId,
          brokerId: 'broker-1',
          assignedBy: 'admin-1',
          fromLocation: 'Mumbai',
          toLocation: 'Delhi',
          distanceKm: 1400.0,
          tonnage: 20.0,
          ratePerTon: 500.0,
          totalRate: 10000.0,
          commissionAmount: 500.0,
          advanceGiven: 2000.0,
          dieselIssued: 3000.0,
          silakAmount: 0.0,
          status: 'assigned',
          startDate: null,
          endDate: null,
          notes: 'Urgent delivery',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: null,
        ),
        TripModel(
          id: 'trip-2',
          lrNumber: 'LR-002',
          vehicleId: 'vehicle-2',
          driverId: driverId,
          brokerId: 'broker-2',
          assignedBy: 'admin-1',
          fromLocation: 'Delhi',
          toLocation: 'Bangalore',
          distanceKm: 2100.0,
          tonnage: 15.0,
          ratePerTon: 600.0,
          totalRate: 9000.0,
          commissionAmount: 450.0,
          advanceGiven: 1500.0,
          dieselIssued: 2500.0,
          silakAmount: 0.0,
          status: 'completed',
          startDate: DateTime.now().subtract(const Duration(days: 3)),
          endDate: DateTime.now().subtract(const Duration(days: 1)),
          notes: 'Completed successfully',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    }

    final response = await client
        .from('trips')
        .select('*')
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);
    
    return response.map((json) => TripModel.fromJson(json)).toList();
  }

  static Future<List<ExpenseModel>> getDriverExpenses(String driverId) async {
    if (SupabaseConfig.isDevelopment) {
      // Mock data for development
      return [
        ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-1',
          vehicleId: 'vehicle-1',
          category: 'fuel',
          description: 'Diesel for Mumbai-Delhi trip',
          amount: 2500.0,
          receiptUrl: null,
          expenseDate: DateTime.now().subtract(const Duration(days: 1)),
          status: 'pending',
          approvedBy: null,
          approvedAt: null,
          rejectionReason: null,
          enteredBy: driverId,
          notes: 'Filled at HP pump',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: null,
        ),
        ExpenseModel(
          id: 'expense-2',
          tripId: null,
          vehicleId: null,
          category: 'toll',
          description: 'Highway toll charges',
          amount: 800.0,
          receiptUrl: null,
          expenseDate: DateTime.now().subtract(const Duration(days: 2)),
          status: 'approved',
          approvedBy: 'admin-1',
          approvedAt: DateTime.now().subtract(const Duration(hours: 12)),
          rejectionReason: null,
          enteredBy: driverId,
          notes: 'Multiple toll booths',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];
    }

    final response = await client
        .from('expenses')
        .select('*')
        .eq('entered_by', driverId)
        .order('created_at', ascending: false);
    
    return response.map((json) => ExpenseModel.fromJson(json)).toList();
  }

  static Future<List<AdvanceModel>> getDriverAdvances(String driverId) async {
    if (SupabaseConfig.isDevelopment) {
      // Mock data for development
      return [
        AdvanceModel(
          id: 'advance-1',
          driverId: driverId,
          tripId: 'trip-1',
          amount: 2000.0,
          advanceType: 'trip_advance',
          purpose: 'Advance for Mumbai-Delhi trip',
          givenBy: 'admin-1',
          givenDate: DateTime.now().subtract(const Duration(days: 2)),
          status: 'approved',
          approvedBy: 'admin-1',
          approvedAt: DateTime.now().subtract(const Duration(days: 2)),
          rejectionReason: null,
          notes: 'Standard advance amount',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        AdvanceModel(
          id: 'advance-2',
          driverId: driverId,
          tripId: null,
          amount: 1000.0,
          advanceType: 'general_advance',
          purpose: 'Emergency advance for vehicle maintenance',
          givenBy: 'admin-1',
          givenDate: DateTime.now().subtract(const Duration(days: 5)),
          status: 'pending',
          approvedBy: null,
          approvedAt: null,
          rejectionReason: null,
          notes: 'Vehicle needs immediate repair',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: null,
        ),
      ];
    }

    final response = await client
        .from('advances')
        .select('*')
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);
    
    return response.map((json) => AdvanceModel.fromJson(json)).toList();
  }

  static Future<void> createExpense(ExpenseModel expense) async {
    if (SupabaseConfig.isDevelopment) {
      print('Creating expense in development mode: ${expense.description}');
      return;
    }

    try {
      // Create a copy of the JSON without the id field since database will auto-generate it
      final expenseJson = expense.toJson();
      expenseJson.remove('id');
      await client.from('expenses').insert(expenseJson);
    } catch (e) {
      print('Error creating expense: $e');
      // In development, we'll just log the error and continue
      if (SupabaseConfig.isDevelopment) {
        return;
      }
      rethrow;
    }
  }

  static Future<void> createAdvance(AdvanceModel advance) async {
    if (SupabaseConfig.isDevelopment) {
      print('Creating advance in development mode: ${advance.amount}');
      return;
    }

    try {
      // Create a copy of the JSON without the id field since database will auto-generate it
      final advanceJson = advance.toJson();
      advanceJson.remove('id');
      await client.from('advances').insert(advanceJson);
    } catch (e) {
      print('Error creating advance: $e');
      // In development, we'll just log the error and continue
      if (SupabaseConfig.isDevelopment) {
        return;
      }
      rethrow;
    }
  }
}
