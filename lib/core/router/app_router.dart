import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login/login_screen.dart';
import '../../screens/auth/register/register_screen.dart';
import '../../screens/auth/welcome/welcome_screen.dart';
import '../../screens/main/dashboard/dashboard_screen.dart';
import '../../screens/main/diary/diary_screen.dart';
import '../../screens/main/main_shell.dart';
import '../../screens/main/profile/profile_screen.dart';
import '../../screens/main/statistics/statistics_screen.dart';
import '../../screens/splash/splash_screen.dart';

/// Имена маршрутов и построение [GoRouter] для SugarBalance.
abstract final class AppRouter {
  AppRouter._();

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String diary = '/diary';
  static const String statistics = '/statistics';
  static const String profile = '/profile';

  static final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

  /// Корневой навигатор (оверлеи, диалоги с корня).
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootKey;

  static const _publicPaths = <String>{splash, welcome, login, register};

  /// Роутер с учётом сохранённой сессии пользователя.
  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: splash,
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final path = state.matchedLocation;

        if (path == splash) return null;

        if (!loggedIn && !_publicPaths.contains(path)) {
          return welcome;
        }

        if (loggedIn &&
            (path == welcome || path == login || path == register)) {
          return dashboard;
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: welcome,
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: dashboard,
                  name: 'dashboard',
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: diary,
                  name: 'diary',
                  builder: (context, state) => const DiaryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: statistics,
                  name: 'statistics',
                  builder: (context, state) => const StatisticsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: profile,
                  name: 'profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
