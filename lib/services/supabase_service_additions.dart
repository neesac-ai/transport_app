import 'package:version1/services/supabase_service.dart';

// Extension methods for accountant approval functionality
extension AccountantApprovalMethods on SupabaseService {
  static Future<void> approveAdvance(String advanceId, String approvedBy) async {
    // Check if in development mode
    try {
      final settings = await SupabaseService.client.from('settings').select('is_development').single();
      final isDevelopment = settings['is_development'] as bool? ?? false;
      
      if (isDevelopment) {
        print('Development mode: Advance $advanceId approved by $approvedBy');
        return;
      }
    } catch (e) {
      // If we can't determine development mode, proceed with the operation
      print('Could not determine development mode: $e');
    }
    try {
      await SupabaseService.client
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
    // Check if in development mode
    try {
      final settings = await SupabaseService.client.from('settings').select('is_development').single();
      final isDevelopment = settings['is_development'] as bool? ?? false;
      
      if (isDevelopment) {
        print('Development mode: Advance $advanceId rejected by $approvedBy');
        return;
      }
    } catch (e) {
      // If we can't determine development mode, proceed with the operation
      print('Could not determine development mode: $e');
    }
    try {
      await SupabaseService.client
          .from('advances')
          .update({
            'status': 'rejected',
            'approved_by': approvedBy,
            'rejection_reason': reason,
            'approved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', advanceId);
      print('Advance rejected successfully');
    } catch (e) {
      print('Error rejecting advance: $e');
      throw Exception('Failed to reject advance: $e');
    }
  }
}
