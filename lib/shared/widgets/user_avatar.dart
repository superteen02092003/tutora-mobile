import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.size = 36, this.imageUrl});

  final String name;
  final double size;
  final String? imageUrl;

  static const _palette = [
    Color(0xFFE8DCC4),
    Color(0xFFD9C7A8),
    Color(0xFFCDD6CF),
    Color(0xFFE0D2C7),
    Color(0xFFD8DCE6),
  ];

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color get _bg {
    final idx = (name.isEmpty ? 0 : name.codeUnitAt(0)) % _palette.length;
    return _palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bg,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: imageUrl == null
          ? Text(
              _initials,
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
                color: AppColors.ink,
              ),
            )
          : null,
    );
  }
}
