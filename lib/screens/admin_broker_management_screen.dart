import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/models/broker_model.dart';
import 'package:version1/services/supabase_service.dart';
import 'add_broker_screen.dart';

class AdminBrokerManagementScreen extends StatefulWidget {
  const AdminBrokerManagementScreen({super.key});

  @override
  State<AdminBrokerManagementScreen> createState() => _AdminBrokerManagementScreenState();
}

class _AdminBrokerManagementScreenState extends State<AdminBrokerManagementScreen> {
  bool _isLoading = true;
  List<BrokerModel> _brokers = [];
  List<BrokerModel> _filteredBrokers = [];
  String _statusFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final brokers = await SupabaseService.getBrokers();
      
      setState(() {
        _brokers = brokers;
        _applyFilters();
      });
    } catch (e) {
      print('Error loading brokers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading brokers: $e'),
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
      // Filter brokers
      _filteredBrokers = _brokers.where((broker) {
        final matchesStatus = _statusFilter == 'all' || broker.status == _statusFilter;
        final matchesSearch = _searchQuery.isEmpty || 
            broker.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (broker.company?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _statusFilter = status;
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broker Management'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFiltersSection(),
                Expanded(
                  child: _buildBrokersList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBroker,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
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
              hintText: 'Search brokers by name or company...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          // Status filter
          Row(
            children: [
              const Text('Filter by Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('all', 'All', _statusFilter, _onStatusFilterChanged),
                      const SizedBox(width: 8),
                      _buildStatusChip('active', 'Active', _statusFilter, _onStatusFilterChanged),
                      const SizedBox(width: 8),
                      _buildStatusChip('inactive', 'Inactive', _statusFilter, _onStatusFilterChanged),
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

  Widget _buildStatusChip(String status, String label, String selectedStatus, Function(String) onChanged) {
    final isSelected = selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onChanged(status),
      selectedColor: AppColors.primaryBlue.withOpacity(0.2),
      checkmarkColor: AppColors.primaryBlue,
    );
  }

  Widget _buildBrokersList() {
    if (_filteredBrokers.isEmpty) {
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
              'No brokers found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first broker to get started',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddBroker,
              icon: const Icon(Icons.add),
              label: const Text('Add Broker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBrokers.length,
      itemBuilder: (context, index) {
        final broker = _filteredBrokers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(
                broker.name.isNotEmpty ? broker.name[0].toUpperCase() : 'B',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              broker.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (broker.company != null) Text('Company: ${broker.company}'),
                Text('Contact: ${broker.contactNumber}'),
                if (broker.email != null) Text('Email: ${broker.email}'),
                Text('Commission: ${broker.commissionRate}%'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(broker.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    broker.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleBrokerAction(value, broker),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit_status',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Change Status'),
                        ],
                      ),
                    ),
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _showBrokerDetails(broker),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleBrokerAction(String action, BrokerModel broker) {
    switch (action) {
      case 'edit_status':
        _showStatusChangeDialog(broker);
        break;
      case 'view_details':
        _showBrokerDetails(broker);
        break;
      case 'delete':
        _showDeleteBrokerConfirmation(broker);
        break;
    }
  }

  void _showStatusChangeDialog(BrokerModel broker) {
    String currentStatus = broker.status;
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Status - ${broker.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select new status:'),
              const SizedBox(height: 16),
              ...['active', 'inactive'].map((status) => 
                RadioListTile<String>(
                  title: Text(status.toUpperCase()),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStatus != currentStatus
                  ? () => _updateBrokerStatus(broker, selectedStatus)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBrokerStatus(BrokerModel broker, String newStatus) async {
    try {
      await SupabaseService.updateBrokerStatus(broker.id, newStatus);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${broker.name} status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBrokerDetails(BrokerModel broker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(broker.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (broker.company != null) Text('Company: ${broker.company}'),
            Text('Contact Number: ${broker.contactNumber}'),
            if (broker.email != null) Text('Email: ${broker.email}'),
            Text('Commission Rate: ${broker.commissionRate}%'),
            Text('Status: ${broker.status}'),
            Text('Created: ${broker.createdAt.toString().split(' ')[0]}'),
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

  void _showDeleteBrokerConfirmation(BrokerModel broker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Broker?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WARNING: This action cannot be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Are you sure you want to permanently delete ${broker.name}?'),
            const SizedBox(height: 8),
            const Text(
              'Note: Brokers associated with trips cannot be deleted.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteBroker(broker),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBroker(BrokerModel broker) async {
    try {
      Navigator.of(context).pop(); // Close confirmation dialog
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting broker...'),
            ],
          ),
        ),
      );
      
      await SupabaseService.deleteBroker(broker.id);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${broker.name} deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh data
      _loadData();
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToAddBroker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBrokerScreen()),
    ).then((result) {
      if (result == true) {
        _loadData(); // Refresh data after adding broker
      }
    });
  }
}

