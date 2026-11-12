import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// T1 Chào mừng — lần mở đầu tiên sau khi đăng nhập (và "Xem lại" từ Cài đặt).
/// Bốn bước: thêm học sinh, ghi âm có đồng ý, duyệt báo cáo, sao khi kỹ năng
/// lên mức. Mỗi bước kèm chỗ bấm trong app (Khánh, 2026-11-12: gia sư mới không
/// biết tạo lớp và ghi âm ở đâu) — thêm so với canvas.
class TutorWelcomeScreen extends ConsumerWidget {
  const TutorWelcomeScreen({super.key});

  static const List<(String, String?)> _steps = [
    (
      'Thêm học sinh của bạn. Học sinh đặt qua TopTutor có sẵn.',
      'Trang chủ › Lớp của bạn › + Thêm học sinh',
    ),
    (
      'Ghi âm mỗi buổi học, khi phụ huynh đã đồng ý.',
      'Tab Ghi âm › Ghi âm buổi học',
    ),
    (
      'Duyệt báo cáo TopTutor soạn sẵn. Bạn duyệt mọi tin nhắn trước khi gửi.',
      'Tab Ghi âm › bản ghi có thẻ Duyệt',
    ),
    ('Một ngôi sao mỗi khi một kỹ năng toán của học sinh lên một mức.', null),
  ];

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    await ref.read(secureStorageProvider).setWelcomeSeen();
    if (!context.mounted) return;
    // Luôn về Trang chủ, kể cả khi mở lại từ Cài đặt (pop sẽ quay về hồ sơ).
    context.go(AppRoutes.tutorHome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(tutorProfileProvider).user?.fullName ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final given = parts.isEmpty ? '' : parts.last;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  CanvasHeader(
                    left: given.isEmpty ? 'Chào mừng' : 'Chào mừng, $given',
                    right: 'Lần đầu',
                    title: 'Ghi âm.\nDuyệt.\nTiến bộ.',
                    titleSize: 52,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: TutorSurface.screenPadding,
                    child: Column(
                      children: [
                        for (var i = 0; i < _steps.length; i++)
                          CanvasRow(
                            lastRule: i == _steps.length - 1,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    '${i + 1}',
                                    style: TutorType.display(
                                      size: 30,
                                      weight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _steps[i].$1,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                          color: TutorColors.ink,
                                        ),
                                      ),
                                      if (_steps[i].$2 != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          _steps[i].$2!,
                                          style:
                                              TutorType.rowSub(
                                                color: TutorColors.warning,
                                              ).copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TutorSurface.gutter,
                16,
                TutorSurface.gutter,
                20,
              ),
              child: Column(
                children: [
                  CanvasCta(
                    label: 'Bắt đầu',
                    onPressed: () => unawaited(_start(context, ref)),
                  ),
                  const SizedBox(height: 8),
                  CanvasGhostLink(
                    label: 'Ghi âm hoạt động thế nào',
                    onTap: () =>
                        unawaited(context.push(AppRoutes.tutorRecordingTips)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
