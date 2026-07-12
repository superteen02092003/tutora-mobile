import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    super.key,
    this.size = 36,
    this.imageUrl,
    this.square = false,
  });

  final String name;
  final double size;
  final String? imageUrl;

  final bool square;

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

  bool get _isSvg {
    final url = imageUrl;
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.contains('.svg') ||
        lower.contains('/svg') ||
        lower.contains('dicebear');
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        color: _bg,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage ? _buildImage(url) : _fallback(),
    );
  }

  Widget _buildImage(String url) {
    if (_isSvg) {
      return SvgPicture.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _fallback(),
      );
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  Widget _fallback() {
    return Text(
      _initials,
      style: GoogleFonts.bricolageGrotesque(
        fontWeight: FontWeight.w700,
        fontSize: size * 0.36,
        color: AppColors.ink,
      ),
    );
  }
}
