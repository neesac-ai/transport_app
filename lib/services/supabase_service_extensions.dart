import 'package:version1/models/expense_model.dart';
import 'package:version1/models/advance_model.dart';
import 'package:version1/services/supabase_service.dart';

extension TripFinancialExtensions on SupabaseService {
  // Get expenses for a specific trip
  static Future<List<ExpenseModel>> getExpensesForTrip(String tripId) async {
    try {
      final response = await SupabaseService.client
          .from('expenses')
          .select()
          .eq('trip_id', tripId);
      
      return response.map<ExpenseModel>((json) => ExpenseModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting expenses for trip: $e');
      return [];
    }
  }

  // Get advances for a specific trip
  static Future<List<AdvanceModel>> getAdvancesForTrip(String tripId) async {
    try {
      final response = await SupabaseService.client
          .from('advances')
          .select()
          .eq('trip_id', tripId);
      
      return response.map<AdvanceModel>((json) => AdvanceModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting advances for trip: $e');
      return [];
    }
  }
}

