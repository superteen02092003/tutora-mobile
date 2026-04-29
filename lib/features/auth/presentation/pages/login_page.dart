import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/jwt_utils.dart';
import '../../../../core/storage/secure_storage.dart';
import '../controllers/login_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(loginControllerProvider.notifier).login(
          _emailCtrl.text,
          _passCtrl.text,
        );
  }

  void _navigateByRole() async {
    final token = await ref.read(secureStorageProvider).getAccessToken();
    if (!mounted || token == null) return;
    final claims = parseJwt(token);
    if (!mounted || claims == null) return;
    switch (claims.role) {
      case UserRole.student:
        context.go(AppRoutes.studentHome);
      case UserRole.tutor:
        context.go(AppRoutes.tutorHome);
      case UserRole.unknown:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider, (_, state) {
      if (state is LoginSuccess) _navigateByRole();
      if (state is LoginError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
        ref.read(loginControllerProvider.notifier).resetError();
      }
    });

    final state = ref.watch(loginControllerProvider);
    final isLoading = state is LoginLoading;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // Wordmark
              Text(
                'TUTORA.',
                style: AppTextStyles.eyebrow(color: AppColors.oxblood).copyWith(fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),

              // Heading
              Text('Chào mừng\ntrở lại.', style: AppTextStyles.h1()),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Học cùng gia sư phù hợp nhất với bạn.',
                style: AppTextStyles.serifItalic(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Email / phone
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
                decoration: const InputDecoration(labelText: 'Email hoặc số điện thoại'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Password
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.ink4,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : () {},
                  child: Text('Quên mật khẩu?', style: AppTextStyles.label(color: AppColors.oxblood)),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Submit
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cream,
                        ),
                      )
                    : const Text('Đăng nhập'),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
