class DieselEntryModel {
  final String id;
  final String? tripId;
  final String vehicleId;
  final String entryType;
  final String? pumpPartnerId;
  final double quantityLiters;
  final double ratePerLiter;
  final double totalAmount;
  final String? pumpLocation;
  final String? pumpName;
  final double? odometerReading;
  final DateTime entryDate;
  final String? enteredBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DieselEntryModel({
    required this.id,
    this.tripId,
    required this.vehicleId,
    required this.entryType,
    this.pumpPartnerId,
    required this.quantityLiters,
    required this.ratePerLiter,
    required this.totalAmount,
    this.pumpLocation,
    this.pumpName,
    this.odometerReading,
    required this.entryDate,
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
      'entry_type': entryType,
      'pump_partner_id': pumpPartnerId,
      'quantity_liters': quantityLiters,
      'rate_per_liter': ratePerLiter,
      'total_amount': totalAmount,
      'pump_location': pumpLocation,
      'pump_name': pumpName,
      'odometer_reading': odometerReading,
      'entry_date': entryDate.toIso8601String(),
      'entered_by': enteredBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory DieselEntryModel.fromJson(Map<String, dynamic> json) {
    return DieselEntryModel(
      id: json['id'],
      tripId: json['trip_id'],
      vehicleId: json['vehicle_id'],
      entryType: json['entry_type'],
      pumpPartnerId: json['pump_partner_id'],
      quantityLiters: (json['quantity_liters'] ?? 0.0).toDouble(),
      ratePerLiter: (json['rate_per_liter'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      pumpLocation: json['pump_location'],
      pumpName: json['pump_name'],
      odometerReading: json['odometer_reading']?.toDouble(),
      entryDate: DateTime.parse(json['entry_date']),
      enteredBy: json['entered_by'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  DieselEntryModel copyWith({
    String? id,
    String? tripId,
    String? vehicleId,
    String? entryType,
    String? pumpPartnerId,
    double? quantityLiters,
    double? ratePerLiter,
    double? totalAmount,
    String? pumpLocation,
    String? pumpName,
    double? odometerReading,
    DateTime? entryDate,
    String? enteredBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DieselEntryModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      vehicleId: vehicleId ?? this.vehicleId,
      entryType: entryType ?? this.entryType,
      pumpPartnerId: pumpPartnerId ?? this.pumpPartnerId,
      quantityLiters: quantityLiters ?? this.quantityLiters,
      ratePerLiter: ratePerLiter ?? this.ratePerLiter,
      totalAmount: totalAmount ?? this.totalAmount,
      pumpLocation: pumpLocation ?? this.pumpLocation,
      pumpName: pumpName ?? this.pumpName,
      odometerReading: odometerReading ?? this.odometerReading,
      entryDate: entryDate ?? this.entryDate,
      enteredBy: enteredBy ?? this.enteredBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isCreditPump => entryType == 'credit_pump';
  bool get isRandomPump => entryType == 'random_pump';
  bool get isDieselCard => entryType == 'diesel_card';
  
  String get entryTypeDisplayName {
    switch (entryType) {
      case 'credit_pump':
        return 'Credit Pump Partner';
      case 'random_pump':
        return 'Random Pump';
      case 'diesel_card':
        return 'Diesel Card';
      default:
        return 'Unknown';
    }
  }
}

enum DieselEntryType {
  creditPump('credit_pump', 'Credit Pump Partner', 'Diesel from registered pump partner'),
  randomPump('random_pump', 'Random Pump', 'Diesel from any pump'),
  dieselCard('diesel_card', 'Diesel Card', 'Diesel using company diesel card');

  const DieselEntryType(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}


