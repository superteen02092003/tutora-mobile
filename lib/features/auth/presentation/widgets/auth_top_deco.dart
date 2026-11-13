import 'package:flutter/material.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Lá cây trang trí góc phải — sau nội dung, không nhận chạm.
class AuthLeaf extends StatelessWidget {
  const AuthLeaf({this.width = 150, super.key});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: const IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: 0.94,
          child: Image(
            image: AssetImage('assets/images/decor/leaf_home.webp'),
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    ),
  );
}

/// Đầu màn đăng nhập / đăng ký — design V5.6: nền giấy, lá cây góc phải (sau
/// chữ), nút tròn quay lại hoặc chữ "TopTutor", một dòng viết tay Charm ở
/// khoảng trống, tiêu đề Bricolage, mô tả Inter.
class AuthTopDeco extends StatelessWidget {
  const AuthTopDeco({
    required this.title,
    super.key,
    this.greeting,
    this.lead,
    this.hand,
    this.showBrand = false,
    this.onBack,
  });

  /// Tiêu đề lớn ("Đăng nhập").
  final String title;

  /// Dòng nhỏ trên tiêu đề (Bricolage thường).
  final String? greeting;

  /// Mô tả dưới tiêu đề.
  final Widget? lead;

  /// Một dòng viết tay ngắn (Charm).
  final String? hand;

  /// Hiện chữ "TopTutor" (chỉ màn đăng nhập).
  final bool showBrand;

  /// Có thì hiện nút tròn quay lại.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Lá cây góc phải, sau nội dung, không bao giờ đè chữ.
        const Positioned(top: 0, right: 0, child: AuthLeaf()),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            14,
            TutorSurface.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    if (onBack != null) CanvasBackButton(onTap: onBack!),
                    if (showBrand)
                      Text('TopTutor', style: TutorType.display(size: 20)),
                  ],
                ),
              ),
              const SizedBox(height: 52),
              if (hand != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 10),
                  child: CanvasHand(hand!, swash: false),
                ),
              if (greeting != null) ...[
                Text(
                  greeting!,
                  style: TutorType.display(size: 17, weight: FontWeight.w400),
                ),
                const SizedBox(height: 4),
              ],
              Text(title, style: TutorType.display(size: 30)),
              if (lead != null) ...[
                const SizedBox(height: 8),
                DefaultTextStyle.merge(
                  style: TutorType.rowSub().copyWith(fontSize: 14),
                  child: lead!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
