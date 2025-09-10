import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/services/supabase_service.dart';
import 'package:version1/models/user_model.dart';

class AdminUsersManagementScreen extends StatefulWidget {
  const AdminUsersManagementScreen({super.key});

  @override
  State<AdminUsersManagementScreen> createState() => _AdminUsersManagementScreenState();
}

class _AdminUsersManagementScreenState extends State<AdminUsersManagementScreen> {
  bool _isLoading = true;
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  String _selectedRole = 'all';
  String _searchQuery = '';
  List<String> _selectedUserIds = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await SupabaseService.getAllUsers();
      setState(() {
        _allUsers = users;
        _applyFilters();
      });
    } catch (e) {
      print('Error loading users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final matchesRole = _selectedRole == 'all' || (user.role?.toString().split('.').last ?? '') == _selectedRole;
        final matchesSearch = _searchQuery.isEmpty || 
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.phoneNumber.contains(_searchQuery) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesRole && matchesSearch;
      }).toList();
    });
  }

  void _onRoleFilterChanged(String role) {
    setState(() {
      _selectedRole = role;
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedUserIds.clear();
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _selectAllUsers() {
    setState(() {
      _selectedUserIds = _filteredUsers.map((user) => user.id).toList();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUserIds.clear();
    });
  }

  Future<void> _bulkApproveUsers() async {
    if (_selectedUserIds.isEmpty) return;

    try {
      for (String userId in _selectedUserIds) {
        await SupabaseService.approveUser(userId);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedUserIds.length} users approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      _clearSelection();
      _toggleSelectionMode();
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkRejectUsers() async {
    if (_selectedUserIds.isEmpty) return;

    try {
      for (String userId in _selectedUserIds) {
        await SupabaseService.rejectUser(userId, 'Bulk rejection by admin');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedUserIds.length} users rejected successfully'),
          backgroundColor: Colors.orange,
        ),
      );
      
      _clearSelection();
      _toggleSelectionMode();
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? 'Exit Selection' : 'Select Users',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          if (_isSelectionMode) _buildBulkActionsSection(),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search users by name, phone, or email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          // Role filter
          Row(
            children: [
              const Text('Filter by Role:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRoleChip('all', 'All'),
                      const SizedBox(width: 8),
                      _buildRoleChip('admin', 'Admin'),
                      const SizedBox(width: 8),
                      _buildRoleChip('traffic_manager', 'Traffic Manager'),
                      const SizedBox(width: 8),
                      _buildRoleChip('driver', 'Driver'),
                      const SizedBox(width: 8),
                      _buildRoleChip('accountant', 'Accountant'),
                      const SizedBox(width: 8),
                      _buildRoleChip('pump_partner', 'Pump Partner'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, String label) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onRoleFilterChanged(role),
      selectedColor: AppColors.primaryBlue.withOpacity(0.2),
      checkmarkColor: AppColors.primaryBlue,
    );
  }

  Widget _buildBulkActionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Row(
        children: [
          Text(
            '${_selectedUserIds.length} selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_selectedUserIds.length < _filteredUsers.length)
            TextButton(
              onPressed: _selectAllUsers,
              child: const Text('Select All'),
            ),
          if (_selectedUserIds.isNotEmpty)
            TextButton(
              onPressed: _clearSelection,
              child: const Text('Clear'),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _selectedUserIds.isNotEmpty ? _bulkApproveUsers : null,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _selectedUserIds.isNotEmpty ? _bulkRejectUsers : null,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final isSelected = _selectedUserIds.contains(user.id);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.phoneNumber} • ${user.email}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(user.approvalStatus.name),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    child: Text(
                      user.approvalStatus.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                        child: Text(
                          (user.role?.toString().split('.').last ?? 'NOT_SET').toUpperCase(),
                        style: TextStyle(
                          color: _getRoleColor(user.role),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${user.createdAt.toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleUserSelection(user.id),
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) => _handleUserAction(value, user),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view_details',
                        child: Row(
                          children: [
                            Icon(Icons.info, size: 18),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      if (user.approvalStatus.name == 'pending')
                        const PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Approve'),
                            ],
                          ),
                        ),
                      if (user.approvalStatus.name == 'pending')
                        const PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              Icon(Icons.close, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Reject'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'activity_log',
                        child: Row(
                          children: [
                            Icon(Icons.history, size: 18),
                            SizedBox(width: 8),
                            Text('Activity Log'),
                          ],
                        ),
                      ),
                    ],
                  ),
            onTap: _isSelectionMode
                ? () => _toggleUserSelection(user.id)
                : () => _showUserDetails(user),
          ),
        );
      },
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.tripManager:
        return Colors.blue;
      case UserRole.driver:
        return Colors.green;
      case UserRole.accountant:
        return Colors.purple;
      case UserRole.pumpPartner:
        return Colors.orange;
      case null:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleUserAction(String action, UserModel user) {
    switch (action) {
      case 'view_details':
        _showUserDetails(user);
        break;
      case 'approve':
        _approveUser(user);
        break;
      case 'reject':
        _rejectUser(user);
        break;
      case 'activity_log':
        _showActivityLog(user);
        break;
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${user.phoneNumber}'),
            Text('Email: ${user.email}'),
            Text('Address: ${user.address}'),
            Text('Role: ${user.role?.toString().split('.').last ?? 'Not set'}'),
            Text('Status: ${user.approvalStatus.name}'),
            Text('Created: ${user.createdAt.toString().split(' ')[0]}'),
            if (user.updatedAt != null)
              Text('Updated: ${user.updatedAt.toString().split(' ')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(UserModel user) async {
    try {
      await SupabaseService.approveUser(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    try {
      await SupabaseService.rejectUser(user.id, 'Rejected by admin');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} rejected successfully'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showActivityLog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activity Log - ${user.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildActivityItem('User registered', user.createdAt, 'Registration'),
                    if (user.updatedAt != null)
                      _buildActivityItem('Profile updated', user.updatedAt!, 'Update'),
                    _buildActivityItem('Last login', DateTime.now().subtract(const Duration(hours: 2)), 'Login'),
                    _buildActivityItem('Status changed to ${user.approvalStatus.name}', DateTime.now().subtract(const Duration(days: 1)), 'Status Change'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String description, DateTime timestamp, String type) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: _getActivityTypeColor(type),
        child: Icon(
          _getActivityTypeIcon(type),
          size: 16,
          color: Colors.white,
        ),
      ),
      title: Text(description),
      subtitle: Text(timestamp.toString().split('.')[0]),
      dense: true,
    );
  }

  Color _getActivityTypeColor(String type) {
    switch (type) {
      case 'Registration':
        return Colors.blue;
      case 'Update':
        return Colors.orange;
      case 'Login':
        return Colors.green;
      case 'Status Change':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type) {
      case 'Registration':
        return Icons.person_add;
      case 'Update':
        return Icons.edit;
      case 'Login':
        return Icons.login;
      case 'Status Change':
        return Icons.swap_horiz;
      default:
        return Icons.info;
    }
  }
}
