import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/common_filter_bar_widget.dart';
import '../controllers/home_controller.dart';

class HomeFilterBarWidget extends GetView<HomeController> {
  const HomeFilterBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Obx(() {
        final availableModels = controller.selectedBrandId.value != null
            ? controller.carModels.where((m) => m.brandId == controller.selectedBrandId.value).toList()
            : controller.carModels;

        return CommonFilterBarWidget(
          categories: controller.categories,
          brands: controller.brands,
          carModels: availableModels.isNotEmpty ? availableModels : controller.carModels,
          selectedCategoryId: controller.selectedCategoryId.value,
          selectedBrandId: controller.selectedBrandId.value,
          selectedCarModelId: controller.selectedCarModelId.value,
          onCategoryChanged: controller.selectCategory,
          onBrandChanged: controller.selectBrand,
          onCarModelChanged: controller.selectCarModel,
          onClearAll: controller.clearFilters,
        );
      }),
    );
  }
}
