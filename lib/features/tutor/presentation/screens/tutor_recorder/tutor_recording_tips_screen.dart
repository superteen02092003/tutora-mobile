import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// T7 · Mẹo ghi âm (design canvas 11/2026): thói quen của tuần trong khối tối,
/// ba điều cơ bản, mục học online và 6 thói quen. Nội dung tĩnh.
class TutorRecordingTipsScreen extends StatelessWidget {
  const TutorRecordingTipsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      GoRouter.of(context).push(AppRoutes.tutorRecordingTips);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            CanvasHeader(
              onBack: () => Navigator.of(context).maybePop(),
              title: 'Mẹo ghi âm',
              titleSize: 40,
              lead: 'Vài thói quen nhỏ cho một bản ghi rõ.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TutorSurface.gutter,
                22,
                TutorSurface.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                    decoration: BoxDecoration(
                      color: TutorColors.ink2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 16,
                              color: TutorColors.accent,
                            ),
                            SizedBox(width: 6),
                            CanvasKicker(
                              'Thói quen của tuần',
                              color: TutorColors.accent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          const TextSpan(
                            children: [
                              TextSpan(text: 'Hỏi xong, '),
                              TextSpan(
                                text: 'đếm thầm đến ba.',
                                style: TextStyle(color: Color(0xFFF2C877)),
                              ),
                            ],
                          ),
                          style: TutorType.display(
                            size: 36,
                            color: Colors.white,
                            height: 1.05,
                          ).copyWith(letterSpacing: -1.2),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Học sinh trả lời dài hơn, và bản ghi nghe rõ em hơn.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFFDCE8E0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (final (i, t) in const [
                    'Điện thoại đặt giữa bàn',
                    'Phòng yên tĩnh',
                    'Pin trên 30% · mang theo sạc',
                  ].indexed)
                    CanvasRow(
                      lastRule: i == 2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${i + 1}',
                              style: TutorType.display(
                                size: 30,
                                weight: FontWeight.w300,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: TutorColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  const CanvasExpander(
                    title: 'Buổi học online',
                    children: [
                      Text(
                        'Dùng loa laptop, không đeo tai nghe, và đặt điện thoại cạnh laptop.',
                      ),
                    ],
                  ),
                  const CanvasExpander(
                    title: 'Đủ 6 thói quen',
                    lastRule: true,
                    children: [
                      Text('1. Bấm ghi âm trước khi chào học sinh'),
                      Text('2. Nhờ học sinh đọc to đề bài'),
                      Text('3. Đọc to những gì bạn viết lên bảng'),
                      Text('4. Hỏi xong, đếm thầm đến ba'),
                      Text('5. Không nói chồng lên học sinh'),
                      Text('6. Học sinh nói nhỏ thì nhờ em nói to hơn'),
                    ],
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
