import 'package:flutter/material.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_availability_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/settings_section.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_profile_header.dart';
import 'package:tutora/features/tutor/presentation/widgets/wallet_card.dart';
import 'package:tutora/mock/tutor_profile_mock.dart';

class TutorProfileScreen extends StatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  bool _notifOn = true;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: Column(
        children: [
          TutorProfileHeader(notifOn: _notifOn),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(14, 14, 14, bottomPad + 100),
              children: [
                WalletCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TutorWalletScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const SectionLabel('Hồ sơ gia sư'),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Chỉnh thông tin cá nhân',
                      sub: kTutorProfile.email,
                      onTap: () {},
                    ),
                    SettingRow(
                      icon: Icons.menu_book_outlined,
                      label: 'Môn dạy & hồ sơ công khai',
                      sub: kTutorProfile.subjects.join(', '),
                      onTap: () {},
                    ),
                    SettingRow(
                      icon: Icons.shield_outlined,
                      label: 'Bảo mật & Mật khẩu',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const SectionLabel('Lịch dạy'),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Ngày rảnh',
                      sub: 'Cài đặt khung giờ & ngày có thể dạy',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorAvailabilityScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const SectionLabel('Tài chính'),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Tài khoản ngân hàng',
                      sub:
                          '${kTutorProfile.bank.bankName} · ${kTutorProfile.bank.accountNumber}',
                      onTap: () {},
                    ),
                    SettingRow(
                      icon: Icons.south_rounded,
                      label: 'Lịch sử rút tiền',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TutorWalletScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.notifications_outlined,
                      label: 'Thông báo',
                      trailing: Switch(
                        value: _notifOn,
                        onChanged: (v) => setState(() => _notifOn = v),
                        activeThumbColor: AppColors.ink,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  children: [
                    SettingRow(
                      icon: Icons.logout_rounded,
                      label: 'Đăng xuất',
                      danger: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
