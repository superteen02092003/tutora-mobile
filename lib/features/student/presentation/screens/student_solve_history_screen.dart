import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/student/data/datasources/ai_solve_datasource.dart';
import 'package:tutora/features/student/presentation/providers/ai_solve_provider.dart';

/// Lịch sử các phiên giải toán của user (gắn userId, nạp từ BE).
class StudentSolveHistoryPage extends ConsumerWidget {
  const StudentSolveHistoryPage({required this.onOpenSession, super.key});

  /// Gọi khi bấm 1 phiên — điều hướng sang màn chat với openSessionId.
  final void Function(String sessionId) onOpenSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final async = ref.watch(solveHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          'Lịch sử giải toán',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
        actions: [
          // Xoá tất cả — chỉ hiện khi có phiên.
          async.maybeWhen(
            data: (sessions) => sessions.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Xoá tất cả',
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.ink2,
                    ),
                    onPressed: () => _confirmDeleteAll(context, ref),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: AppColors.line2),
        ),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.oxblood),
        ),
        error: (e, _) => _EmptyOrError(
          icon: Icons.cloud_off_rounded,
          title: 'Không tải được lịch sử',
          subtitle: 'Kiểm tra kết nối và thử lại.',
          onRetry: () => ref.invalidate(solveHistoryProvider),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const _EmptyOrError(
              icon: Icons.history_edu_rounded,
              title: 'Chưa có bài nào',
              subtitle: 'Chụp một bài toán để Tutora giải giúp bạn nhé!',
            );
          }
          return RefreshIndicator(
            color: AppColors.oxblood,
            onRefresh: () async => ref.invalidate(solveHistoryProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const Divider(
                height: 0.5,
                indent: 16,
                color: AppColors.line2,
              ),
              itemBuilder: (context, i) {
                final s = sessions[i];
                // Vuốt SANG TRÁI để lộ nút Xoá (kiểu iOS, như danh sách chat).
                return Slidable(
                  key: ValueKey(s.sessionId),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.28,
                    children: [
                      SlidableAction(
                        onPressed: (_) async {
                          if (await _confirmDeleteOne(context) &&
                              context.mounted) {
                            await _deleteSession(context, ref, s.sessionId);
                          }
                        },
                        backgroundColor: AppColors.oxblood,
                        foregroundColor: Colors.white,
                        icon: Icons.delete_outline_rounded,
                        label: 'Xoá',
                      ),
                    ],
                  ),
                  child: _SessionTile(
                    session: s,
                    onTap: () => onOpenSession(s.sessionId),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDeleteOne(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Xoá bài này?'),
            content: const Text('Phiên giải toán này sẽ bị xoá vĩnh viễn.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Huỷ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Xoá',
                  style: TextStyle(color: AppColors.oxblood),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) async {
    try {
      await ref.read(aiSolveDatasourceProvider).deleteSession(sessionId);
      ref.invalidate(solveHistoryProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xoá không thành công, thử lại nhé.')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá tất cả lịch sử?'),
        content: const Text(
          'Toàn bộ phiên giải toán sẽ bị xoá vĩnh viễn. Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xoá tất cả',
              style: TextStyle(color: AppColors.oxblood),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(aiSolveDatasourceProvider).deleteAllSessions();
      ref.invalidate(solveHistoryProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xoá không thành công, thử lại nhé.')),
        );
      }
    }
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onTap});
  final AiChatSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (session.title?.trim().isNotEmpty ?? false)
        ? session.title!.trim()
        : 'Bài toán không tiêu đề';
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.oxblood.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.functions_rounded,
          size: 20,
          color: AppColors.oxblood,
        ),
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      subtitle: session.updatedAt == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _relativeTime(session.updatedAt!),
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink4),
              ),
            ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.ink4,
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.ink4),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}
