import 'package:flutter/material.dart';
import 'package:version1/constants/app_colors.dart';
import 'package:version1/models/user_model.dart';
import 'package:version1/models/expense_model.dart';
import 'package:version1/services/supabase_service.dart';

class AccountantExpenseApprovalScreen extends StatefulWidget {
  final UserModel user;

  const AccountantExpenseApprovalScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<AccountantExpenseApprovalScreen> createState() => _AccountantExpenseApprovalScreenState();
}

class _AccountantExpenseApprovalScreenState extends State<AccountantExpenseApprovalScreen> {
  bool _isLoading = true;
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filteredExpenses = [];
  String _statusFilter = 'pending';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await SupabaseService.getAllExpenses();
      setState(() {
        _expenses = expenses;
        _applyFilters();
      });
    } catch (e) {
      print('Error loading expenses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading expenses: $e'),
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
      _filteredExpenses = _expenses.where((expense) {
        final matchesStatus = _statusFilter == 'all' || expense.status == _statusFilter;
        final matchesSearch = _searchQuery.isEmpty || 
            expense.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            expense.category.toLowerCase().contains(_searchQuery.toLowerCase());
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
        title: const Text('Expense Approval'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
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
                  child: _buildExpensesList(),
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
              hintText: 'Search expenses by description or category...',
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

  Widget _buildExpensesList() {
    if (_filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusFilter == 'pending'
                  ? 'No pending expenses to approve'
                  : 'Try changing the filter to see more expenses',
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
      itemCount: _filteredExpenses.length,
      itemBuilder: (context, index) {
        final expense = _filteredExpenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(expense.category),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              expense.description,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${expense.category}'),
                Text('Date: ${_formatDate(expense.expenseDate)}'),
                if (expense.tripId != null)
                  Text('Trip: ${expense.tripId}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(expense.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    expense.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => _showExpenseDetails(expense),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return Colors.blue;
      case 'toll':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'food':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return Icons.local_gas_station;
      case 'toll':
        return Icons.money;
      case 'maintenance':
        return Icons.build;
      case 'food':
        return Icons.fastfood;
      default:
        return Icons.receipt;
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

  void _showExpenseDetails(ExpenseModel expense) {
    final TextEditingController _rejectionReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expense Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', expense.description),
              _buildDetailRow('Category', expense.category),
              _buildDetailRow('Amount', '₹${expense.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Date', _formatDate(expense.expenseDate)),
              _buildDetailRow('Status', expense.status.toUpperCase()),
              if (expense.tripId != null)
                _buildDetailRow('Trip ID', expense.tripId!),
              if (expense.notes != null && expense.notes!.isNotEmpty)
                _buildDetailRow('Notes', expense.notes!),
              if (expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Receipt:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: expense.receiptUrl != null
                          ? Image.network(
                              expense.receiptUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.grey,
                            ),
                    ),
                  ],
                ),
              if (expense.status == 'pending') ...[
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
          if (expense.status == 'pending') ...[
            ElevatedButton(
              onPressed: () => _rejectExpense(expense, _rejectionReasonController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () => _approveExpense(expense),
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

  Future<void> _approveExpense(ExpenseModel expense) async {
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
              Text('Approving expense...'),
            ],
          ),
        ),
      );

      await SupabaseService.approveExpense(expense.id, widget.user.id);
      
      // Close loading dialog and details dialog
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh expenses list
      _loadExpenses();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectExpense(ExpenseModel expense, String reason) async {
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
              Text('Rejecting expense...'),
            ],
          ),
        ),
      );

      await SupabaseService.rejectExpense(expense.id, widget.user.id, reason);
      
      // Close loading dialog and details dialog
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Refresh expenses list
      _loadExpenses();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

