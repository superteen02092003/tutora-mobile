import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/app_colors.dart';

class TutorShell extends StatelessWidget {
  const TutorShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    _TabItem(
      label: 'Lịch dạy',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
    ),
    _TabItem(
      label: 'Đóng góp',
      icon: Icons.add_box_outlined,
      activeIcon: Icons.add_box,
    ),
    _TabItem(
      label: 'Hồ sơ',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _TutorBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        tabs: _tabs,
      ),
    );
  }
}

class _TutorBottomNav extends StatelessWidget {
  const _TutorBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? tab.activeIcon : tab.icon,
                        size: 22,
                        color: selected ? AppColors.ink : AppColors.ink4,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected ? AppColors.ink : AppColors.ink4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
