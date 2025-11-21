import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AIMessage extends StatelessWidget {
  final String content;
  final DateTime timestamp;

  const AIMessage({
    Key? key,
    required this.content,
    required this.timestamp,
  }) : super(key: key);

  String _formatContent(String text) {
    return text
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<b>${m[1]}</b>')
        .replaceAllMapped(RegExp(r'^\* ', multiLine: true), (m) => '• ')
        .replaceAll('. *', '.<br><br>•')
        .replaceAll('Chào bác/cô!', '<b>Chào bác/cô!</b>')
        .replaceAll('Nên tránh:', '<br><b>🚫 Nên tránh:</b>')
        .replaceAll('Để giảm', '<br><b>💡 Để giảm')
        .replaceAll('Uống nhiều', '<br><b>💧 Uống nhiều')
        .replaceAll('Sức khỏe', '<br><b>🏥 Sức khỏe')
        .replaceAll('Ngâm keo', '<br><b>🌿 Ngâm keo')
        .replaceAll('Thức ăn', '<br><b>🍎 Thức ăn')
        .replaceAll('Khói thuốc', '<br><b>🚭 Khói thuốc')
        .replaceAll('Trong trường hợp', '<br><b>⚠️ Trong trường hợp')
        .replaceAll('Chúc bác/cô', '<br><b>🌟 Chúc bác/cô');
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatContent(content);
    final timeText =
        "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD);
    final bgColor2 = isDark ? const Color(0xFF1E4A3E) : const Color(0xFFE8F5E9);
    final borderColor = isDark ? Colors.blue.shade700 : Colors.lightBlueAccent;
    final textColor = isDark ? Colors.grey[200] : Colors.grey[800];
    final dividerColor = isDark ? Colors.blue.shade800 : Colors.blue.shade100;
    final timeColor = isDark ? Colors.blue.shade300 : Colors.blue;
    final warningBg = isDark ? Colors.yellow.shade900.withOpacity(0.3) : Colors.yellow.shade50;
    final warningBorder = isDark ? Colors.yellow.shade800 : Colors.yellow.shade200;
    final warningText = isDark ? Colors.yellow.shade200 : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.blue, Colors.green]),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Html(
                  data: formatted,
                  style: {
                    "body": Style(
                      fontSize: FontSize.medium,
                      color: textColor,
                      whiteSpace: WhiteSpace.normal,
                      margin: Margins.zero,
                    ),
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: dividerColor),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: timeColor),
              const SizedBox(width: 4),
              Text(
                timeText,
                style: TextStyle(fontSize: 11, color: timeColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: warningBg,
              border: Border.all(color: warningBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '⚠️ Lưu ý: Đây chỉ là tư vấn sơ bộ. Vui lòng tham khảo ý kiến bác sĩ chuyên khoa để được chẩn đoán và điều trị chính xác.',
              style: TextStyle(fontSize: 12, color: warningText),
            ),
          ),
        ],
      ),
    );
  }
}
