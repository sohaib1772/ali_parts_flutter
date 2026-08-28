import 'package:flutter/material.dart';
import '../../../core/widgets/app_header_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppHeaderWidget(
      title: 'مكتب علي شوفرليت',
      showBack: false,
    );
  }
}
