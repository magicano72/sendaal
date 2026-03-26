import 'package:Sendaal/core/theme/text_style.dart';
import 'package:Sendaal/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'accounts/accounts_screen.dart';
import 'profile/profile_screen.dart';

/// Main app shell with bottom navigation bar.
/// Manages the primary tabs.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _screens = const [HomeScreen(), AccountsScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFE7F0FF),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final isSelected = states.contains(MaterialState.selected);
            return TextStyles.labelBold.copyWith(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            );
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            final isSelected = states.contains(MaterialState.selected);
            return IconThemeData(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 24,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppTheme.surface,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 8,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Accounts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
