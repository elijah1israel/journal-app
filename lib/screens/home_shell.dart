import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'strategies_screen.dart';
import 'trades_screen.dart';

/// The shell that hosts every top-level screen behind a bottom-nav bar.
/// Mirrors Pable's [HomeShell] pattern: an [IndexedStack] preserves each
/// tab's state across switches, and the chrome stays consistent.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _NavItem {
  _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<_NavItem> _items = [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      builder: (_) => const DashboardScreen(),
    ),
    _NavItem(
      label: 'Trades',
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      builder: (_) => const TradesScreen(),
    ),
    _NavItem(
      label: 'Strategies',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      builder: (_) => const StrategiesScreen(),
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      builder: (_) => const ProfileScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (final it in _items) Builder(builder: it.builder)],
      ),
      bottomNavigationBar: _ScrollableBottomNav(
        items: _items,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Horizontally scrollable nav — mirrors Pable mobile's `_ScrollableBottomNav`.
/// Even with four tabs we stay scrollable so adding screens later (Calendar,
/// Signals, Performance) doesn't squeeze the labels.
class _ScrollableBottomNav extends StatelessWidget {
  const _ScrollableBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++)
                  _NavTile(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? AppColors.gray900 : AppColors.gray500;
    final iconColor = selected ? AppColors.tealDarker : AppColors.gray400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minWidth: 84),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.teal50 : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
