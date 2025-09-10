class TripModel {
  final String id;
  final String lrNumber;
  final String vehicleId;
  final String driverId;
  final String? brokerId;
  final String? assignedBy;
  final String fromLocation;
  final String toLocation;
  final double? distanceKm;
  final double? tonnage;
  final double? ratePerTon;
  final double? totalRate;
  final double commissionAmount;
  final double advanceGiven;
  final double dieselIssued;
  final double silakAmount;
  String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TripModel({
    required this.id,
    required this.lrNumber,
    required this.vehicleId,
    required this.driverId,
    this.brokerId,
    this.assignedBy,
    required this.fromLocation,
    required this.toLocation,
    this.distanceKm,
    this.tonnage,
    this.ratePerTon,
    this.totalRate,
    this.commissionAmount = 0.0,
    this.advanceGiven = 0.0,
    this.dieselIssued = 0.0,
    this.silakAmount = 0.0,
    this.status = 'assigned',
    this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lr_number': lrNumber,
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'broker_id': brokerId,
      'assigned_by': assignedBy,
      'from_location': fromLocation,
      'to_location': toLocation,
      'distance_km': distanceKm,
      'tonnage': tonnage,
      'rate_per_ton': ratePerTon,
      'total_rate': totalRate,
      'commission_amount': commissionAmount,
      'advance_given': advanceGiven,
      'diesel_issued': dieselIssued,
      'silak_amount': silakAmount,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      lrNumber: json['lr_number'],
      vehicleId: json['vehicle_id'],
      driverId: json['driver_id'],
      brokerId: json['broker_id'],
      assignedBy: json['assigned_by'],
      fromLocation: json['from_location'],
      toLocation: json['to_location'],
      distanceKm: json['distance_km']?.toDouble(),
      tonnage: json['tonnage']?.toDouble(),
      ratePerTon: json['rate_per_ton']?.toDouble(),
      totalRate: json['total_rate']?.toDouble(),
      commissionAmount: (json['commission_amount'] ?? 0.0).toDouble(),
      advanceGiven: (json['advance_given'] ?? 0.0).toDouble(),
      dieselIssued: (json['diesel_issued'] ?? 0.0).toDouble(),
      silakAmount: (json['silak_amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'assigned',
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  TripModel copyWith({
    String? id,
    String? lrNumber,
    String? vehicleId,
    String? driverId,
    String? brokerId,
    String? assignedBy,
    String? fromLocation,
    String? toLocation,
    double? distanceKm,
    double? tonnage,
    double? ratePerTon,
    double? totalRate,
    double? commissionAmount,
    double? advanceGiven,
    double? dieselIssued,
    double? silakAmount,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      lrNumber: lrNumber ?? this.lrNumber,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      brokerId: brokerId ?? this.brokerId,
      assignedBy: assignedBy ?? this.assignedBy,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      distanceKm: distanceKm ?? this.distanceKm,
      tonnage: tonnage ?? this.tonnage,
      ratePerTon: ratePerTon ?? this.ratePerTon,
      totalRate: totalRate ?? this.totalRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      advanceGiven: advanceGiven ?? this.advanceGiven,
      dieselIssued: dieselIssued ?? this.dieselIssued,
      silakAmount: silakAmount ?? this.silakAmount,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  double get calculatedTotalRate {
    if (tonnage != null && ratePerTon != null) {
      return tonnage! * ratePerTon!;
    }
    return totalRate ?? 0.0;
  }

  double get calculatedCommission {
    if (brokerId != null && calculatedTotalRate > 0) {
      // Commission will be calculated based on broker's rate
      return calculatedTotalRate * 0.05; // Default 5%, should be from broker
    }
    return commissionAmount;
  }

  bool get isCompleted => status == 'completed';
  bool get isSettled => status == 'settled';
  bool get isInProgress => status == 'in_progress';
  bool get isAssigned => status == 'assigned';
}

enum TripStatus {
  assigned('Assigned', 'Trip has been assigned to driver'),
  inProgress('In Progress', 'Trip is currently in progress'),
  completed('Completed', 'Trip has been completed'),
  settled('Settled', 'Trip has been settled and paid'),
  cancelled('Cancelled', 'Trip has been cancelled');

  const TripStatus(this.displayName, this.description);

  final String displayName;
  final String description;
}
