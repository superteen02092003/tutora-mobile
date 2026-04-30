import 'package:flutter/material.dart';
import 'package:tutora/core/constants/app_colors.dart';

class VerifyPip extends StatelessWidget {
  const VerifyPip({super.key, this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 14.0 : 16.0;
    final iconSize = small ? 8.0 : 10.0;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.ink,
      ),
      child: Icon(Icons.check, size: iconSize, color: AppColors.cream),
    );
  }
}
