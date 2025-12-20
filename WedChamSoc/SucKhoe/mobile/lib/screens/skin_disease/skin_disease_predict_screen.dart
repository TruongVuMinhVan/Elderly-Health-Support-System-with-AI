import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/skin_disease.dart';
import '../../api/api_client.dart';
import '../../api/skin_disease_service.dart';
import '../../styles/theme.dart';
import 'skin_disease_detail_screen.dart';

class SkinDiseasePredictScreen extends StatefulWidget {
  const SkinDiseasePredictScreen({super.key});

  @override
  State<SkinDiseasePredictScreen> createState() => _SkinDiseasePredictScreenState();
}

class _SkinDiseasePredictScreenState extends State<SkinDiseasePredictScreen> {
  File? _selectedImage;
  bool _loading = false;
  String? _error;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _error = null;
        });
        await _uploadImage();
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
        });
        await _uploadImage();
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi chụp ảnh: $e';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final service = SkinDiseaseService(api);
      final result = await service.predictDisease(_selectedImage!, useTestEndpoint: true);

      if (!mounted) return;

      if (result.predictedDisease == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xác định bệnh. Vui lòng thử lại với ảnh khác.'),
            backgroundColor: AppColors.healthWarning,
          ),
        );
        return;
      }

      // Navigate to detail screen with full prediction result
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SkinDiseaseDetailScreen(
            disease: result.predictedDisease!,
            confidence: result.confidence,
            topPredictions: result.topPredictions,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error ?? 'Lỗi dự đoán: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.elderlyBg,
      appBar: AppBar(
        title: const Text('Dự đoán bệnh ngoài da'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to dashboard
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  color: Colors.grey[100],
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
                              Icons.image_outlined,
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
                            const SizedBox(height: 4),
                            Text(
                              'Chọn ảnh từ thư viện hoặc chụp ảnh mới',
                              style: TextStyle(
                                color: AppColors.elderlyTextLight,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_error != null)
              Card(
                elevation: 0,
                color: AppColors.healthDanger.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.healthDanger.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.healthDanger,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: AppColors.healthDanger,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_error != null) const SizedBox(height: 16),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn ảnh từ thư viện'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp ảnh từ camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Loading indicator
            if (_loading)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Đang phân tích ảnh...',
                    style: TextStyle(
                      color: AppColors.elderlyTextLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

            // Info card
            const Spacer(),
            Card(
              elevation: 0,
              color: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chụp ảnh rõ nét vùng da cần kiểm tra. Kết quả chỉ mang tính chất tham khảo.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.elderlyText,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

