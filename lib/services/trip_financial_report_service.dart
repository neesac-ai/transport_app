import 'package:version1/models/trip_financial_report_model.dart';
import 'package:version1/models/trip_model.dart';
import 'package:version1/services/supabase_service.dart';
import 'package:version1/services/supabase_service_extensions.dart';
import 'package:version1/services/diesel_service.dart';

class TripFinancialReportService {
  // Generate a financial report for a trip
  static Future<TripFinancialReportModel> generateFinancialReport({
    required TripModel trip,
    required bool isFinal,
  }) async {
    try {
      // Generate a UUID for the new report
      final id = SupabaseService.generateUuid();
      
      // Get all expenses for the trip
      final expenses = await TripFinancialExtensions.getExpensesForTrip(trip.id);
      final totalExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      
      // Get all advances for the trip
      final advances = await TripFinancialExtensions.getAdvancesForTrip(trip.id);
      final totalAdvances = advances.fold(0.0, (sum, advance) => sum + advance.amount);
      
      // Get total diesel cost
      final totalDieselCost = await DieselService.getTotalDieselCostForTrip(trip.id);
      
      // Calculate total revenue and net revenue
      final totalRevenue = trip.calculatedTotalRate;
      final netRevenue = totalRevenue - trip.calculatedCommission;
      
      // Calculate total expenses
      final totalCosts = totalExpenses + totalAdvances + trip.silakAmount + totalDieselCost;
      
      // Calculate profit/loss
      final profitLoss = netRevenue - totalCosts;
      
      // Calculate profit margin percentage
      final profitMarginPercentage = netRevenue > 0 ? (profitLoss / netRevenue) * 100 : 0.0;
      
      // Create the report
      final report = TripFinancialReportModel(
        id: id,
        tripId: trip.id,
        tripLrNumber: trip.lrNumber,
        fromLocation: trip.fromLocation,
        toLocation: trip.toLocation,
        distanceKm: trip.distanceKm ?? 0.0,
        tonnage: trip.tonnage ?? 0.0,
        ratePerTon: trip.ratePerTon ?? 0.0,
        totalRevenue: totalRevenue,
        commissionAmount: trip.calculatedCommission,
        netRevenue: netRevenue,
        advanceAmount: totalAdvances,
        expensesAmount: totalExpenses,
        silakAmount: trip.silakAmount,
        dieselAmount: totalDieselCost,
        otherCosts: 0.0, // No other costs for now
        totalExpenses: totalCosts,
        profitLoss: profitLoss,
        profitMarginPercentage: profitMarginPercentage,
        tripStatus: trip.status,
        isFinal: isFinal,
        reportDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      // Save to Supabase
      final response = await SupabaseService.client
          .from('trip_financial_reports')
          .insert(report.toJson())
          .select()
          .single();
      
      return TripFinancialReportModel.fromJson(response);
    } catch (e) {
      print('Error generating financial report: $e');
      throw Exception('Failed to generate financial report: $e');
    }
  }

  // Get all financial reports for a trip
  static Future<List<TripFinancialReportModel>> getFinancialReportsForTrip(String tripId) async {
    try {
      final response = await SupabaseService.client
          .from('trip_financial_reports')
          .select()
          .eq('trip_id', tripId)
          .order('report_date', ascending: false);
      
      return response.map<TripFinancialReportModel>((json) => TripFinancialReportModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting financial reports: $e');
      throw Exception('Failed to get financial reports: $e');
    }
  }

  // Get the latest financial report for a trip
  static Future<TripFinancialReportModel?> getLatestFinancialReport(String tripId) async {
    try {
      final response = await SupabaseService.client
          .from('trip_financial_reports')
          .select()
          .eq('trip_id', tripId)
          .order('report_date', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response != null) {
        return TripFinancialReportModel.fromJson(response);
      }
      
      return null;
    } catch (e) {
      print('Error getting latest financial report: $e');
      throw Exception('Failed to get latest financial report: $e');
    }
  }

  // Get the final financial report for a trip
  static Future<TripFinancialReportModel?> getFinalFinancialReport(String tripId) async {
    try {
      final response = await SupabaseService.client
          .from('trip_financial_reports')
          .select()
          .eq('trip_id', tripId)
          .eq('is_final', true)
          .maybeSingle();
      
      if (response != null) {
        return TripFinancialReportModel.fromJson(response);
      }
      
      return null;
    } catch (e) {
      print('Error getting final financial report: $e');
      throw Exception('Failed to get final financial report: $e');
    }
  }

  // Generate final report when trip is completed
  static Future<TripFinancialReportModel> generateFinalReport(TripModel trip) async {
    if (trip.status != 'completed' && trip.status != 'settled') {
      throw Exception('Cannot generate final report for a trip that is not completed or settled');
    }
    
    return generateFinancialReport(trip: trip, isFinal: true);
  }

  // Get all financial reports (for admin and accountant)
  static Future<List<TripFinancialReportModel>> getAllFinancialReports() async {
    try {
      final response = await SupabaseService.client
          .from('trip_financial_reports')
          .select()
          .order('report_date', ascending: false);
      
      return response.map<TripFinancialReportModel>((json) => TripFinancialReportModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all financial reports: $e');
      throw Exception('Failed to get all financial reports: $e');
    }
  }

  // Get all final financial reports (for admin and accountant)
  static Future<List<TripFinancialReportModel>> getAllFinalReports() async {
    try {
      final response = await SupabaseService.client
          .from('trip_financial_reports')
          .select()
          .eq('is_final', true)
          .order('report_date', ascending: false);
      
      return response.map<TripFinancialReportModel>((json) => TripFinancialReportModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all final reports: $e');
      throw Exception('Failed to get all final reports: $e');
    }
  }

  // Check if user can access financial reports (admin or accountant only)
  static bool canAccessFinancialReports(String userRole) {
    return userRole == 'admin' || userRole == 'accountant';
  }
}
