import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/models/user_model.dart';
import 'package:version1/models/advance_model.dart';
import 'package:version1/services/supabase_service.dart';
import 'package:version1/services/supabase_service_additions.dart';

class AccountantAdvanceApprovalScreen extends StatefulWidget {
  final UserModel user;

  const AccountantAdvanceApprovalScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<AccountantAdvanceApprovalScreen> createState() => _AccountantAdvanceApprovalScreenState();
}

class _AccountantAdvanceApprovalScreenState extends State<AccountantAdvanceApprovalScreen> {
  bool _isLoading = true;
  List<AdvanceModel> _advances = [];
  List<AdvanceModel> _filteredAdvances = [];
  String _statusFilter = 'pending';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAdvances();
  }

  Future<void> _loadAdvances() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final advances = await SupabaseService.getAllAdvances();
      setState(() {
        _advances = advances;
        _applyFilters();
      });
    } catch (e) {
      print('Error loading advances: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading advances: $e'),
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
      _filteredAdvances = _advances.where((advance) {
        final matchesStatus = _statusFilter == 'all' || advance.status == _statusFilter;
        final matchesSearch = _searchQuery.isEmpty || 
            (advance.purpose?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            advance.advanceType.toLowerCase().contains(_searchQuery.toLowerCase());
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
        title: const Text('Advance Approval'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdvances,
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
                  child: _buildAdvancesList(),
                ),
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
              hintText: 'Search advances by purpose or type...',
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
                      _buildStatusChip('pending', 'Pending', _statusFilter, _onStatusFilterChanged),
                      const SizedBox(width: 8),
                      _buildStatusChip('approved', 'Approved', _statusFilter, _onStatusFilterChanged),
                      const SizedBox(width: 8),
                      _buildStatusChip('rejected', 'Rejected', _statusFilter, _onStatusFilterChanged),
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
    Color chipColor;
    
    switch (status) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'approved':
        chipColor = Colors.green;
        break;
      case 'rejected':
        chipColor = Colors.red;
        break;
      default:
        chipColor = AppColors.primaryBlue;
    }
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onChanged(status),
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
    );
  }

  Widget _buildAdvancesList() {
    if (_filteredAdvances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No advances found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusFilter == 'pending'
                  ? 'No pending advances to approve'
                  : 'Try changing the filter to see more advances',
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
      itemCount: _filteredAdvances.length,
      itemBuilder: (context, index) {
        final advance = _filteredAdvances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAdvanceTypeColor(advance.advanceType),
              child: Icon(
                _getAdvanceTypeIcon(advance.advanceType),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              advance.purpose ?? advance.advanceType.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${advance.advanceType.replaceAll('_', ' ')}'),
                Text('Date: ${_formatDate(advance.givenDate)}'),
                if (advance.tripId != null)
                  Text('Trip: ${advance.tripId}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${advance.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(advance.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    advance.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => _showAdvanceDetails(advance),
          ),
        );
      },
    );
  }

  Color _getAdvanceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'trip_advance':
        return Colors.blue;
      case 'general_advance':
        return Colors.green;
      case 'emergency':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData _getAdvanceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'trip_advance':
        return Icons.directions_car;
      case 'general_advance':
        return Icons.account_balance_wallet;
      case 'emergency':
        return Icons.warning;
      default:
        return Icons.attach_money;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAdvanceDetails(AdvanceModel advance) {
    final TextEditingController _rejectionReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Purpose', advance.purpose ?? 'Not specified'),
              _buildDetailRow('Type', advance.advanceType.replaceAll('_', ' ')),
              _buildDetailRow('Amount', '₹${advance.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Date', _formatDate(advance.givenDate)),
              _buildDetailRow('Status', advance.status.toUpperCase()),
              if (advance.tripId != null)
                _buildDetailRow('Trip ID', advance.tripId!),
              if (advance.notes != null && advance.notes!.isNotEmpty)
                _buildDetailRow('Notes', advance.notes!),
              if (advance.status == 'pending') ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Approve or Reject:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _rejectionReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason (if rejecting)',
                    border: OutlineInputBorder(),
                    hintText: 'Enter reason for rejection...',
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (advance.status == 'pending') ...[
            ElevatedButton(
              onPressed: () => _rejectAdvance(advance, _rejectionReasonController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () => _approveAdvance(advance),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAdvance(AdvanceModel advance) async {
    try {
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
              Text('Approving advance...'),
            ],
          ),
        ),
      );

      await AccountantApprovalMethods.approveAdvance(advance.id, widget.user.id);
      
      // Close loading dialog and details dialog
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advance approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh advances list
      _loadAdvances();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving advance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAdvance(AdvanceModel advance, String reason) async {
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for rejection'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
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
              Text('Rejecting advance...'),
            ],
          ),
        ),
      );

      await AccountantApprovalMethods.rejectAdvance(advance.id, widget.user.id, reason);
      
      // Close loading dialog and details dialog
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advance rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Refresh advances list
      _loadAdvances();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting advance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
