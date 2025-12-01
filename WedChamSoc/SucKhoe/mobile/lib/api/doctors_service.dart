import 'api_client.dart';

class DoctorsService {
  DoctorsService(this._api);

  final ApiClient _api;

  /// Tìm bác sĩ gần nhất - không cần đăng nhập
  Future<List<DoctorModel>> findNearbyDoctors({
    double? latitude,
    double? longitude,
    String? address,
    String? specialty,
    double maxDistanceKm = 10.0,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
      if (specialty != null) 'specialty': specialty,
      'max_distance_km': maxDistanceKm,
      'limit': limit,
    };

    final data = await _api.get<List<dynamic>>(
      '/doctors/nearby',
      query: query,
      requireAuth: false, // Không cần đăng nhập
    );

    return data
        .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Tìm kiếm bác sĩ theo từ khóa
  Future<List<DoctorModel>> searchDoctors({
    required String query,
    int limit = 20,
  }) async {
    final data = await _api.get<List<dynamic>>(
      '/doctors/search',
      query: {'q': query, 'limit': limit},
      requireAuth: false,
    );

    return data
        .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy thông tin chi tiết bác sĩ
  Future<DoctorModel> getDoctor(int doctorId) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/doctors/$doctorId',
      requireAuth: false,
    );
    return DoctorModel.fromJson(data);
  }
}

class DoctorModel {
  final int id;
  final String name;
  final String? specialty;
  final String? clinicName;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int reviewCount;
  final String? priceRange;
  final Map<String, dynamic>? openingHours;
  final bool isActive;
  final double? distance; // Khoảng cách tính từ vị trí người dùng (km)

  DoctorModel({
    required this.id,
    required this.name,
    this.specialty,
    this.clinicName,
    required this.address,
    this.phone,
    this.email,
    this.website,
    this.latitude,
    this.longitude,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.priceRange,
    this.openingHours,
    this.isActive = true,
    this.distance,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as int,
      name: json['name'] as String,
      specialty: json['specialty'] as String?,
      clinicName: json['clinic_name'] as String?,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      priceRange: json['price_range'] as String?,
      openingHours: json['opening_hours'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? true,
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
    );
  }

  String get displayName => clinicName != null ? '$name - $clinicName' : name;
  
  String get distanceText {
    if (distance == null) return 'Không xác định';
    if (distance! < 1) {
      return '${(distance! * 1000).toStringAsFixed(0)}m';
    }
    return '${distance!.toStringAsFixed(1)}km';
  }
}

