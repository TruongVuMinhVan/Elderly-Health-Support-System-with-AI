import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, String>? user;
  final VoidCallback? onMenuPressed;

  const Header({Key? key, this.user, this.onMenuPressed}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey[300] : Colors.black87;
    
    return AppBar(
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
        onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
      ),
      title: Row(
        children: [
          Icon(Icons.favorite, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            'SứcKhỏe',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              Icon(Icons.notifications_none, color: iconColor),
              Positioned(
                right: 0,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              )
            ],
          ),
          onPressed: () {},
        ),
        user != null
            ? PopupMenuButton<int>(
          offset: const Offset(0, 60),
          icon: const CircleAvatar(child: Icon(Icons.person)),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 0, child: Text('Hồ sơ cá nhân')),
            const PopupMenuItem(value: 1, child: Text('Cài đặt')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 2, child: Text('Đăng xuất')),
          ],
          onSelected: (value) {
            // TODO: Handle actions
          },
        )
            : TextButton(
          onPressed: () {},
          child: const Text('Đăng nhập'),
        ),
      ],
    );
  }
}
