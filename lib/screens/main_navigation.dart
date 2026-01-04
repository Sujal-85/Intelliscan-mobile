import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme/design_system.dart';
import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';
import 'features/advanced_features_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static _MainNavigationState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainNavigationState>();

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void setIndex(int index) {
    // Ensure index is within valid range
    if (index >= 0 && index < _screens.length) {
      setState(() => _selectedIndex = index);
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const AdvancedFeaturesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: DesignSystem.surfaceColor(context),
          boxShadow: DesignSystem.softShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.history_rounded, 'History'),
                _buildNavItem(2, Icons.auto_awesome_rounded, 'Advanced'),
                _buildNavItem(3, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? DesignSystem.primaryGradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? DesignSystem.gradientShadow : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              FadeIn(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
