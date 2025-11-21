import 'package:flutter/material.dart';

/// Health types configuration constants
class HealthConstants {
  static const List<Map<String, dynamic>> healthTypes = [
    {
      'type': 'blood_pressure',
      'name': 'Huyết áp',
      'unit': 'mmHg',
      'icon': '❤️',
      'color': Colors.red,
    },
    {
      'type': 'blood_sugar',
      'name': 'Đường huyết',
      'unit': 'mg/dL',
      'icon': '🩸',
      'color': Colors.blue,
    },
    {
      'type': 'weight',
      'name': 'Cân nặng',
      'unit': 'kg',
      'icon': '⚖️',
      'color': Colors.green,
    },
    {
      'type': 'heart_rate',
      'name': 'Nhịp tim',
      'unit': 'bpm',
      'icon': '💓',
      'color': Colors.purple,
    },
  ];

  static Map<String, dynamic> getTypeConfig(String type) {
    return healthTypes.firstWhere(
      (t) => t['type'] == type,
      orElse: () => healthTypes[0],
    );
  }
}

