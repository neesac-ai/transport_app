import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../services/supabase_service.dart';

class DriverExpenseTrackingScreen extends StatefulWidget {
  final UserModel user;

  const DriverExpenseTrackingScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<DriverExpenseTrackingScreen> createState() => _DriverExpenseTrackingScreenState();
}

class _DriverExpenseTrackingScreenState extends State<DriverExpenseTrackingScreen> {
  bool _isLoading = true;
  List<ExpenseModel> _expenses = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    
    try {
      final expenses = await SupabaseService.getDriverExpenses(widget.user.id);
      setState(() => _expenses = expenses);
    } catch (e) {
      print('Error loading expenses: $e');
      _showErrorSnackBar('Failed to load expenses');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<ExpenseModel> _getFilteredExpenses() {
    switch (_selectedFilter) {
      case 'pending':
        return _expenses.where((expense) => expense.status == 'pending').toList();
      case 'approved':
        return _expenses.where((expense) => expense.status == 'approved').toList();
      case 'rejected':
        return _expenses.where((expense) => expense.status == 'rejected').toList();
      default:
        return _expenses;
    }
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'approved', 'label': 'Approved'},
      {'key': 'rejected', 'label': 'Rejected'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter['key']!);
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(expense.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    expense.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(expense.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  expense.category,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.attach_money, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatDate(expense.expenseDate),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (expense.notes != null && expense.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${expense.notes}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
            if (expense.status == 'rejected' && expense.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection Reason: ${expense.rejectionReason}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _addExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          user: widget.user,
          onExpenseAdded: _loadExpenses,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadExpenses,
                    child: _getFilteredExpenses().isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _getFilteredExpenses().length,
                            itemBuilder: (context, index) {
                              final expense = _getFilteredExpenses()[index];
                              return _buildExpenseCard(expense);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any expenses in this category',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onExpenseAdded;

  const AddExpenseScreen({
    Key? key,
    required this.user,
    required this.onExpenseAdded,
  }) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'fuel';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _categories = [
    'fuel',
    'toll',
    'maintenance',
    'food',
    'accommodation',
    'other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final expense = ExpenseModel(
        id: '', // Will be auto-generated by database
        tripId: null, // General expense, not trip-specific
        vehicleId: null,
        category: _selectedCategory,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        receiptUrl: null,
        expenseDate: _selectedDate,
        status: 'pending',
        approvedBy: null,
        approvedAt: null,
        rejectionReason: null,
        enteredBy: widget.user.id,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
        updatedAt: null,
      );

      await SupabaseService.createExpense(expense);
      
      Navigator.pop(context);
      widget.onExpenseAdded();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error creating expense: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit expense'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter expense description',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              const Text(
                'Amount (₹)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter any additional notes',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
