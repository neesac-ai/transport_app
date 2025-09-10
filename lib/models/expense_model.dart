class ExpenseModel {
  final String id;
  final String? tripId;
  final String? vehicleId;
  final String category;
  final String description;
  final double amount;
  final String? receiptUrl;
  final DateTime expenseDate;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? enteredBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ExpenseModel({
    required this.id,
    this.tripId,
    this.vehicleId,
    required this.category,
    required this.description,
    required this.amount,
    this.receiptUrl,
    required this.expenseDate,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.enteredBy,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'vehicle_id': vehicleId,
      'category': category,
      'description': description,
      'amount': amount,
      'receipt_url': receiptUrl,
      'expense_date': expenseDate.toIso8601String().split('T')[0], // Date only
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'entered_by': enteredBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      tripId: json['trip_id'],
      vehicleId: json['vehicle_id'],
      category: json['category'],
      description: json['description'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      receiptUrl: json['receipt_url'],
      expenseDate: DateTime.parse(json['expense_date']),
      status: json['status'] ?? 'pending',
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
      rejectionReason: json['rejection_reason'],
      enteredBy: json['entered_by'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  ExpenseModel copyWith({
    String? id,
    String? tripId,
    String? vehicleId,
    String? category,
    String? description,
    double? amount,
    String? receiptUrl,
    DateTime? expenseDate,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    String? enteredBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      vehicleId: vehicleId ?? this.vehicleId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      expenseDate: expenseDate ?? this.expenseDate,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      enteredBy: enteredBy ?? this.enteredBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isTripSpecific => tripId != null;
  bool get isGeneral => tripId == null;
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  
  String get categoryDisplayName {
    switch (category) {
      case 'trip_specific':
        return 'Trip Specific';
      case 'general':
        return 'General';
      case 'maintenance':
        return 'Maintenance';
      case 'fuel':
        return 'Fuel';
      case 'toll':
        return 'Toll';
      case 'driver_expense':
        return 'Driver Expense';
      case 'office':
        return 'Office';
      default:
        return category;
    }
  }
}

enum ExpenseCategory {
  tripSpecific('trip_specific', 'Trip Specific', 'Expenses related to specific trips'),
  general('general', 'General', 'General business expenses'),
  maintenance('maintenance', 'Maintenance', 'Vehicle maintenance expenses'),
  fuel('fuel', 'Fuel', 'Fuel and diesel expenses'),
  toll('toll', 'Toll', 'Toll and road tax expenses'),
  driverExpense('driver_expense', 'Driver Expense', 'Driver-related expenses'),
  office('office', 'Office', 'Office and administrative expenses');

  const ExpenseCategory(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}

enum ExpenseStatus {
  pending('pending', 'Pending', 'Waiting for approval'),
  approved('approved', 'Approved', 'Expense has been approved'),
  rejected('rejected', 'Rejected', 'Expense has been rejected');

  const ExpenseStatus(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}


