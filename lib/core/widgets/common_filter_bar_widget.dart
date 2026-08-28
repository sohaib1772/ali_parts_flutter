import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/brand_model.dart';
import '../../data/models/car_model_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/product_repository.dart';

class FilterOption {
  final String id;
  final String label;
  final String? sub;

  FilterOption({required this.id, required this.label, this.sub});
}

class CommonFilterBarWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final List<BrandModel> brands;
  final List<CarModelModel> carModels;

  final String? selectedCategoryId;
  final String? selectedBrandId;
  final String? selectedCarModelId;

  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String?> onCarModelChanged;
  final VoidCallback onClearAll;

  const CommonFilterBarWidget({
    super.key,
    required this.categories,
    required this.brands,
    required this.carModels,
    required this.selectedCategoryId,
    required this.selectedBrandId,
    required this.selectedCarModelId,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    required this.onCarModelChanged,
    required this.onClearAll,
  });

  String get categoryValueText {
    if (selectedCategoryId == null) return 'الكل';
    final cat = categories.firstWhereOrNull((c) => c.id == selectedCategoryId);
    return cat != null ? cat.nameAr : 'الكل';
  }

  String get brandValueText {
    if (selectedBrandId == null) return 'الكل';
    final b = brands.firstWhereOrNull((item) => item.id == selectedBrandId);
    return b != null ? b.nameAr : 'الكل';
  }

  String get carModelValueText {
    if (selectedCarModelId == null) return 'الكل';
    final m = carModels.firstWhereOrNull((item) => item.id == selectedCarModelId);
    return m != null ? m.nameAr : 'الكل';
  }

  @override
  Widget build(BuildContext context) {
    final isCatActive = selectedCategoryId != null;
    final isBrandActive = selectedBrandId != null;
    final isModelActive = selectedCarModelId != null;
    final hasActive = isCatActive || isBrandActive || isModelActive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3-Column Equal Grid spanning the exact screen width
        Row(
          children: [
            // 1. Category Button
            Expanded(
              child: _buildFilterButton(
                prefix: 'التصنيف:',
                value: categoryValueText,
                isActive: isCatActive,
                onTap: () => _showPickerModal(
                  title: 'اختر التصنيف',
                  currentValue: selectedCategoryId,
                  options: categories.map((c) => FilterOption(id: c.id, label: c.nameAr)).toList(),
                  loadOptions: () async {
                    final repo = Get.find<ProductRepository>();
                    final list = await repo.fetchCategories();
                    return list.map((c) => FilterOption(id: c.id, label: c.nameAr)).toList();
                  },
                  onSelect: (id) => onCategoryChanged(id.isEmpty ? null : id),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // 2. Brand Button
            Expanded(
              child: _buildFilterButton(
                prefix: 'الماركة:',
                value: brandValueText,
                isActive: isBrandActive,
                onTap: () => _showPickerModal(
                  title: 'اختر الماركة',
                  currentValue: selectedBrandId,
                  options: brands.map((b) => FilterOption(id: b.id, label: b.nameAr, sub: b.nameEn)).toList(),
                  loadOptions: () async {
                    final repo = Get.find<ProductRepository>();
                    final list = await repo.fetchBrands();
                    return list.map((b) => FilterOption(id: b.id, label: b.nameAr, sub: b.nameEn)).toList();
                  },
                  onSelect: (id) => onBrandChanged(id.isEmpty ? null : id),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // 3. Car Model Button
            Expanded(
              child: _buildFilterButton(
                prefix: 'السيارة:',
                value: carModelValueText,
                isActive: isModelActive,
                onTap: () => _showPickerModal(
                  title: 'اختر نوع السيارة',
                  currentValue: selectedCarModelId,
                  options: carModels.map((m) => FilterOption(id: m.id, label: m.nameAr, sub: m.nameEn)).toList(),
                  loadOptions: () async {
                    final repo = Get.find<ProductRepository>();
                    final list = await repo.fetchCarModels(brandId: selectedBrandId);
                    return list.map((m) => FilterOption(id: m.id, label: m.nameAr, sub: m.nameEn)).toList();
                  },
                  onSelect: (id) => onCarModelChanged(id.isEmpty ? null : id),
                ),
              ),
            ),
          ],
        ),

        // Active Filter Chips & Clear All (Matching React Website Exactly)
        if (hasActive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                // Active Chips List
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // 1. Category Chip
                      if (isCatActive)
                        _buildActiveChip(
                          label: categoryValueText,
                          onRemove: () => onCategoryChanged(null),
                        ),

                      // 2. Brand Chip
                      if (isBrandActive)
                        _buildActiveChip(
                          label: brandValueText,
                          onRemove: () => onBrandChanged(null),
                        ),

                      // 3. Car Model Chip
                      if (isModelActive)
                        _buildActiveChip(
                          label: carModelValueText,
                          onRemove: () => onCarModelChanged(null),
                        ),
                    ],
                  ),
                ),

                // Underlined "مسح الكل" text on the left
                GestureDetector(
                  onTap: onClearAll,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'مسح الكل',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActiveChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7), // Light Gold Amber bg
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF92400E), // Gold/Amber text
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.close_rounded,
              color: Color(0xFF92400E),
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String prefix,
    required String value,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navyDark : const Color(0xFF132B45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.gold : const Color(0xFF234468),
            width: isActive ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prefix,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? AppColors.gold : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isActive ? AppColors.gold : const Color(0xFF94A3B8),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerModal({
    required String title,
    required String? currentValue,
    required List<FilterOption> options,
    Future<List<FilterOption>> Function()? loadOptions,
    required Function(String) onSelect,
  }) {
    Get.dialog(
      _FilterDialogWidget(
        title: title,
        currentValue: currentValue,
        options: options,
        loadOptions: loadOptions,
        onSelect: onSelect,
      ),
      barrierColor: Colors.black.withValues(alpha: 0.65),
    );
  }
}

class _FilterDialogWidget extends StatefulWidget {
  final String title;
  final String? currentValue;
  final List<FilterOption> options;
  final Future<List<FilterOption>> Function()? loadOptions;
  final Function(String) onSelect;

  const _FilterDialogWidget({
    required this.title,
    required this.currentValue,
    required this.options,
    this.loadOptions,
    required this.onSelect,
  });

  @override
  State<_FilterDialogWidget> createState() => _FilterDialogWidgetState();
}

class _FilterDialogWidgetState extends State<_FilterDialogWidget> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<FilterOption> _allOptions = [];
  List<FilterOption> _filteredList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _allOptions = List.from(widget.options);
    _filteredList = List.from(widget.options);

    // If options are empty, load them dynamically in the background!
    if (_allOptions.isEmpty && widget.loadOptions != null) {
      _isLoading = true;
      widget.loadOptions!().then((loaded) {
        if (mounted) {
          setState(() {
            _allOptions = loaded;
            _filter(_searchCtrl.text);
            _isLoading = false;
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  void _filter(String q) {
    if (q.trim().isEmpty) {
      setState(() => _filteredList = _allOptions);
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _filteredList = _allOptions.where((o) {
        return o.label.toLowerCase().contains(lower) ||
            (o.sub != null && o.sub!.toLowerCase().contains(lower));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    
    // When keyboard is visible, calculate strict available area above keyboard
    final availableHeight = screenHeight - keyboardHeight - mediaQuery.padding.top - 40;
    final maxHeight = (keyboardHeight > 0)
        ? (availableHeight * 0.82).clamp(140.0, availableHeight)
        : screenHeight * 0.70;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: keyboardHeight > 0 ? 8 : 24,
      ),
      child: Container(
        width: mediaQuery.size.width * 0.88,
        constraints: BoxConstraints(
          maxWidth: 380,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Deep Navy with Gold Bullet and Close Button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                color: AppColors.navyDark,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Right: Gold bullet + Title
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Left: Circular Close Button
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Loading State inside Dialog
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.gold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'جاري تحميل الخيارات...',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: false,
                            onChanged: _filter,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'ابحث هنا...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _filter('');
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const Divider(color: Color(0xFFF1F5F9), height: 1),

                // Options List
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      // "الكل" Option (Only if search is empty)
                      if (_searchCtrl.text.isEmpty)
                        InkWell(
                          onTap: () {
                            widget.onSelect('');
                            Get.back();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            color:
                                widget.currentValue == null ||
                                    widget.currentValue!.isEmpty
                                ? AppColors.gold.withValues(alpha: 0.1)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Text(
                                  'الكل',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color:
                                        widget.currentValue == null ||
                                            widget.currentValue!.isEmpty
                                        ? AppColors.goldDark
                                        : AppColors.textDark,
                                    fontWeight:
                                        widget.currentValue == null ||
                                            widget.currentValue!.isEmpty
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                if (widget.currentValue == null ||
                                    widget.currentValue!.isEmpty) ...[
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.gold,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ),
                        ),

                      // Filtered Options
                      ..._filteredList.map((opt) {
                        final isSelected = widget.currentValue == opt.id;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            InkWell(
                              onTap: () {
                                widget.onSelect(opt.id);
                                Get.back();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              color: isSelected
                                  ? AppColors.gold.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Gold Checkmark on left if selected
                                  if (isSelected) ...[
                                    const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.gold,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                  ],

                                  // Right-aligned Name Block spanning full width
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          opt.label,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppColors.goldDark
                                                : AppColors.textDark,
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.w600,
                                            fontSize: 13.5,
                                            height: 1.3,
                                          ),
                                        ),
                                        if (opt.sub != null &&
                                            opt.sub!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            opt.sub!,
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    if (_filteredList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'لا توجد نتائج مطابقة',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }
}
