import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/auth_validators.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/capsule_white_button.dart';
import '../../main/main_shell.dart';

/// Экран регистрации по макету: секции профиля, персональных данных и доп. полей.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthController = TextEditingController();
  final _carbsController = TextEditingController();
  final _hypoController = TextEditingController();

  /// 1 — тип I, 2 — тип II.
  int _diabetesType = 1;

  /// 0 — муж., 1 — жен.
  int _gender = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthController.dispose();
    _carbsController.dispose();
    _hypoController.dispose();
    super.dispose();
  }

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

  /// Выбор даты рождения через системный picker.
  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.formNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _birthController.text = _formatRuDate(picked));
    }
  }

  /// Дата в формате дд.ММ.гггг без пакета intl.
  static String _formatRuDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  /// Валидация, сохранение в SQLite и переход в приложение.
  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final err = auth.validateRegistrationFields(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      birthText: _birthController.text,
      carbsRaw: _carbsController.text,
      hypoRaw: _hypoController.text,
    );
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }

    final birth = AuthValidators.parseRuDate(_birthController.text.trim())!;
    final carbsText = _carbsController.text.trim().replaceAll(',', '.');
    final hypoText = _hypoController.text.trim().replaceAll(',', '.');
    final carbsXe = carbsText.isEmpty ? null : double.parse(carbsText);
    final hypo = hypoText.isEmpty ? null : double.parse(hypoText);

    final ok = await auth.signUp(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      birthDate: birth,
      diabetesType: _diabetesType,
      gender: _gender,
      carbsXe: carbsXe,
      hypoglycemia: hypo,
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Регистрация',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        color: AppColors.formNavy,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(label: 'Профиль'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      style: _fieldTextStyle(theme),
                      decoration: _fieldDecoration('Имя пользователя'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: _fieldTextStyle(theme),
                      decoration: _fieldDecoration('Почта'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      style: _fieldTextStyle(theme),
                      decoration: _fieldDecoration('Пароль'),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(label: 'Персональные данные'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _birthController,
                      readOnly: true,
                      onTap: _pickBirthDate,
                      style: _fieldTextStyle(theme),
                      decoration: _fieldDecoration('Дата рождения').copyWith(
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.inputHint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LabeledToggleRow(
                      label: 'Тип диабета',
                      leftLabel: 'I',
                      rightLabel: 'II',
                      leftSelected: _diabetesType == 1,
                      onLeft: () => setState(() => _diabetesType = 1),
                      onRight: () => setState(() => _diabetesType = 2),
                    ),
                    const SizedBox(height: 14),
                    _LabeledToggleRow(
                      label: 'Пол',
                      leftLabel: 'М',
                      rightLabel: 'Ж',
                      leftSelected: _gender == 0,
                      onLeft: () => setState(() => _gender = 0),
                      onRight: () => setState(() => _gender = 1),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(label: 'Дополнительно'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _carbsController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      style: _fieldTextStyle(theme),
                      decoration: _fieldDecoration('Углеводов в ХЕ'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _hypoController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      style: _fieldTextStyle(theme),
                      decoration: _fieldDecoration('Гипогликемия'),
                    ),
                    const SizedBox(height: 32),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return CapsuleWhiteButton(
                          label: auth.isBusy ? 'Сохранение…' : 'Продолжить',
                          onPressed: auth.isBusy
                              ? null
                              : () => unawaited(_onContinue()),
                        );
                      },
                    ),
                    SizedBox(height: 16 + bottomInset),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _fieldTextStyle(ThemeData theme) {
    return theme.textTheme.bodyLarge?.copyWith(
      color: AppColors.formNavy,
      fontSize: 16,
    );
  }
}

/// Заголовок секции (мелкий жирный слева).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: AppColors.formNavy,
      ),
    );
  }
}

/// Строка с подписью и двумя переключателями (как на макете).
class _LabeledToggleRow extends StatelessWidget {
  const _LabeledToggleRow({
    required this.label,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String label;
  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.formNavy, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: AppColors.formNavy,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: _ToggleChip(
                    label: leftLabel,
                    selected: leftSelected,
                    onTap: onLeft,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleChip(
                    label: rightLabel,
                    selected: !leftSelected,
                    onTap: onRight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.18)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.formNavy, width: 1.1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                  color: AppColors.formNavy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
