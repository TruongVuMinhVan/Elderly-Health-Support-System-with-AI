enum RecordType { bloodPressure, heartRate, bloodSugar, weight, temperature }

RecordType recordTypeFromString(String value) {
  switch (value) {
    case 'blood_pressure':
      return RecordType.bloodPressure;
    case 'heart_rate':
      return RecordType.heartRate;
    case 'blood_sugar':
      return RecordType.bloodSugar;
    case 'weight':
      return RecordType.weight;
    case 'temperature':
      return RecordType.temperature;
    default:
      return RecordType.weight; // fallback
  }
}

String recordTypeToString(RecordType type) {
  switch (type) {
    case RecordType.bloodPressure:
      return 'blood_pressure';
    case RecordType.heartRate:
      return 'heart_rate';
    case RecordType.bloodSugar:
      return 'blood_sugar';
    case RecordType.weight:
      return 'weight';
    case RecordType.temperature:
      return 'temperature';
  }
}

class HealthProfileModel {
  final int id;
  final int userId;
  final double? height;
  final String? bloodType;
  final List<String> chronicDiseases;
  final List<String> allergies;
  final List<String> currentMedications;
  final String? medicalNotes;
  final String? doctorName;
  final String? doctorPhone;
  final String? insuranceInfo;
  final String createdAt;
  final String updatedAt;

  const HealthProfileModel({
    required this.id,
    required this.userId,
    this.height,
    this.bloodType,
    required this.chronicDiseases,
    required this.allergies,
    required this.currentMedications,
    this.medicalNotes,
    this.doctorName,
    this.doctorPhone,
    this.insuranceInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthProfileModel.fromJson(Map<String, dynamic> json) => HealthProfileModel(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        height: (json['height'] as num?)?.toDouble(),
        bloodType: json['blood_type'] as String?,
        chronicDiseases: (json['chronic_diseases'] as List?)?.cast<String>() ?? const <String>[],
        allergies: (json['allergies'] as List?)?.cast<String>() ?? const <String>[],
        currentMedications: (json['current_medications'] as List?)?.cast<String>() ?? const <String>[],
        medicalNotes: json['medical_notes'] as String?,
        doctorName: json['doctor_name'] as String?,
        doctorPhone: json['doctor_phone'] as String?,
        insuranceInfo: json['insurance_info'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'height': height,
        'blood_type': bloodType,
        'chronic_diseases': chronicDiseases,
        'allergies': allergies,
        'current_medications': currentMedications,
        'medical_notes': medicalNotes,
        'doctor_name': doctorName,
        'doctor_phone': doctorPhone,
        'insurance_info': insuranceInfo,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class HealthRecordModel {
  final int id;
  final int userId;
  final RecordType recordType;
  final int? systolicPressure;
  final int? diastolicPressure;
  final int? heartRate;
  final double? bloodSugar;
  final double? weight;
  final double? temperature;
  final String? notes;
  final String recordedAt;
  final String createdAt;
  final String displayValue;
  final bool isNormal;

  const HealthRecordModel({
    required this.id,
    required this.userId,
    required this.recordType,
    this.systolicPressure,
    this.diastolicPressure,
    this.heartRate,
    this.bloodSugar,
    this.weight,
    this.temperature,
    this.notes,
    required this.recordedAt,
    required this.createdAt,
    required this.displayValue,
    required this.isNormal,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) => HealthRecordModel(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        recordType: recordTypeFromString(json['record_type'] as String? ?? ''),
        systolicPressure: json['systolic_pressure'] as int?,
        diastolicPressure: json['diastolic_pressure'] as int?,
        heartRate: json['heart_rate'] as int?,
        bloodSugar: (json['blood_sugar'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        temperature: (json['temperature'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        recordedAt: json['recorded_at'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        displayValue: json['display_value'] as String? ?? '',
        isNormal: json['is_normal'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'record_type': recordTypeToString(recordType),
        'systolic_pressure': systolicPressure,
        'diastolic_pressure': diastolicPressure,
        'heart_rate': heartRate,
        'blood_sugar': bloodSugar,
        'weight': weight,
        'temperature': temperature,
        'notes': notes,
        'recorded_at': recordedAt,
        'created_at': createdAt,
        'display_value': displayValue,
        'is_normal': isNormal,
      };
}


