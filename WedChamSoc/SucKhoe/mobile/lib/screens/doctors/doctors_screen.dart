import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../api/api_client.dart';
import '../../api/doctors_service.dart';
import '../../styles/theme.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final _service = DoctorsService(ApiClient());
  final _searchController = TextEditingController();

  List<DoctorModel> _doctors = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Dịch vụ định vị chưa được bật';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Quyền truy cập vị trí bị từ chối';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Quyền truy cập vị trí bị từ chối vĩnh viễn';
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // Load nearby doctors
      await _loadNearbyDoctors();
    } catch (e) {
      setState(() {
        _error = 'Không thể lấy vị trí: $e';
      });
      // Still try to load doctors without location
      await _loadNearbyDoctors();
    }
  }

  Future<void> _loadNearbyDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<DoctorModel> doctors;
      
      if (_currentPosition != null) {
        doctors = await _service.findNearbyDoctors(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          maxDistanceKm: 10.0,
          limit: 20,
        );
      } else {
        // Load without location filter
        doctors = await _service.findNearbyDoctors(
          limit: 20,
        );
      }

      if (!mounted) return;
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải danh sách bác sĩ: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      await _loadNearbyDoctors();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doctors = await _service.searchDoctors(query: query);
      if (!mounted) return;
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tìm kiếm: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tìm Bác Sĩ'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bác sĩ, phòng khám...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _handleSearch,
                  icon: const Icon(Icons.search),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          // Error message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.healthDanger.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.healthDanger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.healthDanger),
                    ),
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_doctors.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_hospital_outlined,
                      size: 64,
                      color: AppColors.elderlyTextLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy bác sĩ',
                      style: TextStyle(
                        color: AppColors.elderlyTextLight,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Doctors list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _doctors.length,
                itemBuilder: (context, index) {
                  final doctor = _doctors[index];
                  return _buildDoctorCard(doctor);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showDoctorDetails(doctor);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (doctor.specialty != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            doctor.specialty!,
                            style: TextStyle(
                              color: AppColors.elderlyTextLight,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (doctor.distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doctor.distanceText,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.elderlyTextLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      doctor.address,
                      style: TextStyle(
                        color: AppColors.elderlyTextLight,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              if (doctor.phone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: AppColors.elderlyTextLight),
                    const SizedBox(width: 4),
                    Text(
                      doctor.phone!,
                      style: TextStyle(
                        color: AppColors.elderlyTextLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
              if (doctor.rating > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${doctor.rating.toStringAsFixed(1)} (${doctor.reviewCount} đánh giá)',
                      style: TextStyle(
                        color: AppColors.elderlyTextLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDoctorDetails(DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.grey[700] 
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                doctor.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (doctor.specialty != null) ...[
                const SizedBox(height: 8),
                Text(
                  doctor.specialty!,
                  style: TextStyle(
                    color: AppColors.elderlyTextLight,
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildDetailRow(Icons.location_on, doctor.address),
              if (doctor.phone != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.phone, doctor.phone!),
              ],
              if (doctor.email != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.email, doctor.email!),
              ],
              if (doctor.rating > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '${doctor.rating.toStringAsFixed(1)} (${doctor.reviewCount} đánh giá)',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
              if (doctor.priceRange != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.attach_money, doctor.priceRange!),
              ],
              if (doctor.distance != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open map/directions
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng chỉ đường đang phát triển')),
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: Text('Chỉ đường (${doctor.distanceText})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.elderlyTextLight),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

