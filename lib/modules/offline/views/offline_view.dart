import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../widgets/offline_content_widget.dart';

class OfflineView extends StatelessWidget {
  const OfflineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfflineContentWidget(
        onRetry: () => Get.offAllNamed(AppRoutes.mainNav),
      ),
    );
  }
}
