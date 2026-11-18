import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/consent_text.dart';

/// Hiện nội dung đồng ý ghi âm để gia sư đưa phụ huynh đọc.
///
/// Khi [askConfirm] = true, trả `true` nếu gia sư bấm "Phụ huynh đã đồng ý".
Future<bool?> showConsentTextDialog(
  BuildContext context, {
  bool askConfirm = false,
}) {
  final pill = FilledButton.styleFrom(
    backgroundColor: TutorColors.primary,
    foregroundColor: Colors.white,
    shape: const StadiumBorder(),
    minimumSize: const Size(0, 44),
    textStyle: TutorType.action(),
  );
  final ghost = TextButton.styleFrom(
    foregroundColor: TutorColors.ink3,
    shape: const StadiumBorder(),
    minimumSize: const Size(0, 44),
    textStyle: TutorType.action(),
  );
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: TutorColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TutorSurface.radius),
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3, right: 10),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: TutorColors.ink3,
            ),
          ),
          Expanded(
            child: Text(
              consentTextTitle,
              style: TutorType.display(size: 20),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          consentTextBody,
          style: TutorType.body().copyWith(fontSize: 14, height: 1.5),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: askConfirm
          ? [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: ghost,
                child: const Text('Chưa'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: pill,
                child: const Text('Phụ huynh đã đồng ý'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: ghost,
                child: const Text('Đóng'),
              ),
            ],
    ),
  );
}
