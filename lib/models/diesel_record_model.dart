class DieselRecordModel {
  final String id;
  final String tripId;
  final String vehicleId;
  final double quantity; // in liters
  final double pricePerLiter;
  final double totalAmount;
  final String recordType; // 'initial', 'refill'
  final String? pumpPartnerId; // ID of the pump partner if applicable
  final DateTime recordDate;
  final String? location;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DieselRecordModel({
    required this.id,
    required this.tripId,
    required this.vehicleId,
    required this.quantity,
    required this.pricePerLiter,
    required this.totalAmount,
    required this.recordType,
    this.pumpPartnerId,
    required this.recordDate,
    this.location,
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
      'quantity': quantity,
      'price_per_liter': pricePerLiter,
      'total_amount': totalAmount,
      'record_type': recordType,
      'pump_partner_id': pumpPartnerId,
      'record_date': recordDate.toIso8601String(),
      'location': location,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory DieselRecordModel.fromJson(Map<String, dynamic> json) {
    return DieselRecordModel(
      id: json['id'],
      tripId: json['trip_id'],
      vehicleId: json['vehicle_id'],
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      pricePerLiter: (json['price_per_liter'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      recordType: json['record_type'] ?? 'refill',
      pumpPartnerId: json['pump_partner_id'],
      recordDate: DateTime.parse(json['record_date']),
      location: json['location'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  DieselRecordModel copyWith({
    String? id,
    String? tripId,
    String? vehicleId,
    double? quantity,
    double? pricePerLiter,
    double? totalAmount,
    String? recordType,
    String? pumpPartnerId,
    DateTime? recordDate,
    String? location,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DieselRecordModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      vehicleId: vehicleId ?? this.vehicleId,
      quantity: quantity ?? this.quantity,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalAmount: totalAmount ?? this.totalAmount,
      recordType: recordType ?? this.recordType,
      pumpPartnerId: pumpPartnerId ?? this.pumpPartnerId,
      recordDate: recordDate ?? this.recordDate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate total amount
  factory DieselRecordModel.calculate({
    required String id,
    required String tripId,
    required String vehicleId,
    required double quantity,
    required double pricePerLiter,
    required String recordType,
    String? pumpPartnerId,
    DateTime? recordDate,
    String? location,
    String? notes,
  }) {
    final totalAmount = quantity * pricePerLiter;

    return DieselRecordModel(
      id: id,
      tripId: tripId,
      vehicleId: vehicleId,
      quantity: quantity,
      pricePerLiter: pricePerLiter,
      totalAmount: totalAmount,
      recordType: recordType,
      pumpPartnerId: pumpPartnerId,
      recordDate: recordDate ?? DateTime.now(),
      location: location,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}

