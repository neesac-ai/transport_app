class SilakModel {
  final String id;
  final String tripId;
  final double fuelAllowancePerKm;
  final double foodAllowancePerKm;
  final double stayAllowancePerKm;
  final double otherAllowancePerKm;
  final String? otherAllowanceDescription;
  final double totalFuelAllowance;
  final double totalFoodAllowance;
  final double totalStayAllowance;
  final double totalOtherAllowance;
  final double totalAllowance;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SilakModel({
    required this.id,
    required this.tripId,
    this.fuelAllowancePerKm = 0.0,
    this.foodAllowancePerKm = 0.0,
    this.stayAllowancePerKm = 0.0,
    this.otherAllowancePerKm = 0.0,
    this.otherAllowanceDescription,
    required this.totalFuelAllowance,
    required this.totalFoodAllowance,
    required this.totalStayAllowance,
    required this.totalOtherAllowance,
    required this.totalAllowance,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'fuel_allowance_per_km': fuelAllowancePerKm,
      'food_allowance_per_km': foodAllowancePerKm,
      'stay_allowance_per_km': stayAllowancePerKm,
      'other_allowance_per_km': otherAllowancePerKm,
      'other_allowance_description': otherAllowanceDescription,
      'total_fuel_allowance': totalFuelAllowance,
      'total_food_allowance': totalFoodAllowance,
      'total_stay_allowance': totalStayAllowance,
      'total_other_allowance': totalOtherAllowance,
      'total_allowance': totalAllowance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory SilakModel.fromJson(Map<String, dynamic> json) {
    return SilakModel(
      id: json['id'],
      tripId: json['trip_id'],
      fuelAllowancePerKm: (json['fuel_allowance_per_km'] ?? 0.0).toDouble(),
      foodAllowancePerKm: (json['food_allowance_per_km'] ?? 0.0).toDouble(),
      stayAllowancePerKm: (json['stay_allowance_per_km'] ?? 0.0).toDouble(),
      otherAllowancePerKm: (json['other_allowance_per_km'] ?? 0.0).toDouble(),
      otherAllowanceDescription: json['other_allowance_description'],
      totalFuelAllowance: (json['total_fuel_allowance'] ?? 0.0).toDouble(),
      totalFoodAllowance: (json['total_food_allowance'] ?? 0.0).toDouble(),
      totalStayAllowance: (json['total_stay_allowance'] ?? 0.0).toDouble(),
      totalOtherAllowance: (json['total_other_allowance'] ?? 0.0).toDouble(),
      totalAllowance: (json['total_allowance'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Copy with method for updates
  SilakModel copyWith({
    String? id,
    String? tripId,
    double? fuelAllowancePerKm,
    double? foodAllowancePerKm,
    double? stayAllowancePerKm,
    double? otherAllowancePerKm,
    String? otherAllowanceDescription,
    double? totalFuelAllowance,
    double? totalFoodAllowance,
    double? totalStayAllowance,
    double? totalOtherAllowance,
    double? totalAllowance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SilakModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      fuelAllowancePerKm: fuelAllowancePerKm ?? this.fuelAllowancePerKm,
      foodAllowancePerKm: foodAllowancePerKm ?? this.foodAllowancePerKm,
      stayAllowancePerKm: stayAllowancePerKm ?? this.stayAllowancePerKm,
      otherAllowancePerKm: otherAllowancePerKm ?? this.otherAllowancePerKm,
      otherAllowanceDescription: otherAllowanceDescription ?? this.otherAllowanceDescription,
      totalFuelAllowance: totalFuelAllowance ?? this.totalFuelAllowance,
      totalFoodAllowance: totalFoodAllowance ?? this.totalFoodAllowance,
      totalStayAllowance: totalStayAllowance ?? this.totalStayAllowance,
      totalOtherAllowance: totalOtherAllowance ?? this.totalOtherAllowance,
      totalAllowance: totalAllowance ?? this.totalAllowance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate totals based on distance
  factory SilakModel.calculate({
    required String id,
    required String tripId,
    required double distanceKm,
    required double fuelAllowancePerKm,
    required double foodAllowancePerKm,
    required double stayAllowancePerKm,
    required double otherAllowancePerKm,
    String? otherAllowanceDescription,
  }) {
    final totalFuelAllowance = distanceKm * fuelAllowancePerKm;
    final totalFoodAllowance = distanceKm * foodAllowancePerKm;
    final totalStayAllowance = distanceKm * stayAllowancePerKm;
    final totalOtherAllowance = distanceKm * otherAllowancePerKm;
    final totalAllowance = totalFuelAllowance + totalFoodAllowance + totalStayAllowance + totalOtherAllowance;

    return SilakModel(
      id: id,
      tripId: tripId,
      fuelAllowancePerKm: fuelAllowancePerKm,
      foodAllowancePerKm: foodAllowancePerKm,
      stayAllowancePerKm: stayAllowancePerKm,
      otherAllowancePerKm: otherAllowancePerKm,
      otherAllowanceDescription: otherAllowanceDescription,
      totalFuelAllowance: totalFuelAllowance,
      totalFoodAllowance: totalFoodAllowance,
      totalStayAllowance: totalStayAllowance,
      totalOtherAllowance: totalOtherAllowance,
      totalAllowance: totalAllowance,
      createdAt: DateTime.now(),
    );
  }
}

