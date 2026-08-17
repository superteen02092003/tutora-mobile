import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

/// Header dùng chung cho các màn con: nút back + tiêu đề căn giữa.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    required this.title,
    super.key,
    this.onBack,
    this.trailing,
    this.showBack = true,
  });

  final String title;

  /// Mặc định là pop; truyền vào khi cần chặn/xử lý trước lúc thoát.
  final VoidCallback? onBack;

  /// Nút phụ bên phải (nếu không có thì chừa chỗ để tiêu đề vẫn cân giữa).
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (showBack)
            _CircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack ?? () => Navigator.of(context).pop(),
            )
          else
            const SizedBox(width: 36),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: AppColors.ink,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
      ),
      child: Icon(icon, size: 15, color: AppColors.ink),
    ),
  );
}
