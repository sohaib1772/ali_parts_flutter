import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    controller;

    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Logo Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFF0F1E36),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.28),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.directions_car_filled_rounded,
                  color: AppColors.gold,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'مكتب علي شوفرليت',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),

            const Text(
              'قطع غيار جديدة ومستعملة · العراق',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 36),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
