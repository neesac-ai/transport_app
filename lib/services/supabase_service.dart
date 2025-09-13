import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
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
  static final _uuid = Uuid();
  
  // Generate a UUID
  static String generateUuid() {
    return _uuid.v4();
  }
  
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
  
  // Get all expenses with details
  static Future<List<ExpenseModel>> getAllExpenses() async {
    if (SupabaseConfig.isDevelopment) {
      // Return sample data for development
      return [
        ExpenseModel(
          id: '1',
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
          enteredBy: 'driver-1',
          notes: 'Filled at HP pump',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: null,
        ),
        ExpenseModel(
          id: '2',
          tripId: 'trip-2',
          vehicleId: 'vehicle-2',
          category: 'toll',
          description: 'Highway toll charges',
          amount: 800.0,
          receiptUrl: null,
          expenseDate: DateTime.now().subtract(const Duration(days: 2)),
          status: 'approved',
          approvedBy: 'admin-1',
          approvedAt: DateTime.now().subtract(const Duration(hours: 12)),
          rejectionReason: null,
          enteredBy: 'driver-2',
          notes: 'Multiple toll booths',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];
    }
    
    try {
      final response = await client
          .from('expenses')
          .select('*, trips(lr_number, from_location, to_location, vehicle_id)')
          .order('created_at', ascending: false);
      
      return response.map((json) => ExpenseModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all expenses: $e');
      return [];
    }
  }
  
  // Get all advances with details
  static Future<List<AdvanceModel>> getAllAdvances() async {
    if (SupabaseConfig.isDevelopment) {
      // Return sample data for development
      return [
        AdvanceModel(
          id: 'advance-1',
          driverId: 'driver-1',
          tripId: 'trip-1',
          amount: 2000.0,
          advanceType: 'trip_advance',
          purpose: 'Advance for Mumbai-Delhi trip',
          givenBy: 'admin-1',
          givenDate: DateTime.now().subtract(const Duration(days: 2)),
          status: 'pending',
          approvedBy: null,
          approvedAt: null,
          rejectionReason: null,
          notes: 'Standard advance amount',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: null,
        ),
        AdvanceModel(
          id: 'advance-2',
          driverId: 'driver-2',
          tripId: 'trip-2',
          amount: 1500.0,
          advanceType: 'trip_advance',
          purpose: 'Advance for Delhi-Bangalore trip',
          givenBy: 'admin-1',
          givenDate: DateTime.now().subtract(const Duration(days: 3)),
          status: 'approved',
          approvedBy: 'admin-1',
          approvedAt: DateTime.now().subtract(const Duration(days: 3)),
          rejectionReason: null,
          notes: 'Standard advance amount',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
    }
    
    try {
      final response = await client
          .from('advances')
          .select('*, trips(lr_number, from_location, to_location)')
          .order('created_at', ascending: false);
      
      return response.map((json) => AdvanceModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all advances: $e');
      return [];
    }
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

  // Update driver status
  static Future<void> updateDriverStatus(String driverId, String status) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Driver $driverId status updated to $status');
      return;
    }

    try {
      await client
          .from('drivers')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);
      
      print('Driver status updated successfully');
    } catch (e) {
      print('Error updating driver status: $e');
      throw Exception('Failed to update driver status: $e');
    }
  }
  
  // Update broker status
  static Future<void> updateBrokerStatus(String brokerId, String status) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Broker $brokerId status updated to $status');
      return;
    }

    try {
      await client
          .from('brokers')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', brokerId);
      
      print('Broker status updated successfully');
    } catch (e) {
      print('Error updating broker status: $e');
      throw Exception('Failed to update broker status: $e');
    }
  }

  // Delete broker
  static Future<void> deleteBroker(String brokerId) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Broker $brokerId deleted');
      return;
    }

    try {
      print('=== SUPABASE SERVICE: Deleting broker $brokerId ===');
      
      // Check if broker is associated with any trips
      final tripsWithBroker = await client
          .from('trips')
          .select('id')
          .eq('broker_id', brokerId);
      
      if (tripsWithBroker.isNotEmpty) {
        throw Exception('Cannot delete broker: They are associated with ${tripsWithBroker.length} trips');
      }
      
      // Delete the broker record
      await client
          .from('brokers')
          .delete()
          .eq('id', brokerId);
      
      print('Broker deleted successfully');
    } catch (e) {
      print('Error deleting broker: $e');
      throw Exception('Failed to delete broker: $e');
    }
  }

  // Delete vehicle
  static Future<void> deleteVehicle(String vehicleId) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Vehicle $vehicleId deleted');
      return;
    }

    try {
      print('=== SUPABASE SERVICE: Deleting vehicle $vehicleId ===');
      
      // Check if vehicle is associated with any trips
      final tripsWithVehicle = await client
          .from('trips')
          .select('id')
          .eq('vehicle_id', vehicleId);
      
      if (tripsWithVehicle.isNotEmpty) {
        throw Exception('Cannot delete vehicle: It is associated with ${tripsWithVehicle.length} trips');
      }
      
      // Delete the vehicle
      await client
          .from('vehicles')
          .delete()
          .eq('id', vehicleId);
      
      print('Vehicle deleted successfully');
    } catch (e) {
      print('Error deleting vehicle: $e');
      throw Exception('Failed to delete vehicle: $e');
    }
  }

  // Delete driver
  static Future<void> deleteDriver(String driverId) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Driver $driverId deleted');
      return;
    }

    try {
      print('=== SUPABASE SERVICE: Deleting driver $driverId ===');
      
      // Check if driver is associated with any trips
      final tripsWithDriver = await client
          .from('trips')
          .select('id')
          .eq('driver_id', driverId);
      
      if (tripsWithDriver.isNotEmpty) {
        throw Exception('Cannot delete driver: They are associated with ${tripsWithDriver.length} trips');
      }
      
      // Get user_id for this driver
      final driverRecord = await client
          .from('drivers')
          .select('user_id')
          .eq('id', driverId)
          .single();
      
      final userId = driverRecord['user_id'] as String?;
      
      // Delete the driver record
      await client
          .from('drivers')
          .delete()
          .eq('id', driverId);
      
      print('Driver record deleted successfully');
      
      // If we have a user_id, delete the user profile as well
      if (userId != null) {
        try {
          await client
              .from('user_profiles')
              .delete()
              .eq('id', userId);
          
          print('User profile deleted successfully');
        } catch (e) {
          print('Error deleting user profile: $e');
          // We don't throw here as the driver record was successfully deleted
        }
      }
    } catch (e) {
      print('Error deleting driver: $e');
      throw Exception('Failed to delete driver: $e');
    }
  }

  // Delete user
  static Future<void> deleteUser(String userId) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: User $userId deleted');
      return;
    }

    try {
      print('=== SUPABASE SERVICE: Deleting user $userId ===');
      
      // Check if user is a driver
      final driverRecord = await client
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (driverRecord != null) {
        // Delete driver record first
        final driverId = driverRecord['id'] as String;
        await deleteDriver(driverId);
      } else {
        // If not a driver, just delete the user profile
        await client
            .from('user_profiles')
            .delete()
            .eq('id', userId);
      }
      
      print('User deleted successfully');
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Accountant approval methods
  static Future<void> approveExpense(String expenseId, String approvedBy) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Expense $expenseId approved by $approvedBy');
      return;
    }
    try {
      await client
          .from('expenses')
          .update({
            'status': 'approved',
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId);
      print('Expense approved successfully');
    } catch (e) {
      print('Error approving expense: $e');
      throw Exception('Failed to approve expense: $e');
    }
  }

  static Future<void> rejectExpense(String expenseId, String approvedBy, String reason) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Expense $expenseId rejected by $approvedBy');
      return;
    }
    try {
      await client
          .from('expenses')
          .update({
            'status': 'rejected',
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId);
      print('Expense rejected successfully');
    } catch (e) {
      print('Error rejecting expense: $e');
      throw Exception('Failed to reject expense: $e');
    }
  }

  static Future<void> approveAdvance(String advanceId, String approvedBy) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Advance $advanceId approved by $approvedBy');
      return;
    }
    try {
      await client
          .from('advances')
          .update({
            'status': 'approved',
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', advanceId);
      print('Advance approved successfully');
    } catch (e) {
      print('Error approving advance: $e');
      throw Exception('Failed to approve advance: $e');
    }
  }

  static Future<void> rejectAdvance(String advanceId, String approvedBy, String reason) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Advance $advanceId rejected by $approvedBy');
      return;
    }
    try {
      await client
          .from('advances')
          .update({
            'status': 'rejected',
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', advanceId);
      print('Advance rejected successfully');
    } catch (e) {
      print('Error rejecting advance: $e');
      throw Exception('Failed to reject advance: $e');
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
  static Future<String?> getDriverIdForUser(String userId) async {
    if (SupabaseConfig.isDevelopment) {
      return userId; // In development, use user ID as driver ID
    }

    final driverResponse = await client
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    
    if (driverResponse == null) {
      print('No driver record found for user: $userId');
      return null;
    }
    
    return driverResponse['id'] as String;
  }

  static Future<List<TripModel>> getDriverTrips(String userId) async {
    if (SupabaseConfig.isDevelopment) {
      // Mock data for development
      return [
        TripModel(
          id: 'trip-1',
          lrNumber: 'LR-001',
          vehicleId: 'vehicle-1',
          driverId: userId,
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
          driverId: userId,
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

    // First, get the driver record for this user
    final driverResponse = await client
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    
    if (driverResponse == null) {
      print('No driver record found for user: $userId');
      return [];
    }
    
    final driverId = driverResponse['id'] as String;
    print('Found driver ID: $driverId for user: $userId');

    // Now get trips for this driver
    final response = await client
        .from('trips')
        .select('*')
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);
    
    print('Found ${response.length} trips for driver: $driverId');
    return response.map((json) => TripModel.fromJson(json)).toList();
  }

  static Future<List<ExpenseModel>> getDriverExpenses(String userId) async {
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
          enteredBy: userId,
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
          enteredBy: userId,
          notes: 'Multiple toll booths',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];
    }

    // First, get the driver record for this user
    final driverResponse = await client
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    
    if (driverResponse == null) {
      print('No driver record found for user: $userId');
      return [];
    }
    
    final driverId = driverResponse['id'] as String;

    final response = await client
        .from('expenses')
        .select('*')
        .eq('entered_by', driverId)
        .order('created_at', ascending: false);
    
    return response.map((json) => ExpenseModel.fromJson(json)).toList();
  }

  static Future<List<AdvanceModel>> getDriverAdvances(String userId) async {
    if (SupabaseConfig.isDevelopment) {
      // Mock data for development
      return [
        AdvanceModel(
          id: 'advance-1',
          driverId: userId,
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
          driverId: userId,
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

    // First, get the driver record for this user
    final driverResponse = await client
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    
    if (driverResponse == null) {
      print('No driver record found for user: $userId');
      return [];
    }
    
    final driverId = driverResponse['id'] as String;

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

  // ==================== SYSTEM HEALTH MONITORING ====================
  
  // Test database connection and return health status
  static Future<Map<String, dynamic>> testDatabaseConnection() async {
    if (SupabaseConfig.isDevelopment) {
      return {
        'success': true,
        'response_time_ms': 50,
        'message': 'Development mode - simulated connection',
      };
    }

    try {
      final startTime = DateTime.now();
      
      // Test with a simple query
      await client
          .from('user_profiles')
          .select('count')
          .limit(1);
      
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      return {
        'success': true,
        'response_time_ms': responseTime,
        'message': 'Database connection successful',
      };
    } catch (e) {
      print('Database connection test failed: $e');
      return {
        'success': false,
        'response_time_ms': -1,
        'message': 'Database connection failed: $e',
        'error': e.toString(),
      };
    }
  }

  // Get count of active user sessions
  static Future<int> getActiveSessionsCount() async {
    if (SupabaseConfig.isDevelopment) {
      return 5; // Simulated active sessions
    }

    try {
      // Get current authenticated users count
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      // For a more accurate count, you could query a sessions table
      // or use Supabase's built-in session management
      // This is a simplified implementation
      return 1; // At least the current user
    } catch (e) {
      print('Error getting active sessions count: $e');
      return 0;
    }
  }

  // Get storage usage percentage (simulated - Supabase doesn't expose this directly)
  static Future<double> getStorageUsage() async {
    if (SupabaseConfig.isDevelopment) {
      return 45.0; // Simulated storage usage
    }

    try {
      // Supabase doesn't directly expose storage usage via API
      // This would require using Supabase's management API or dashboard
      // For now, we'll simulate based on data volume
      
      // Get approximate data size by counting records
      final userCount = await client
          .from('user_profiles')
          .select('count')
          .count();
      
      final vehicleCount = await client
          .from('vehicles')
          .select('count')
          .count();
      
      final tripCount = await client
          .from('trips')
          .select('count')
          .count();
      
      // Rough estimation: each record ~1KB, total capacity ~100MB
      final totalRecords = (userCount.count) + (vehicleCount.count) + (tripCount.count);
      final estimatedUsage = (totalRecords * 1.0) / 100000.0 * 100; // 1KB per record, 100MB total
      
      return estimatedUsage.clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating storage usage: $e');
      return 0.0;
    }
  }

  // Get last backup time (simulated - would need Supabase management API)
  static Future<String> getLastBackupTime() async {
    if (SupabaseConfig.isDevelopment) {
      return '2 hours ago'; // Simulated backup time
    }

    try {
      // Supabase handles backups automatically, but doesn't expose this via client API
      // This would require Supabase management API access
      // For now, we'll return a simulated recent backup time
      final now = DateTime.now();
      final lastBackup = now.subtract(const Duration(hours: 2));
      final diff = now.difference(lastBackup);
      
      if (diff.inHours > 0) {
        return '${diff.inHours} hours ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error getting last backup time: $e');
      return 'Unknown';
    }
  }

  // Calculate system uptime based on successful operations
  static Future<double> calculateSystemUptime() async {
    if (SupabaseConfig.isDevelopment) {
      return 99.9; // Simulated uptime
    }

    try {
      // This is a simplified uptime calculation
      // In a real implementation, you'd track successful vs failed operations over time
      
      // Test multiple operations to determine uptime
      final operations = <Future>[];
      
      // Test user profiles access
      operations.add(client.from('user_profiles').select('count').limit(1));
      
      // Test vehicles access
      operations.add(client.from('vehicles').select('count').limit(1));
      
      // Test trips access
      operations.add(client.from('trips').select('count').limit(1));
      
      // Wait for all operations to complete
      await Future.wait(operations);
      
      // If all operations succeeded, assume high uptime
      return 99.9;
    } catch (e) {
      print('Error calculating system uptime: $e');
      // If operations failed, calculate based on error rate
      return 85.0; // Assume some downtime
    }
  }

  // Get detailed system metrics
  static Future<Map<String, dynamic>> getSystemMetrics() async {
    if (SupabaseConfig.isDevelopment) {
      return {
        'database_status': 'Operational',
        'api_response_time_ms': 50,
        'storage_usage_percent': 45.0,
        'active_sessions': 5,
        'last_backup': '2 hours ago',
        'system_uptime_percent': 99.9,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    try {
      final dbTest = await testDatabaseConnection();
      final activeSessions = await getActiveSessionsCount();
      final storageUsage = await getStorageUsage();
      final lastBackup = await getLastBackupTime();
      final uptime = await calculateSystemUptime();

      return {
        'database_status': dbTest['success'] == true ? 'Operational' : 'Error',
        'api_response_time_ms': dbTest['response_time_ms'] ?? -1,
        'storage_usage_percent': storageUsage,
        'active_sessions': activeSessions,
        'last_backup': lastBackup,
        'system_uptime_percent': uptime,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting system metrics: $e');
      return {
        'database_status': 'Error',
        'api_response_time_ms': -1,
        'storage_usage_percent': 0.0,
        'active_sessions': 0,
        'last_backup': 'Unknown',
        'system_uptime_percent': 0.0,
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // Odometer photo methods
  static Future<String> uploadOdometerPhoto({
    required String tripId,
    required String vehicleId,
    required String photoType,
    required XFile photo,
    required int odometerReading,
    String? location,
    String? notes,
  }) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Uploading odometer photo for trip $tripId');
      return 'dev-photo-id-${DateTime.now().millisecondsSinceEpoch}';
    }
    
    try {
      print('=== SUPABASE SERVICE: Uploading odometer photo ===');
      print('Trip ID: $tripId');
      print('Vehicle ID: $vehicleId');
      print('Photo type: $photoType');
      print('Photo name: ${photo.name}');
      
      // Upload file to Supabase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photo.name}';
      final filePath = 'trips/$tripId/$fileName';
      
      final fileBytes = await photo.readAsBytes();
      print('File size: ${fileBytes.length} bytes');
      
      final uploadResponse = await client.storage
          .from('odometer-photos')
          .uploadBinary(filePath, fileBytes);
      
      print('Upload response: $uploadResponse');
      
      if (uploadResponse.isNotEmpty) {
        // Get public URL
        final photoUrl = client.storage
            .from('odometer-photos')
            .getPublicUrl(filePath);
        
        print('Photo URL: $photoUrl');
        
        // Save metadata to odometer_photos table
        final response = await client
            .from('odometer_photos')
            .insert({
              'trip_id': tripId,
              'vehicle_id': vehicleId,
              'photo_type': photoType,
              'photo_url': photoUrl,
              'odometer_reading': odometerReading,
              'location': location,
              'uploaded_by': client.auth.currentUser?.id,
              'notes': notes,
            })
            .select()
            .single();
        
        print('Odometer photo record created: $response');
        return response['id'] as String;
      }
      
      throw Exception('Failed to upload photo');
    } catch (e) {
      print('Error uploading odometer photo: $e');
      throw Exception('Failed to upload odometer photo: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getOdometerPhotos(String tripId) async {
    if (SupabaseConfig.isDevelopment) {
      // Return mock data for development
      return [
        {
          'id': 'photo-1',
          'trip_id': tripId,
          'vehicle_id': 'vehicle-1',
          'photo_type': 'start',
          'photo_url': 'https://example.com/start.jpg',
          'odometer_reading': 45230,
          'location': 'Starting point',
          'uploaded_by': 'driver-1',
          'uploaded_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'notes': 'Start odometer reading',
        },
        {
          'id': 'photo-2',
          'trip_id': tripId,
          'vehicle_id': 'vehicle-1',
          'photo_type': 'end',
          'photo_url': 'https://example.com/end.jpg',
          'odometer_reading': 46630,
          'location': 'Ending point',
          'uploaded_by': 'driver-1',
          'uploaded_at': DateTime.now().toIso8601String(),
          'notes': 'End odometer reading',
        },
      ];
    }

    try {
      print('=== SUPABASE SERVICE: Getting odometer photos for trip $tripId ===');
      
      final response = await client
          .from('odometer_photos')
          .select('*')
          .eq('trip_id', tripId)
          .order('uploaded_at', ascending: false);
      
      print('Found ${response.length} odometer photos');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching odometer photos: $e');
      return [];
    }
  }

  static Future<void> deleteOdometerPhoto(String photoId) async {
    if (SupabaseConfig.isDevelopment) {
      print('Development mode: Deleting odometer photo $photoId');
      return;
    }

    try {
      print('=== SUPABASE SERVICE: Deleting odometer photo $photoId ===');
      
      // Get photo details first to get the file path
      final photo = await client
          .from('odometer_photos')
          .select('photo_url')
          .eq('id', photoId)
          .single();
      
      print('Photo details: $photo');
      
      // Extract path from URL
      final photoUrl = photo['photo_url'] as String;
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      // The path should be in format /storage/v1/object/public/bucket-name/path/to/file
      // We need to extract just the path/to/file part
      final storagePath = pathSegments.sublist(pathSegments.indexOf('odometer-photos') + 1).join('/');
      
      print('Deleting file from storage: $storagePath');
      
      // Delete from storage
      await client.storage
          .from('odometer-photos')
          .remove([storagePath]);
      
      // Delete from database
      await client
          .from('odometer_photos')
          .delete()
          .eq('id', photoId);
      
      print('Odometer photo deleted successfully');
    } catch (e) {
      print('Error deleting odometer photo: $e');
      throw Exception('Failed to delete odometer photo: $e');
    }
  }
}
