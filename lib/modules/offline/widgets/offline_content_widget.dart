import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class OfflineContentWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineContentWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navyMedium,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.gold,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا يوجد اتصال بالإنترنت',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يرجى التحقق من اتصالك بالشبكة وإعادة المحاولة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
          ],
        ),
      ),
    );
  }
}
