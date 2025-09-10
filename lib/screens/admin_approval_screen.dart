import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  List<UserModel> pendingUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final users = await SupabaseService.getPendingUsers();
      setState(() {
        pendingUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveUser(UserModel user) async {
    print('=== APPROVING USER ===');
    print('User ID: ${user.id}');
    print('User Name: ${user.name}');
    
    try {
      await SupabaseService.approveUser(user.id);
      print('User approved successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} has been approved'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingUsers(); // Refresh the list
      }
    } catch (e) {
      print('Error approving user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    final TextEditingController reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject ${user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await SupabaseService.rejectUser(user.id, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} has been rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPendingUsers(); // Refresh the list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Approvals'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingUsers,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.green[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending approvals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All users have been processed',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingUsers.length,
                    itemBuilder: (context, index) {
                      final user = pendingUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryBlue,
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.role?.displayName ?? 'No Role',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (user.phoneNumber.isNotEmpty) ...[
                                _buildInfoRow(Icons.phone, user.phoneNumber),
                                const SizedBox(height: 8),
                              ],
                              if (user.address.isNotEmpty) ...[
                                _buildInfoRow(Icons.location_on, user.address),
                                const SizedBox(height: 8),
                              ],
                              _buildInfoRow(
                                Icons.calendar_today,
                                'Registered: ${_formatDate(user.createdAt)}',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approveUser(user),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _rejectUser(user),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Reject'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
