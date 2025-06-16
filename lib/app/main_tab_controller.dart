import 'package:flutter/material.dart';
import '../features/timer_list/timer_list_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/settings/settings_screen.dart';

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TimerListScreen(),
    const StatsScreen(),
    const CalendarScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.6),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          items: [
            BottomNavigationBarItem(
              icon: _buildTabIcon(Icons.timer_outlined, Icons.timer, 0),
              label: '타이머',
            ),
            BottomNavigationBarItem(
              icon: _buildTabIcon(Icons.bar_chart_outlined, Icons.bar_chart, 1),
              label: '통계',
            ),
            BottomNavigationBarItem(
              icon: _buildTabIcon(
                Icons.calendar_month_outlined,
                Icons.calendar_month,
                2,
              ),
              label: '캘린더',
            ),
            BottomNavigationBarItem(
              icon: _buildTabIcon(Icons.settings_outlined, Icons.settings, 3),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabIcon(
    IconData unselectedIcon,
    IconData selectedIcon,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(isSelected ? selectedIcon : unselectedIcon, size: 24),
    );
  }
}
