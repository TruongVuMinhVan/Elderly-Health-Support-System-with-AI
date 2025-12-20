import 'package:flutter/material.dart';

/// Dialog for 2FA verification
class TwoFactorDialog extends StatefulWidget {
  final String? message;
  
  const TwoFactorDialog({super.key, this.message});

  /// Shows the 2FA dialog and returns the OTP entered by the user
  static Future<String?> show(BuildContext context, {String? message}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (ctx) => TwoFactorDialog(message: message),
    );
  }

  @override
  State<TwoFactorDialog> createState() => _TwoFactorDialogState();
}

class _TwoFactorDialogState extends State<TwoFactorDialog> {
  late final TextEditingController _otpController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    if (_isSubmitting) return;
    Navigator.pop(context);
  }

  void _handleSubmit() {
    if (_isSubmitting) return;
    
    final result = _otpController.text.trim();
    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác thực 2 bước'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message ?? 'Vui lòng nhập mã OTP gửi qua email',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Mã OTP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              enabled: !_isSubmitting,
              maxLength: 6,
              onSubmitted: (_) => _handleSubmit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : _handleCancel,
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}

