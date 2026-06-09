import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';

class ParentChildAvatarStrip extends StatefulWidget {
  const ParentChildAvatarStrip({
    required this.students,
    required this.isLoading,
    required this.selectedId,
    required this.onSelect,
    required this.onAddChild,
    required this.onNotif,
    this.selectedSubject,
    this.selectedTutor,
    this.onDark = false,
    super.key,
  });

  final List<ParentStudentDto> students;
  final bool isLoading;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddChild;
  final VoidCallback onNotif;
  final String? selectedSubject;
  final String? selectedTutor;
  final bool onDark;

  @override
  State<ParentChildAvatarStrip> createState() => _ParentChildAvatarStripState();
}

class _ParentChildAvatarStripState extends State<ParentChildAvatarStrip> {
  static const _chipWidth = 80.0;
  static const _horizontalPadding = 20.0;

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerOn(int index) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final target =
        _horizontalPadding + index * _chipWidth + _chipWidth / 2 - viewport / 2;
    unawaited(
      _scrollController.animateTo(
        target.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _onSelect(int index, String studentId) {
    widget.onSelect(studentId);
    _centerOn(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final selectedStudent = widget.students
        .where((s) => s.studentId == widget.selectedId)
        .firstOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row: chips (scrollable, fills width) + notification icon pinned right
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalPadding,
                    10,
                    0,
                    0,
                  ),
                  children: [
                    for (var i = 0; i < widget.students.length; i++)
                      _ChildAvatarChip(
                        student: widget.students[i],
                        selected:
                            widget.students[i].studentId == widget.selectedId,
                        onTap: () => _onSelect(i, widget.students[i].studentId),
                      ),
                    _AddChildChip(onTap: widget.onAddChild),
                  ],
                ),
              ),
              // Notification bell — top-aligned, same height as chip area
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 20, 0),
                child: GestureDetector(
                  onTap: widget.onNotif,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFD166),
                              border: Border.all(
                                color: const Color(0xFF2F5FBF),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Selected child info
        if (selectedStudent != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStudent.fullName.toUpperCase(),
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (widget.selectedSubject != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        [
                          widget.selectedSubject,
                          if (widget.selectedTutor != null)
                            widget.selectedTutor,
                        ].join(' · '),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                else
                  Text(
                    'Chưa có lớp học',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _cartoonAvatarUrl(String studentId) =>
    'https://api.dicebear.com/9.x/adventurer/png?seed=$studentId';

const _avatarBg = Color(0xFFD8E8F5);

class _ChildAvatarChip extends StatelessWidget {
  const _ChildAvatarChip({
    required this.student,
    required this.selected,
    required this.onTap,
  });

  final ParentStudentDto student;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = student.fullName
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();
    final shortName =
        student.fullName.trim().split(' ').lastOrNull ?? student.fullName;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        scale: selected ? 1.06 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 68,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: _avatarBg,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 52,
                  height: 52,
                  color: _avatarBg,
                  alignment: Alignment.center,
                  child: Image.network(
                    (student.avatarUrl != null && student.avatarUrl!.isNotEmpty)
                        ? student.avatarUrl!
                        : _cartoonAvatarUrl(student.studentId),
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Initials(initials),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                shortName.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? const Color(0xFF2B5BBF) : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink2,
      ),
    );
  }
}

class _AddChildChip extends StatelessWidget {
  const _AddChildChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.6,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Thêm c...',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
