class AdvanceModel {
  final String id;
  final String driverId;
  final String? tripId;
  final double amount;
  final String advanceType;
  final String? purpose;
  final String? givenBy;
  final DateTime givenDate;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AdvanceModel({
    required this.id,
    required this.driverId,
    this.tripId,
    required this.amount,
    this.advanceType = 'trip_advance',
    this.purpose,
    this.givenBy,
    required this.givenDate,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'trip_id': tripId,
      'amount': amount,
      'advance_type': advanceType,
      'purpose': purpose,
      'given_by': givenBy,
      'given_date': givenDate.toIso8601String().split('T')[0], // Date only
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory AdvanceModel.fromJson(Map<String, dynamic> json) {
    return AdvanceModel(
      id: json['id'],
      driverId: json['driver_id'],
      tripId: json['trip_id'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      advanceType: json['advance_type'] ?? 'trip_advance',
      purpose: json['purpose'],
      givenBy: json['given_by'],
      givenDate: DateTime.parse(json['given_date']),
      status: json['status'] ?? 'pending',
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
      rejectionReason: json['rejection_reason'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  AdvanceModel copyWith({
    String? id,
    String? driverId,
    String? tripId,
    double? amount,
    String? advanceType,
    String? purpose,
    String? givenBy,
    DateTime? givenDate,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdvanceModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      tripId: tripId ?? this.tripId,
      amount: amount ?? this.amount,
      advanceType: advanceType ?? this.advanceType,
      purpose: purpose ?? this.purpose,
      givenBy: givenBy ?? this.givenBy,
      givenDate: givenDate ?? this.givenDate,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isTripAdvance => advanceType == 'trip_advance';
  bool get isGeneralAdvance => advanceType == 'general_advance';
  bool get isEmergencyAdvance => advanceType == 'emergency';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  
  String get advanceTypeDisplayName {
    switch (advanceType) {
      case 'trip_advance':
        return 'Trip Advance';
      case 'general_advance':
        return 'General Advance';
      case 'emergency':
        return 'Emergency Advance';
      default:
        return 'Unknown';
    }
  }
}

enum AdvanceType {
  tripAdvance('trip_advance', 'Trip Advance', 'Advance given for specific trip'),
  generalAdvance('general_advance', 'General Advance', 'General advance for driver'),
  emergency('emergency', 'Emergency Advance', 'Emergency advance for urgent needs');

  const AdvanceType(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}

enum AdvanceStatus {
  pending('pending', 'Pending', 'Waiting for approval'),
  approved('approved', 'Approved', 'Advance has been approved'),
  rejected('rejected', 'Rejected', 'Advance has been rejected');

  const AdvanceStatus(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}


