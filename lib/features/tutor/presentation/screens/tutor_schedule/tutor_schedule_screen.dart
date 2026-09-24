import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_calendar_agenda.dart';

/// Tab Lịch (prototype: "8 · Lịch · Tháng ghim + Agenda").
///
/// Tiêu đề + nút "Hôm nay"; bên dưới là lịch tháng ghim và agenda cuộn.
/// Chạm một buổi trong agenda để mở chi tiết buổi học.
class TutorScheduleScreen extends StatefulWidget {
  const TutorScheduleScreen({super.key});

  @override
  State<TutorScheduleScreen> createState() => _TutorScheduleScreenState();
}

class _TutorScheduleScreenState extends State<TutorScheduleScreen> {
  final _agenda = TutorCalendarAgendaController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Lịch dạy', style: TutorType.screenTitle()),
                  ),
                  SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: _agenda.goToday,
                      style: OutlinedButton.styleFrom(
                        // Theme app đặt minimumSize rộng vô hạn cho OutlinedButton.
                        minimumSize: const Size(0, 36),
                        backgroundColor: TutorColors.surface,
                        side: const BorderSide(color: TutorColors.line),
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        shape: const StadiumBorder(),
                      ),
                      child: Text('Hôm nay', style: TutorType.action()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: TutorCalendarAgenda(controller: _agenda)),
          ],
        ),
      ),
    );
  }
}
