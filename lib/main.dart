import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/diary_provider.dart';
import 'repositories/diary_repository.dart';
import 'repositories/user_repository.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await DatabaseService.instance.database;
  if (kDebugMode) {
    final dbPath = await DatabaseService.instance.databaseFilePath;
    debugPrint('SugarBalance SQLite: $dbPath');
  }
  final userRepository = UserRepository(database);
  final diaryRepository = DiaryRepository(database);
  final sessionService = SessionService();

  final authProvider = AuthProvider(userRepository, sessionService);
  await authProvider.restoreSession();

  final router = AppRouter.create(authProvider);

  runApp(
    MultiProvider(
      providers: [
        Provider<UserRepository>.value(value: userRepository),
        Provider<DiaryRepository>.value(value: diaryRepository),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DiaryProvider>(
          create: (context) =>
              DiaryProvider(diaryRepository, context.read<AuthProvider>()),
        ),
      ],
      child: SugarBalanceApp(routerConfig: router),
    ),
  );
}

/// Корень приложения SugarBalance: тема MD3 и GoRouter.
class SugarBalanceApp extends StatelessWidget {
  const SugarBalanceApp({super.key, required this.routerConfig});

  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SugarBalance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: routerConfig,
    );
  }
}
