class UserModel {
  final int id;
  final String auth0Id;
  final String email;
  final String? phone;
  final String fullName;
  final String? dateOfBirth;
  final String? gender; // 'male' | 'female' | 'other'
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String createdAt;
  final String updatedAt;
  final bool isActive;
  final int? age;

  const UserModel({
    required this.id,
    required this.auth0Id,
    required this.email,
    this.phone,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.age,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        auth0Id: json['auth0_id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        fullName: json['full_name'] as String? ?? '',
        dateOfBirth: json['date_of_birth'] as String?,
        gender: json['gender'] as String?,
        address: json['address'] as String?,
        emergencyContactName: json['emergency_contact_name'] as String?,
        emergencyContactPhone: json['emergency_contact_phone'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? false,
        age: json['age'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'auth0_id': auth0Id,
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'address': address,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_active': isActive,
        'age': age,
      };
}


