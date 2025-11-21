import 'package:flutter/material.dart';
import '../../styles/theme.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [AppColors.primary, AppColors.primary700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      "Hệ thống chăm sóc sức khỏe người cao tuổi",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "Hệ thống hỗ trợ theo dõi và chăm sóc sức khỏe toàn diện, giúp người cao tuổi và gia đình quản lý sức khỏe dễ dàng, hiệu quả.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0EA5E9),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: const Text("Đăng ký miễn phí", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          child: const Text(
                            "Đăng nhập",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Features section
              const _FeaturesSection(),

              // Stats section
              const _StatsSection(),

              // CTA section
              const _CtaSection(),

              // Footer - nằm cuối trang
              const _FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.favorite,
        'title': 'Theo dõi sức khỏe',
        'desc': 'Ghi nhận các chỉ số: huyết áp, đường huyết, nhịp tim...'
      },
      {
        'icon': Icons.show_chart,
        'title': 'Biểu đồ trực quan',
        'desc': 'Xem biểu đồ thay đổi sức khỏe theo thời gian.'
      },
      {
        'icon': Icons.alarm,
        'title': 'Nhắc nhở thông minh',
        'desc': 'Nhắc uống thuốc và lịch khám đúng giờ.'
      },
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'Tư vấn AI',
        'desc': 'Chatbot AI hỗ trợ 24/7, sẵn sàng giúp bạn.'
      },
      {
        'icon': Icons.verified_user,
        'title': 'Bảo mật cao',
        'desc': 'Dữ liệu được bảo vệ với công nghệ mã hóa.'
      },
      {
        'icon': Icons.groups,
        'title': 'Dễ sử dụng',
        'desc': 'Giao diện thân thiện, phù hợp người cao tuổi.'
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Column(
        children: [
          const Text(
            "Tính năng nổi bật",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Những gì bạn cần để chăm sóc sức khỏe tốt nhất",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final f = features[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        f['icon'] as IconData,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      f['title'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      f['desc'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 2,
            ),
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text("Khám phá ngay", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    final stats = const [
      {'name': 'Người dùng tin tưởng', 'value': '1,000+'},
      {'name': 'Chỉ số sức khỏe được theo dõi', 'value': '50,000+'},
      {'name': 'Lời nhắc đã gửi', 'value': '100,000+'},
      {'name': 'Tư vấn AI', 'value': '24/7'},
    ];

    return Container(
      color: const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Được tin tưởng bởi hàng nghìn người dùng',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hệ thống đã giúp nhiều gia đình chăm sóc sức khỏe người thân hiệu quả',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final s = stats[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s['value'] as String,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s['name'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Sẵn sàng bắt đầu chăm sóc sức khỏe?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Đăng ký ngay hôm nay để trải nghiệm hệ thống chăm sóc sức khỏe thông minh và toàn diện.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFE0F2FE), fontSize: 15),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Đăng ký miễn phí', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text(
                  'Đã có tài khoản? Đăng nhập',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1F2937),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          // Logo/Brand
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Hệ thống SứcKhỏe",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Description
          const Text(
            "Hệ thống hỗ trợ chăm sóc sức khỏe người cao tuổi toàn diện",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          // Links
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              _FooterLink(text: "Về chúng tôi", onTap: () {}),
              _FooterLink(text: "Liên hệ", onTap: () {}),
              _FooterLink(text: "Chính sách bảo mật", onTap: () {}),
              _FooterLink(text: "Điều khoản sử dụng", onTap: () {}),
            ],
          ),
          const SizedBox(height: 32),
          
          // Divider
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 24),
          
          // Copyright and Contact
          Column(
            children: [
              const Text(
                "© 2025 Hệ thống SứcKhỏe. Tất cả quyền được bảo lưu.",
                style: TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 14, color: Colors.white60),
                  const SizedBox(width: 6),
                  const Text(
                    "support@suckhoe.vn",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.white60),
                  const SizedBox(width: 6),
                  const Text(
                    "Hotline: 1900-xxxx",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white70,
          ),
        ),
      ),
    );
  }
}
