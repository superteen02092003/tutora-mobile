import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/features/tutor/data/models/consent_text.dart';

/// Hiện nội dung đồng ý ghi âm để gia sư đưa phụ huynh đọc.
///
/// Khi [askConfirm] = true, trả `true` nếu gia sư bấm "Phụ huynh đã đồng ý".
Future<bool?> showConsentTextDialog(
  BuildContext context, {
  bool askConfirm = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(consentTextTitle),
      content: const SingleChildScrollView(
        child: Text(
          consentTextBody,
          style: TextStyle(fontSize: 14, height: 1.45, color: TutorColors.ink),
        ),
      ),
      actions: askConfirm
          ? [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Chưa'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Phụ huynh đã đồng ý'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
    ),
  );
}
