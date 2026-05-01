import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';

enum AppToastType { defaultType, info, success, error, warning }

/// Global top-positioned toast. Replace ScaffoldMessenger.showSnackBar everywhere.
///
/// Usage:
///   AppToast.show(context, message: 'Đã lưu thành công', type: AppToastType.success);
///   AppToast.show(context, message: 'Lỗi xảy ra', type: AppToastType.error,
class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.defaultType,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _current?.remove();
    _current = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );

    _current = entry;
    Overlay.of(context).insert(entry);
  }
}

class _AppToastWidget extends StatefulWidget {
  const _AppToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    unawaited(_ctrl.forward());
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    unawaited(
      _ctrl.reverse().then((_) {
        if (mounted) widget.onDismiss();
      }),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _ToastConfig.of(widget.type);
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + AppSpacing.sm,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.line2),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(cfg.iconAsset, width: 22, height: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppTextStyles.bodySmall(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.actionLabel != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        widget.onAction?.call();
                        _dismiss();
                      },
                      child: Text(
                        widget.actionLabel!.toUpperCase(),
                        style: AppTextStyles.label(color: cfg.accentColor),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: cfg.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastConfig {
  const _ToastConfig({required this.iconAsset, required this.accentColor});

  factory _ToastConfig.of(AppToastType type) => switch (type) {
    AppToastType.defaultType => const _ToastConfig(
      iconAsset: 'assets/icons/icon_default.png',
      accentColor: AppColors.ink,
    ),
    AppToastType.info => const _ToastConfig(
      iconAsset: 'assets/icons/icon_info.png',
      accentColor: Color(0xFF1976D2),
    ),
    AppToastType.success => const _ToastConfig(
      iconAsset: 'assets/icons/icon_success.png',
      accentColor: AppColors.success,
    ),
    AppToastType.error => const _ToastConfig(
      iconAsset: 'assets/icons/icon_error.png',
      accentColor: AppColors.error,
    ),
    AppToastType.warning => const _ToastConfig(
      iconAsset: 'assets/icons/icon_warning.png',
      accentColor: Color(0xFFB45309),
    ),
  };

  final String iconAsset;
  final Color accentColor;
}
