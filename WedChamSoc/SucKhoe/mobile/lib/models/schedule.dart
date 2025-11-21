enum ScheduleType { medication, appointment, checkup }

ScheduleType scheduleTypeFromString(String value) {
  switch (value) {
    case 'medication':
      return ScheduleType.medication;
    case 'appointment':
      return ScheduleType.appointment;
    case 'checkup':
      return ScheduleType.checkup;
    default:
      return ScheduleType.appointment;
  }
}

String scheduleTypeToString(ScheduleType type) {
  switch (type) {
    case ScheduleType.medication:
      return 'medication';
    case ScheduleType.appointment:
      return 'appointment';
    case ScheduleType.checkup:
      return 'checkup';
  }
}

class ScheduleModel {
  final int id;
  final int userId;
  final ScheduleType scheduleType;
  final String title;
  final String? description;
  final String scheduledDatetime;
  final String? location;
  final String? doctorName;
  final int? medicationId;
  final bool isCompleted;
  final bool isRecurring;
  final String? recurrencePattern;
  final String createdAt;
  final String updatedAt;
  final bool isUpcoming;
  final bool isOverdue;

  const ScheduleModel({
    required this.id,
    required this.userId,
    required this.scheduleType,
    required this.title,
    this.description,
    required this.scheduledDatetime,
    this.location,
    this.doctorName,
    this.medicationId,
    required this.isCompleted,
    required this.isRecurring,
    this.recurrencePattern,
    required this.createdAt,
    required this.updatedAt,
    required this.isUpcoming,
    required this.isOverdue,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        scheduleType: scheduleTypeFromString(json['schedule_type'] as String? ?? ''),
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        scheduledDatetime: json['scheduled_datetime'] as String? ?? '',
        location: json['location'] as String?,
        doctorName: json['doctor_name'] as String?,
        medicationId: json['medication_id'] as int?,
        isCompleted: json['is_completed'] as bool? ?? false,
        isRecurring: json['is_recurring'] as bool? ?? false,
        recurrencePattern: json['recurrence_pattern'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        isUpcoming: json['is_upcoming'] as bool? ?? false,
        isOverdue: json['is_overdue'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'schedule_type': scheduleTypeToString(scheduleType),
        'title': title,
        'description': description,
        'scheduled_datetime': scheduledDatetime,
        'location': location,
        'doctor_name': doctorName,
        'medication_id': medicationId,
        'is_completed': isCompleted,
        'is_recurring': isRecurring,
        'recurrence_pattern': recurrencePattern,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_upcoming': isUpcoming,
        'is_overdue': isOverdue,
      };
}


