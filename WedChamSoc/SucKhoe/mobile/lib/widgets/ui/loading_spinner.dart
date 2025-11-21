import 'package:flutter/material.dart';

/// Loading spinner (convert từ React LoadingSpinner)
/// Dùng: LoadingSpinner(size: SpinnerSize.md)
enum SpinnerSize { sm, md, lg }

class LoadingSpinner extends StatelessWidget {
  final SpinnerSize size;
  final Color color;

  const LoadingSpinner({
    Key? key,
    this.size = SpinnerSize.md,
    this.color = Colors.teal,
  }) : super(key: key);

  double _mapSize() {
    switch (size) {
      case SpinnerSize.sm:
        return 16;
      case SpinnerSize.lg:
        return 48;
      default:
        return 32;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spinnerSize = _mapSize();
    return SizedBox(
      height: spinnerSize,
      width: spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
