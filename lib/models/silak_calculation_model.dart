class SilakCalculationModel {
  final String id;
  final String tripId;
  final String driverId;
  final String calculationType;
  final double rate;
  final double quantity;
  final double calculatedAmount;
  final double advanceDeducted;
  final double dieselDeducted;
  final double netAmount;
  final DateTime calculatedAt;
  final String? calculatedBy;
  final String? notes;
  final DateTime createdAt;

  SilakCalculationModel({
    required this.id,
    required this.tripId,
    required this.driverId,
    required this.calculationType,
    required this.rate,
    required this.quantity,
    required this.calculatedAmount,
    this.advanceDeducted = 0.0,
    this.dieselDeducted = 0.0,
    required this.netAmount,
    required this.calculatedAt,
    this.calculatedBy,
    this.notes,
    required this.createdAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'driver_id': driverId,
      'calculation_type': calculationType,
      'rate': rate,
      'quantity': quantity,
      'calculated_amount': calculatedAmount,
      'advance_deducted': advanceDeducted,
      'diesel_deducted': dieselDeducted,
      'net_amount': netAmount,
      'calculated_at': calculatedAt.toIso8601String(),
      'calculated_by': calculatedBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory SilakCalculationModel.fromJson(Map<String, dynamic> json) {
    return SilakCalculationModel(
      id: json['id'],
      tripId: json['trip_id'],
      driverId: json['driver_id'],
      calculationType: json['calculation_type'],
      rate: (json['rate'] ?? 0.0).toDouble(),
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      calculatedAmount: (json['calculated_amount'] ?? 0.0).toDouble(),
      advanceDeducted: (json['advance_deducted'] ?? 0.0).toDouble(),
      dieselDeducted: (json['diesel_deducted'] ?? 0.0).toDouble(),
      netAmount: (json['net_amount'] ?? 0.0).toDouble(),
      calculatedAt: DateTime.parse(json['calculated_at']),
      calculatedBy: json['calculated_by'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Copy with method for updates
  SilakCalculationModel copyWith({
    String? id,
    String? tripId,
    String? driverId,
    String? calculationType,
    double? rate,
    double? quantity,
    double? calculatedAmount,
    double? advanceDeducted,
    double? dieselDeducted,
    double? netAmount,
    DateTime? calculatedAt,
    String? calculatedBy,
    String? notes,
    DateTime? createdAt,
  }) {
    return SilakCalculationModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      driverId: driverId ?? this.driverId,
      calculationType: calculationType ?? this.calculationType,
      rate: rate ?? this.rate,
      quantity: quantity ?? this.quantity,
      calculatedAmount: calculatedAmount ?? this.calculatedAmount,
      advanceDeducted: advanceDeducted ?? this.advanceDeducted,
      dieselDeducted: dieselDeducted ?? this.dieselDeducted,
      netAmount: netAmount ?? this.netAmount,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      calculatedBy: calculatedBy ?? this.calculatedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  bool get isPerKmCalculation => calculationType == 'per_km';
  bool get isPerLiterCalculation => calculationType == 'per_liter';
  
  String get calculationTypeDisplayName {
    switch (calculationType) {
      case 'per_km':
        return 'Per Kilometer';
      case 'per_liter':
        return 'Per Liter';
      default:
        return 'Unknown';
    }
  }

  String get rateDisplayName {
    switch (calculationType) {
      case 'per_km':
        return '₹${rate.toStringAsFixed(2)}/km';
      case 'per_liter':
        return '₹${rate.toStringAsFixed(2)}/liter';
      default:
        return '₹${rate.toStringAsFixed(2)}';
    }
  }

  String get quantityDisplayName {
    switch (calculationType) {
      case 'per_km':
        return '${quantity.toStringAsFixed(2)} km';
      case 'per_liter':
        return '${quantity.toStringAsFixed(2)} liters';
      default:
        return quantity.toStringAsFixed(2);
    }
  }
}

enum SilakCalculationType {
  perKm('per_km', 'Per Kilometer', 'Silak calculated based on distance traveled'),
  perLiter('per_liter', 'Per Liter', 'Silak calculated based on diesel consumed');

  const SilakCalculationType(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}


