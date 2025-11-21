import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'settings_section_card.dart';
import 'totp_setup_widget.dart';
import 'totp_disable_widget.dart';
import 'email_2fa_setup_widget.dart';
import 'email_2fa_disable_widget.dart';

/// Widget for 2FA settings section
class TwoFactorSection extends StatelessWidget {
  final bool twoFactorEnabled;
  final bool emailOtpEnabled;
  final String? preferredMethod;
  final bool totpSettingUp;
  final String? totpSecret;
  final Uint8List? qrCodeBytes;
  final String totpVerificationCode;
  final bool email2FASettingUp;
  final String email2FAOtpCode;
  final bool isSendingOtp;
  final ValueChanged<String> onPreferredMethodChanged;
  final VoidCallback onTOTPToggle;
  final VoidCallback onEmail2FAToggle;
  final ValueChanged<String> onTOTPVerificationCodeChanged;
  final VoidCallback onEnableTOTP;
  final VoidCallback onDisableTOTP;
  final ValueChanged<String> onEmail2FAOtpCodeChanged;
  final VoidCallback onEnableEmail2FA;
  final VoidCallback onDisableEmail2FA;
  final VoidCallback onResendEmail2FA;
  final VoidCallback onCancelTOTPSetup;
  final VoidCallback onCancelEmail2FASetup;

  const TwoFactorSection({
    super.key,
    required this.twoFactorEnabled,
    required this.emailOtpEnabled,
    this.preferredMethod,
    required this.totpSettingUp,
    this.totpSecret,
    this.qrCodeBytes,
    required this.totpVerificationCode,
    required this.email2FASettingUp,
    required this.email2FAOtpCode,
    required this.isSendingOtp,
    required this.onPreferredMethodChanged,
    required this.onTOTPToggle,
    required this.onEmail2FAToggle,
    required this.onTOTPVerificationCodeChanged,
    required this.onEnableTOTP,
    required this.onDisableTOTP,
    required this.onEmail2FAOtpCodeChanged,
    required this.onEnableEmail2FA,
    required this.onDisableEmail2FA,
    required this.onResendEmail2FA,
    required this.onCancelTOTPSetup,
    required this.onCancelEmail2FASetup,
  });

  Widget _build2FAMethodCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Xác thực 2 bước (2FA)',
      icon: Icons.security,
      children: [
        // Preferred 2FA Method Selection
        const Text(
          'Phương thức xác thực ưa thích:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _build2FAMethodCard(
                  context: context,
                  title: 'Ứng dụng xác thực',
                  icon: Icons.qr_code,
                  isSelected: preferredMethod == 'totp',
                  onTap: () => onPreferredMethodChanged('totp'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _build2FAMethodCard(
                  context: context,
                  title: 'Email OTP',
                  icon: Icons.email,
                  isSelected: preferredMethod == 'email',
                  onTap: () => onPreferredMethodChanged('email'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // TOTP 2FA
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xác thực bằng ứng dụng (TOTP)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sử dụng ứng dụng xác thực như Google Authenticator',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  twoFactorEnabled ? 'Đã bật' : 'Chưa bật',
                  style: TextStyle(
                    color: twoFactorEnabled ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: twoFactorEnabled,
                  onChanged: (_) => onTOTPToggle(),
                ),
              ],
            ),
          ],
        ),

        // TOTP Setup UI
        if (totpSettingUp && !twoFactorEnabled)
          TOTPSetupWidget(
            qrCodeBytes: qrCodeBytes,
            secret: totpSecret,
            verificationCode: totpVerificationCode,
            onVerificationCodeChanged: onTOTPVerificationCodeChanged,
            onEnable: onEnableTOTP,
            onCancel: onCancelTOTPSetup,
          ),

        // TOTP Disable UI
        if (twoFactorEnabled && !totpSettingUp)
          TOTPDisableWidget(
            verificationCode: totpVerificationCode,
            onVerificationCodeChanged: onTOTPVerificationCodeChanged,
            onDisable: onDisableTOTP,
          ),

        const SizedBox(height: 24),

        // Email 2FA
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xác thực bằng email',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhận mã xác thực qua email',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  emailOtpEnabled ? 'Đã bật' : 'Chưa bật',
                  style: TextStyle(
                    color: emailOtpEnabled ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: emailOtpEnabled,
                  onChanged: (_) => onEmail2FAToggle(),
                ),
              ],
            ),
          ],
        ),

        // Email 2FA Setup UI
        if (email2FASettingUp && !emailOtpEnabled)
          Email2FASetupWidget(
            otpCode: email2FAOtpCode,
            onOtpCodeChanged: onEmail2FAOtpCodeChanged,
            onEnable: onEnableEmail2FA,
            onResend: onResendEmail2FA,
            onCancel: onCancelEmail2FASetup,
            isSendingOtp: isSendingOtp,
          ),

        // Email 2FA Disable UI
        if (emailOtpEnabled && !email2FASettingUp)
          const Email2FADisableWidget(),
      ],
    );
  }
}

