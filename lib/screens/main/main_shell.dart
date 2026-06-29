import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// Оболочка главного экрана: нижняя навигация и ветки [StatefulShellRoute].
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _iconSize = 30.0;
  static const _selectedIconSize = 32.0;

  /// Переключение вкладки с сохранением стека внутри ветки.
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 76,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: _iconSize),
            selectedIcon: Icon(Icons.home, size: _selectedIconSize),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, size: _iconSize),
            selectedIcon: Icon(Icons.menu_book, size: _selectedIconSize),
            label: 'Дневник',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, size: _iconSize),
            selectedIcon: Icon(Icons.bar_chart, size: _selectedIconSize),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: _iconSize),
            selectedIcon: Icon(Icons.person, size: _selectedIconSize),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

/// Хелпер: перейти на главную вкладку «Сводка».
void goToMainDashboard(BuildContext context) => context.go(AppRouter.dashboard);
