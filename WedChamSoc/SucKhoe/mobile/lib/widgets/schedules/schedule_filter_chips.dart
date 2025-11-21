import 'package:flutter/material.dart';

/// Widget for schedule filter chips
class ScheduleFilterChips extends StatelessWidget {
  final List<Map<String, dynamic>> filters;
  final String? selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const ScheduleFilterChips({
    super.key,
    required this.filters,
    this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((f) {
        final value = f['value'] as String;
        final isSelected = selectedFilter == value;
        return FilterChip(
          label: Text(f['label'] as String),
          onSelected: (_) => onFilterChanged(value),
          selected: isSelected,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }
}

