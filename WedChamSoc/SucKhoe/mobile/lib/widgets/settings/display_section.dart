import 'package:flutter/material.dart';
import 'settings_section_card.dart';

/// Widget for display settings section
class DisplaySection extends StatelessWidget {
  final String fontSize;
  final String theme;
  final String language;
  final ValueChanged<String> onFontSizeChanged;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const DisplaySection({
    super.key,
    required this.fontSize,
    required this.theme,
    required this.language,
    required this.onFontSizeChanged,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items,
            onChanged: onChanged,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Hiển thị',
      icon: Icons.visibility,
      children: [
        _buildDropdownTile(
          title: 'Kích thước chữ',
          value: fontSize,
          items: const [
            DropdownMenuItem(value: 'small', child: Text('Nhỏ')),
            DropdownMenuItem(value: 'medium', child: Text('Vừa')),
            DropdownMenuItem(value: 'large', child: Text('Lớn')),
            DropdownMenuItem(value: 'extra-large', child: Text('Rất lớn')),
          ],
          onChanged: (v) => v != null ? onFontSizeChanged(v) : null,
        ),
        _buildDropdownTile(
          title: 'Giao diện',
          value: theme,
          items: const [
            DropdownMenuItem(value: 'light', child: Text('Sáng')),
            DropdownMenuItem(value: 'dark', child: Text('Tối')),
            DropdownMenuItem(value: 'auto', child: Text('Tự động')),
          ],
          onChanged: (v) => v != null ? onThemeChanged(v) : null,
        ),
        _buildDropdownTile(
          title: 'Ngôn ngữ',
          value: language,
          items: const [
            DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (v) => v != null ? onLanguageChanged(v) : null,
        ),
      ],
    );
  }
}

