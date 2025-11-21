import 'package:flutter/material.dart';

class SkinDiseaseModel {
  final int id;
  final String name;
  final String? nameVi;
  final String? description;
  final List<String> symptoms;
  final String? causes;
  final String? treatment;
  final String? prevention;
  final String? severity; // 'mild', 'moderate', 'severe'
  final bool isCommon;
  final String? createdAt;
  final String? updatedAt;

  const SkinDiseaseModel({
    required this.id,
    required this.name,
    this.nameVi,
    this.description,
    required this.symptoms,
    this.causes,
    this.treatment,
    this.prevention,
    this.severity,
    required this.isCommon,
    this.createdAt,
    this.updatedAt,
  });

  factory SkinDiseaseModel.fromJson(Map<String, dynamic> json) => SkinDiseaseModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        nameVi: json['name_vi'] as String?,
        description: json['description'] as String?,
        symptoms: (json['symptoms'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[],
        causes: json['causes'] as String?,
        treatment: json['treatment'] as String?,
        prevention: json['prevention'] as String?,
        severity: json['severity'] as String?,
        isCommon: json['is_common'] as bool? ?? false,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_vi': nameVi,
        'description': description,
        'symptoms': symptoms,
        'causes': causes,
        'treatment': treatment,
        'prevention': prevention,
        'severity': severity,
        'is_common': isCommon,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String get displayName => nameVi ?? name;

  String get severityText {
    switch (severity?.toLowerCase()) {
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

  Color get severityColor {
    switch (severity?.toLowerCase()) {
      case 'mild':
        return const Color(0xFF16A34A); // green
      case 'moderate':
        return const Color(0xFFEAB308); // yellow
      case 'severe':
        return const Color(0xFFDC2626); // red
      default:
        return const Color(0xFF64748B); // gray
    }
  }
}

/// Top prediction model for displaying alternative predictions
class TopPredictionModel {
  final String diseaseName;
  final SkinDiseaseModel? disease;
  final double confidence;
  final int rank;

  const TopPredictionModel({
    required this.diseaseName,
    this.disease,
    required this.confidence,
    required this.rank,
  });

  factory TopPredictionModel.fromJson(Map<String, dynamic> json) {
    SkinDiseaseModel? disease;
    if (json['disease'] != null) {
      disease = SkinDiseaseModel.fromJson(
        json['disease'] as Map<String, dynamic>,
      );
    }

    return TopPredictionModel(
      diseaseName: json['disease_name'] as String? ?? '',
      disease: disease,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] as int? ?? 0,
    );
  }

  double get confidencePercent => confidence * 100;
}

/// Prediction result model
class PredictionResultModel {
  final int id;
  final int userId;
  final String imagePath;
  final SkinDiseaseModel? predictedDisease;
  final String? predictedDiseaseName;
  final double? confidence;
  final String? createdAt;
  final List<TopPredictionModel> topPredictions;

  const PredictionResultModel({
    required this.id,
    required this.userId,
    required this.imagePath,
    this.predictedDisease,
    this.predictedDiseaseName,
    this.confidence,
    this.createdAt,
    this.topPredictions = const [],
  });

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    SkinDiseaseModel? predictedDisease;
    if (json['predicted_disease'] != null) {
      predictedDisease = SkinDiseaseModel.fromJson(
        json['predicted_disease'] as Map<String, dynamic>,
      );
    }

    List<TopPredictionModel> topPredictions = [];
    if (json['top_predictions'] != null) {
      topPredictions = (json['top_predictions'] as List<dynamic>)
          .map((e) => TopPredictionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PredictionResultModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      imagePath: json['image_path'] as String? ?? '',
      predictedDisease: predictedDisease,
      predictedDiseaseName: json['predicted_disease_name'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
      topPredictions: topPredictions,
    );
  }
}

