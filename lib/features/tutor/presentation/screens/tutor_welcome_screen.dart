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

/// T1 Chào mừng (design V5.6, board V56-Welcome) — lần mở đầu tiên sau khi
/// đăng nhập (và "Xem lại" từ Cài đặt). Không logo. Ba bước: thêm học sinh,
/// ghi âm có đồng ý, duyệt báo cáo; mỗi bước kèm chỗ bấm trong app (Khánh,
/// 2026-11-12: gia sư mới không biết tạo lớp và ghi âm ở đâu).
class TutorWelcomeScreen extends ConsumerWidget {
  const TutorWelcomeScreen({super.key});

  static const List<(String, String)> _steps = [
    ('Thêm học sinh', 'Trang chủ · Học sinh của bạn · +'),
    ('Ghi âm từng buổi, khi phụ huynh đồng ý', 'Bài học · Bắt đầu ghi âm'),
    ('Duyệt báo cáo trước khi gửi', 'Trang chủ · Duyệt ngay'),
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
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    72,
                    TutorSurface.gutter,
                    16,
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 2, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CanvasHand('Rất vui được gặp bạn', swash: false),
                      ),
                    ),
                    Text(
                      given.isEmpty ? 'Chào mừng' : 'Chào mừng,',
                      style: TutorType.display(
                        size: 17,
                        weight: FontWeight.w400,
                      ),
                    ),
                    if (given.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(given, style: TutorType.name()),
                    ],
                    const SizedBox(height: 8),
                    Text('Ghi âm. Duyệt. Tiến bộ.', style: TutorType.rowSub()),
                    const SizedBox(height: 34),
                    Stack(
                      children: [
                        // Đường thời gian dọc nối các bước.
                        const Positioned(
                          left: 11.5,
                          top: 24,
                          bottom: 24,
                          child: SizedBox(
                            width: 1,
                            child: ColoredBox(color: Color(0x241F2A24)),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < _steps.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _StepDot(number: i + 1, on: i == 0),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _steps[i].$1,
                                            style: TutorType.body(),
                                          ),
                                          Text(
                                            _steps[i].$2,
                                            style: TutorType.rowSub(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  12,
                  TutorSurface.gutter,
                  20,
                ),
                child: Column(
                  children: [
                    CanvasCta(
                      label: 'Bắt đầu',
                      onPressed: () => unawaited(_start(context, ref)),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () =>
                          unawaited(context.push(AppRoutes.tutorRecordingTips)),
                      borderRadius: BorderRadius.circular(22),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 16,
                              color: TutorColors.ink,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ghi âm hoạt động thế nào',
                              style: TutorType.rowSub(color: TutorColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Số bước trong vòng tròn 24: đặc (bước đầu) hoặc viền.
class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.on});

  final int number;
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? TutorColors.ink : const Color(0xFFF0EFEA),
      border: on
          ? null
          : Border.all(color: const Color(0xFFA3A8A2), width: 1.4),
    ),
    child: Text(
      '$number',
      style: TutorType.caption(
        color: on ? Colors.white : TutorColors.ink,
      ).copyWith(height: 1),
    ),
  );
}
