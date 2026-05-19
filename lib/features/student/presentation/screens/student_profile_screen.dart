import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/student/presentation/providers/profile_provider.dart';
import 'package:tutora/features/student/presentation/screens/change_password_screen.dart';
import 'package:tutora/features/student/presentation/screens/edit_info_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_profile/profile_hero_header.dart';
// import 'package:tutora/features/student/presentation/screens/student_profile/profile_primitives.dart';
import 'package:tutora/features/student/presentation/screens/student_profile/profile_settings_section.dart';
// TODO: student wallet — ẩn tạm, chưa phát triển
// import 'package:tutora/features/student/presentation/screens/student_profile/profile_recent_history.dart';
// import 'package:tutora/features/student/presentation/screens/student_profile/profile_wallet_card.dart';
// import 'package:tutora/features/student/presentation/screens/student_profile/profile_wallet_detail_screen.dart';
import 'package:tutora/features/student/presentation/shell/student_shell.dart';

class StudentProfilePage extends ConsumerStatefulWidget {
  const StudentProfilePage({super.key});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage>
    with ScrollToTopMixin {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenScrollToTop(context, 4, _scrollController);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.profile == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: TextButton.icon(
            onPressed: () => ref.read(profileProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ),
      );
    }

    final profile = state.profile!;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.only(bottom: bottomPad + AppSpacing.xxl),
          children: [
            ProfileHeroHeader(profile: profile),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TODO: student wallet — ẩn tạm, chưa phát triển
                  // ProfileWalletCard(
                  //   onDetailTap: () => Navigator.of(context).push(
                  //     MaterialPageRoute<void>(
                  //       builder: (_) => const ProfileWalletDetailScreen(),
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 14),
                  // const ProfileSectionLabel('Lịch sử học gần đây'),
                  // ProfileRecentHistory(onViewAll: () {}),
                  // const SizedBox(height: 14),
                  ProfileSettingsSection(
                    onEditInfo: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EditInfoScreen(),
                      ),
                    ),
                    onChangePassword: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                    onLogout: () =>
                        ref.read(authControllerProvider.notifier).logout(),
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
