import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/capsule_white_button.dart';

/// Экран приветствия: макет с орбами и кнопками «Войти» / «Зарегистрироваться».
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    // Крупные пятна: от меньшей стороны экрана (увеличены для заметного фона).
    final orbDiameter = size.shortestSide * 1.72;
    final orbDiameterMint = orbDiameter * 1.12;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Голубое пятно — слева сверху (центр круга уводим в угол, «облако» в экране).
          Positioned(
            top: -orbDiameter * 0.38,
            left: -orbDiameter * 0.38,
            child: _SoftBackgroundOrb(
              diameter: orbDiameter,
              coreColor: const Color.fromARGB(255, 144, 202, 249),
            ),
          ),
          // Зелёное пятно — снизу справа.
          Positioned(
            bottom: -orbDiameterMint * 0.38,
            right: -orbDiameterMint * 0.38,
            child: _SoftBackgroundOrb(
              diameter: orbDiameterMint,
              coreColor: const Color.fromARGB(255, 129, 199, 132),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  Text(
                    'SugarBalance',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 42,
                      height: 1.12,
                      letterSpacing: -0.5,
                      color: AppColors.formNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'твой помощник\nдля самоконтроля при диабете',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 24,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      color: AppColors.formNavy,
                    ),
                  ),
                  const Spacer(flex: 6),
                  CapsuleWhiteButton(
                    label: 'Войти',
                    onPressed: () => context.push(AppRouter.login),
                  ),
                  const SizedBox(height: 14),
                  CapsuleWhiteButton(
                    label: 'Зарегистрироваться',
                    onPressed: () => context.push(AppRouter.register),
                  ),
                  SizedBox(height: 8 + MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Мягкое круговое «пятно» на фоне без резких границ.
class _SoftBackgroundOrb extends StatelessWidget {
  const _SoftBackgroundOrb({required this.diameter, required this.coreColor});

  final double diameter;
  final Color coreColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                coreColor.withValues(alpha: 0.82),
                coreColor.withValues(alpha: 0.48),
                coreColor.withValues(alpha: 0.12),
                coreColor.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.32, 0.62, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
