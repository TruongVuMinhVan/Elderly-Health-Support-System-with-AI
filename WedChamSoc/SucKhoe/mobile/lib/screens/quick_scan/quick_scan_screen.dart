import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/api_client.dart';
import '../../api/quick_scan_service.dart';
import '../../styles/theme.dart';
import '../auth/login_screen.dart';

class QuickScanScreen extends StatefulWidget {
  const QuickScanScreen({super.key});

  @override
  State<QuickScanScreen> createState() => _QuickScanScreenState();
}

class _QuickScanScreenState extends State<QuickScanScreen> {
  File? _selectedImage;
  bool _loading = false;
  String? _error;
  QuickScanResult? _result;

  final ImagePicker _picker = ImagePicker();
  final QuickScanService _service = QuickScanService(ApiClient());

  Future<void> _pickImageFromGallery() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _error = null;
          _result = null;
        });
        await _scanImage();
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi chọn ảnh: $e';
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _error = null;
          _result = null;
        });
        await _scanImage();
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi chụp ảnh: $e';
      });
    }
  }

  Future<void> _scanImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.quickScan(_selectedImage!);

      if (!mounted) return;

      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error ?? 'Lỗi quét nhanh: $e'),
            backgroundColor: AppColors.healthDanger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _handleSaveResult() {
    // Yêu cầu đăng nhập để lưu kết quả
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chẩn Đoán Nhanh'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark 
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Colors.grey[100],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 64,
                              color: AppColors.elderlyTextLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa chọn ảnh',
                              style: TextStyle(
                                color: AppColors.elderlyTextLight,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (_selectedImage == null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Chọn từ thư viện'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp ảnh'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (!_loading) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _result = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Chọn ảnh khác'),
                    ),
                  ),
                ],
              ),
            ],

            // Loading indicator
            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Center(
                child: Text('Đang phân tích...'),
              ),
            ],

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 24),
              Card(
                color: AppColors.healthDanger.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.healthDanger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppColors.healthDanger),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Result
            if (_result != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.healthNormal,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _result!.predictedDiseaseName ?? 'Không xác định',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_result!.confidence != null)
                                  Text(
                                    'Độ tin cậy: ${(_result!.confidence! * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: AppColors.elderlyTextLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_result!.severity != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(_result!.severity!)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Mức độ: ${_getSeverityText(_result!.severity!)}',
                            style: TextStyle(
                              color: _getSeverityColor(_result!.severity!),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (_result!.requiresLogin) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _handleSaveResult,
                          icon: const Icon(Icons.save),
                          label: const Text('Đăng nhập để lưu kết quả'),
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
            ],
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return AppColors.healthNormal;
      case 'moderate':
        return AppColors.healthWarning;
      case 'severe':
        return AppColors.healthDanger;
      default:
        return AppColors.elderlyTextLight;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return 'Nhẹ';
      case 'moderate':
        return 'Trung bình';
      case 'severe':
        return 'Nghiêm trọng';
      default:
        return 'Chưa xác định';
    }
  }
}

