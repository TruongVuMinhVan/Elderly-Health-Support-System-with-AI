class MedicationModel {
  final int id;
  final int userId;
  final String medicationName;
  final String? dosage;
  final String? frequency;
  final String? instructions;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final bool isCurrent;

  const MedicationModel({
    required this.id,
    required this.userId,
    required this.medicationName,
    this.dosage,
    this.frequency,
    this.instructions,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.isCurrent,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) => MedicationModel(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        medicationName: json['medication_name'] as String? ?? '',
        dosage: json['dosage'] as String?,
        frequency: json['frequency'] as String?,
        instructions: json['instructions'] as String?,
        startDate: json['start_date'] as String?,
        endDate: json['end_date'] as String?,
        isActive: json['is_active'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        isCurrent: json['is_current'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'medication_name': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'instructions': instructions,
        'start_date': startDate,
        'end_date': endDate,
        'is_active': isActive,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_current': isCurrent,
      };
}


