import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class ParentAddChildScreen extends ConsumerStatefulWidget {
  const ParentAddChildScreen({super.key});

  @override
  ConsumerState<ParentAddChildScreen> createState() =>
      _ParentAddChildScreenState();
}

class _ParentAddChildScreenState extends ConsumerState<ParentAddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();

  DateTime? _birthdate;
  GradeLevelDto? _selectedGrade;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 10),
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year - 4),
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  Future<void> _pickGrade(List<GradeLevelDto> grades) async {
    final picked = await showModalBottomSheet<GradeLevelDto>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final g in grades)
              ListTile(
                title: Text(
                  g.gradeName,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                trailing: g.gradeLevelId == _selectedGrade?.gradeLevelId
                    ? const Icon(Icons.check_rounded, color: AppColors.oxblood)
                    : null,
                onTap: () => Navigator.pop(ctx, g),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _selectedGrade = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_birthdate == null) {
      AppToast.show(
        context,
        message: 'Vui lòng chọn ngày sinh',
        type: AppToastType.error,
      );
      return;
    }
    if (_selectedGrade == null) {
      AppToast.show(
        context,
        message: 'Vui lòng chọn lớp',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ref
          .read(parentStudentsProvider.notifier)
          .addStudent(
            fullname: _nameCtrl.text.trim(),
            birthdate:
                '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
            school: _schoolCtrl.text.trim(),
            gradeLevelId: _selectedGrade!.gradeLevelId,
            learninggoals: _goalCtrl.text.trim().isNotEmpty
                ? _goalCtrl.text.trim()
                : null,
          );
      if (!mounted) return;
      AppToast.show(
        context,
        message:
            'Đã thêm ${result.fullName}!\nTài khoản: ${result.username}\nMật khẩu: ${result.temporaryPassword}',
        type: AppToastType.success,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show(
        context,
        message: 'Có lỗi xảy ra, thử lại sau',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(gradeLevelsProvider);
    final birthdateText = _birthdate == null
        ? 'Chọn ngày sinh'
        : '${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.ink,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Thêm con'),
        centerTitle: true,
      ),
      body: gradesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.ink),
        ),
        error: (_, _) => Center(
          child: Text(
            'Không tải được dữ liệu',
            style: GoogleFonts.inter(color: AppColors.ink3),
          ),
        ),
        data: (grades) {
          // chọn mặc định lớp 9 nếu chưa chọn
          if (_selectedGrade == null && grades.isNotEmpty) {
            final def =
                grades.where((g) => g.levelOrder == 9).firstOrNull ??
                grades.first;
            unawaited(
              Future.microtask(() => setState(() => _selectedGrade = def)),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                const SizedBox(height: 8),
                const _Label('Họ và tên con'),
                const SizedBox(height: 6),
                _Field(
                  controller: _nameCtrl,
                  hint: 'Nguyễn Văn A',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập tên'
                      : null,
                ),
                const SizedBox(height: 16),
                const _Label('Ngày sinh'),
                const SizedBox(height: 6),
                _TapField(
                  text: birthdateText,
                  placeholder: _birthdate == null,
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                const _Label('Trường học'),
                const SizedBox(height: 6),
                _Field(
                  controller: _schoolCtrl,
                  hint: 'THCS Nguyễn Du',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập trường'
                      : null,
                ),
                const SizedBox(height: 16),
                const _Label('Lớp'),
                const SizedBox(height: 6),
                _TapField(
                  text: _selectedGrade?.gradeName ?? 'Chọn lớp',
                  placeholder: _selectedGrade == null,
                  icon: Icons.expand_more_rounded,
                  onTap: () => _pickGrade(grades),
                ),
                const SizedBox(height: 16),
                const _Label('Mục tiêu học tập (tuỳ chọn)'),
                const SizedBox(height: 6),
                _Field(
                  controller: _goalCtrl,
                  hint: 'Đậu vào lớp 10...',
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Thêm con',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink2,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, this.hint, this.validator});

  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.ink4),
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.text,
    required this.placeholder,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final bool placeholder;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: placeholder ? AppColors.ink4 : AppColors.ink,
                ),
              ),
            ),
            Icon(icon, size: 18, color: AppColors.ink4),
          ],
        ),
      ),
    );
  }
}
