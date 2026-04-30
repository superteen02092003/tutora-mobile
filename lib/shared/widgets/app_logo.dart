import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 15});

  final double size;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'TUTORA',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: size,
              letterSpacing: 0.18 * size,
              color: AppColors.ink,
            ),
          ),
          // TextSpan(
          //   text: '',
          //   style: GoogleFonts.bricolageGrotesque(
          //     fontWeight: FontWeight.w800,
          //     fontSize: size,
          //     letterSpacing: 0.18 * size,
          //     color: AppColors.oxblood,
          //   ),
          // ),
        ],
      ),
    );
  }
}
