import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/capsule_white_button.dart';
import '../../main/main_shell.dart';

/// Экран ввода логина и пароля (макет SugarBalance).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Оформление полей: тёмно-синяя обводка, скругление как в Figma.
  InputDecoration _fieldDecoration(String hint) {
    const radius = 10.0;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.formNavy, width: 1.2),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.inputHint,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
    );
  }

  /// Проверка полей и вход через [AuthProvider] + SQLite.
  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.signIn(
      _loginController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      goToMainDashboard(context);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.formNavy,
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SugarBalance',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                  height: 1.1,
                  color: AppColors.formNavy,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Логин',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.formNavy,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _loginController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.formNavy,
                  fontSize: 16,
                ),
                decoration: _fieldDecoration('example@example.com'),
              ),
              const SizedBox(height: 22),
              Text(
                'Пароль',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.formNavy,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _onLogin(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.formNavy,
                  fontSize: 16,
                ),
                decoration: _fieldDecoration('Введите пароль'),
              ),
              const Spacer(),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return CapsuleWhiteButton(
                    label: auth.isBusy ? 'Вход…' : 'Войти',
                    onPressed: auth.isBusy ? null : () => unawaited(_onLogin()),
                  );
                },
              ),
              SizedBox(height: 12 + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }
}
