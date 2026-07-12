import 'package:flutter/material.dart';
import 'package:tutora/features/auth/presentation/pages/register_page.dart';
import 'package:tutora/features/auth/presentation/widgets/role_tab.dart';

/// Account registration for the Student role.
class RegisterStudentPage extends StatelessWidget {
  const RegisterStudentPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const RegisterPage(role: AuthRole.student);
}
