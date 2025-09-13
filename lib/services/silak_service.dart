import 'package:version1/models/silak_model.dart';
import 'package:version1/services/supabase_service.dart';

class SilakService {
  // Create a new silak record
  static Future<SilakModel> createSilak({
    required String tripId,
    required double distanceKm,
    required double fuelAllowancePerKm,
    required double foodAllowancePerKm,
    required double stayAllowancePerKm,
    required double otherAllowancePerKm,
    String? otherAllowanceDescription,
  }) async {
    try {
      // Generate a UUID for the new silak record
      final id = SupabaseService.generateUuid();
      
      // Calculate the silak allowances based on distance
      final silakModel = SilakModel.calculate(
        id: id,
        tripId: tripId,
        distanceKm: distanceKm,
        fuelAllowancePerKm: fuelAllowancePerKm,
        foodAllowancePerKm: foodAllowancePerKm,
        stayAllowancePerKm: stayAllowancePerKm,
        otherAllowancePerKm: otherAllowancePerKm,
        otherAllowanceDescription: otherAllowanceDescription,
      );
      
      // Save to Supabase
      final response = await SupabaseService.client
          .from('silak_allowances')
          .insert(silakModel.toJson())
          .select()
          .single();
      
      // Update the trip's silak amount
      await SupabaseService.client
          .from('trips')
          .update({
            'silak_amount': silakModel.totalAllowance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);
      
      return SilakModel.fromJson(response);
    } catch (e) {
      print('Error creating silak record: $e');
      throw Exception('Failed to create silak record: $e');
    }
  }

  // Get silak record for a trip
  static Future<SilakModel?> getSilakForTrip(String tripId) async {
    try {
      final response = await SupabaseService.client
          .from('silak_allowances')
          .select()
          .eq('trip_id', tripId)
          .maybeSingle();
      
      if (response != null) {
        return SilakModel.fromJson(response);
      }
      
      return null;
    } catch (e) {
      print('Error getting silak record: $e');
      throw Exception('Failed to get silak record: $e');
    }
  }

  // Update silak record
  static Future<SilakModel> updateSilak({
    required String id,
    required String tripId,
    required double distanceKm,
    required double fuelAllowancePerKm,
    required double foodAllowancePerKm,
    required double stayAllowancePerKm,
    required double otherAllowancePerKm,
    String? otherAllowanceDescription,
  }) async {
    try {
      // Calculate the updated silak allowances
      final silakModel = SilakModel.calculate(
        id: id,
        tripId: tripId,
        distanceKm: distanceKm,
        fuelAllowancePerKm: fuelAllowancePerKm,
        foodAllowancePerKm: foodAllowancePerKm,
        stayAllowancePerKm: stayAllowancePerKm,
        otherAllowancePerKm: otherAllowancePerKm,
        otherAllowanceDescription: otherAllowanceDescription,
      );
      
      // Update in Supabase
      final response = await SupabaseService.client
          .from('silak_allowances')
          .update({
            'fuel_allowance_per_km': fuelAllowancePerKm,
            'food_allowance_per_km': foodAllowancePerKm,
            'stay_allowance_per_km': stayAllowancePerKm,
            'other_allowance_per_km': otherAllowancePerKm,
            'other_allowance_description': otherAllowanceDescription,
            'total_fuel_allowance': silakModel.totalFuelAllowance,
            'total_food_allowance': silakModel.totalFoodAllowance,
            'total_stay_allowance': silakModel.totalStayAllowance,
            'total_other_allowance': silakModel.totalOtherAllowance,
            'total_allowance': silakModel.totalAllowance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      
      // Update the trip's silak amount
      await SupabaseService.client
          .from('trips')
          .update({
            'silak_amount': silakModel.totalAllowance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);
      
      return SilakModel.fromJson(response);
    } catch (e) {
      print('Error updating silak record: $e');
      throw Exception('Failed to update silak record: $e');
    }
  }

  // Delete silak record
  static Future<void> deleteSilak(String id, String tripId) async {
    try {
      await SupabaseService.client
          .from('silak_allowances')
          .delete()
          .eq('id', id);
      
      // Update the trip's silak amount to 0
      await SupabaseService.client
          .from('trips')
          .update({
            'silak_amount': 0.0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);
    } catch (e) {
      print('Error deleting silak record: $e');
      throw Exception('Failed to delete silak record: $e');
    }
  }
}

