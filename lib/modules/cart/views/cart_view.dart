import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_header_widget.dart';
import '../../../data/models/cart_item_model.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartService>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A192F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navyDark, // Dark status bar
        body: SafeArea(
          bottom: false,
          child: Container(
            color: AppColors.background,
            child: Column(
              children: [
                // 1. Top Unified AppHeader with Back Button
                const AppHeaderWidget(
                  title: 'السلة',
                  showBack: true,
                  showCart: false,
                ),

                // 2. Cart Content
                Expanded(
                  child: Obx(() {
                    if (cart.cartItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.cardWhite,
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                              ),
                              child: const Icon(IconsaxPlusBold.bag_2, color: AppColors.gold, size: 54),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'سلتك فارغة',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'أضف قطعاً لبدء التسوق',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        // List of items
                        ...cart.cartItems.map((item) => _CartItemCard(item: item, cart: cart)),

                        const SizedBox(height: 16),

                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'المجموع الفرعي',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatIQD(cart.subtotalIqd),
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'التوصيل',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      if (cart.hasSplitShipment) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFCD34D)),
                                          ),
                                          child: Text(
                                            '${cart.shipmentCount} شحنات',
                                            style: const TextStyle(
                                              color: Color(0xFFB45309),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    cart.deliveryFeeIqd > 0 ? Formatters.formatIQD(cart.deliveryFeeIqd) : 'مجاني',
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              if (cart.hasSplitShipment) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'يتضمن طلبك ${cart.shipmentCount} شحنات منفصلة لحماية القطع الحساسة أو الكبيرة أثناء النقل، ويتم احتساب أجور توصيل مستقلة لكل شحنة.',
                                          style: const TextStyle(
                                            color: Color(0xFF92400E),
                                            fontSize: 11,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Color(0xFFF1F5F9), height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'الإجمالي',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatIQD(cart.totalIqd),
                                    style: const TextStyle(
                                      color: AppColors.navyDark,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Checkout Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Get.toNamed(AppRoutes.checkout),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: const Color(0xFF0F172A),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'متابعة الدفع',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  final CartItemModel item;
  final CartService cart;

  const _CartItemCard({required this.item, required this.cart});

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  bool _isNoteExpanded = false;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _isNoteExpanded = widget.item.note != null && widget.item.note!.isNotEmpty;
    _noteCtrl = TextEditingController(text: widget.item.note ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.item.product;
    final side = widget.item.side;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content on the Right (Arabic RTL)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Title
                Text(
                  product?.nameAr ?? 'قطعة غيار',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),

                if (product?.oemNumber != null && product!.oemNumber!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'OEM: ${product.oemNumber}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Side Selector Chips (LH / RH / PAIR / اختياري) - only if product supports sides
                if (product?.hasSideOptions ?? true) ...[
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSideChip('LH · يسار', 'LH', side),
                        _buildSideChip('RH · يمين', 'RH', side),
                        _buildSideChip('تخم', 'PAIR', side),
                        if (side == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: Text(
                              'اختياري',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Price (reflects 2x for PAIR automatically)
                Text(
                  Formatters.formatIQD(widget.item.totalPrice),
                  style: const TextStyle(
                    color: AppColors.navyDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                // Actions & Quantity Stepper
                Row(
                  children: [
                    // Stepper: [- qty +]
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => widget.cart.updateQuantity(widget.item.id, widget.item.quantity + 1),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.add_rounded, size: 16, color: AppColors.navyDark),
                            ),
                          ),
                          Text(
                            widget.item.quantity.toString(),
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => widget.cart.updateQuantity(widget.item.id, widget.item.quantity - 1),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.remove_rounded, size: 16, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Trash button on the left
                    GestureDetector(
                      onTap: () => widget.cart.removeItem(widget.item.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          IconsaxPlusBold.trash,
                          color: AppColors.remainingBadge,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),

                // Note section
                const SizedBox(height: 6),
                if (!_isNoteExpanded)
                  GestureDetector(
                    onTap: () => setState(() => _isNoteExpanded = true),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconsaxPlusBold.note, color: AppColors.gold, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'إضافة ملاحظة',
                          style: TextStyle(
                            color: AppColors.goldDark,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(IconsaxPlusBold.note, color: AppColors.gold, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'ملاحظة لهذا المنتج:',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _noteCtrl,
                          onChanged: (val) => widget.cart.updateNote(widget.item.id, val),
                          style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                          decoration: InputDecoration(
                            hintText: 'لون، مقاس، تفاصيل إضافية...',
                            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.gold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Product Image Thumbnail
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF1F5F9),
            ),
            clipBehavior: Clip.antiAlias,
            child: product?.mainImage != null && product!.mainImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: Formatters.thumbUrl(product.mainImage, width: 200),
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Icon(
                      Icons.settings_outlined,
                      color: Color(0xFFCBD5E1),
                      size: 32,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideChip(String label, String sideCode, String? currentSide) {
    final isSelected = currentSide == sideCode;

    return GestureDetector(
      onTap: () {
        widget.cart.updateSide(widget.item.id, isSelected ? null : sideCode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDark : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
