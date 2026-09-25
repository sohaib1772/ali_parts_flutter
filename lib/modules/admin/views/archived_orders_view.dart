import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../app/config/api_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_header_widget.dart';

class ArchivedOrdersView extends StatefulWidget {
  const ArchivedOrdersView({super.key});

  @override
  State<ArchivedOrdersView> createState() => _ArchivedOrdersViewState();
}

class _ArchivedOrdersViewState extends State<ArchivedOrdersView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _archivedOrders = [];
  final Map<String, Map<String, dynamic>> _customerProfiles = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadArchivedOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadArchivedOrders() async {
    setState(() => _isLoading = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.get(
        ApiConstants.orders,
        queryParameters: {
          'select': '*,order_items(*)',
          'is_archived': 'eq.true',
          'order': 'created_at.desc',
          'limit': 150,
        },
      );

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        final list = List<Map<String, dynamic>>.from(res.data as List);
        final userIds = <String>{};

        for (final o in list) {
          final uid = o['user_id'] as String?;
          if (uid != null && uid.isNotEmpty) userIds.add(uid);
        }

        if (userIds.isNotEmpty) {
          try {
            final profRes = await dio.get(
              ApiConstants.profiles,
              queryParameters: {
                'select': 'id,full_name,phone,avatar_url',
                'id': 'in.(${userIds.join(",")})',
              },
            );
            if (profRes.statusCode == 200 && profRes.data is List) {
              for (final p in profRes.data as List) {
                final map = Map<String, dynamic>.from(p as Map);
                final id = map['id'] as String?;
                if (id != null) _customerProfiles[id] = map;
              }
            }
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _archivedOrders = list;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _unarchiveOrder(String orderId) async {
    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.post(
        ApiConstants.apiAdminUnarchiveOrder,
        data: {'order_id': orderId},
      );

      if (res.statusCode == 200) {
        Get.snackbar(
          'تمت الاستعادة',
          'تمت استعادة الطلب إلى القائمة النشطة بنجاح ✓',
          backgroundColor: AppColors.inStock,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        _loadArchivedOrders();
      } else {
        Get.snackbar('خطأ', 'تعذرت استعادة الطلب', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      }
    } catch (_) {
      Get.snackbar('خطأ', 'تعذرت استعادة الطلب', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    }
  }

  Future<void> _deletePermanently(String orderId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف نهائي', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: const Text('هل أنت متأكد من حذف هذا الطلب نهائياً من قاعدة البيانات؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dio = Get.find<DioClient>().dio;
      await dio.delete(ApiConstants.orders, queryParameters: {'id': 'eq.$orderId'});
      Get.snackbar('تم', 'تم حذف الطلب بشكل نهائي', backgroundColor: AppColors.inStock, colorText: Colors.white);
      _loadArchivedOrders();
    } catch (_) {
      Get.snackbar('خطأ', 'تعذر حذف الطلب', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final y = dt.year;
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour >= 12 ? 'م' : 'ص';
      return '$y/$m/$d - $h:$min $p';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _archivedOrders.where((o) {
      if (_searchQuery.isEmpty) return true;
      final num = (o['order_number'] ?? o['id'] ?? '').toString().toLowerCase();
      final addr = (o['address'] as Map<String, dynamic>?) ?? {};
      final name = (addr['full_name'] ?? '').toString().toLowerCase();
      final phone = (addr['phone'] ?? '').toString().toLowerCase();
      final city = (addr['city'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return num.contains(q) || name.contains(q) || phone.contains(q) || city.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeaderWidget(
              title: 'الطلبات المأرشفة',
              showBack: true,
              showNotifications: false,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'ابحث برقم الطلب، الاسم، أو الهاتف...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(IconsaxPlusLinear.search_normal_1, color: Color(0xFF94A3B8), size: 18),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(IconsaxPlusBold.close_circle, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.navyDark, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} طلب مأرشف',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  InkWell(
                    onTap: _loadArchivedOrders,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 16, color: AppColors.gold),
                        SizedBox(width: 4),
                        Text('تحديث', style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(IconsaxPlusLinear.archive_1, size: 32, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty ? 'لا توجد طلبات مأرشفة' : 'لا توجد نتائج مطابقة للبحث',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.gold,
                          onRefresh: _loadArchivedOrders,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final o = filtered[index];
                              final id = o['id'] as String;
                              final orderNumber = o['order_number'] ?? id.substring(0, 8);
                              final total = Formatters.formatIQD(o['total_iqd'] ?? 0);
                              final createdAt = _formatDateTime(o['created_at'] as String?);
                              final archivedAt = _formatDateTime(o['archived_at'] as String?);
                              final addr = (o['address'] as Map<String, dynamic>?) ?? {};
                              final customerName = addr['full_name'] ?? 'زبون';
                              final customerPhone = addr['phone'] ?? '';
                              final items = (o['order_items'] as List?) ?? [];

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(IconsaxPlusBold.archive, size: 16, color: Color(0xFFD97706)),
                                            const SizedBox(width: 6),
                                            Text(
                                              '#$orderNumber',
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFBEB),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: const Text(
                                            'مأرشف',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFB45309),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'الزبون: $customerName ${customerPhone.isNotEmpty ? '($customerPhone)' : ''}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                    ),
                                    if (addr['city'] != null)
                                      Text(
                                        'العنوان: ${addr['city']} - ${addr['area'] ?? ''} ${addr['street'] ?? ''}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    const SizedBox(height: 8),
                                    if (items.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFF1F5F9)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'القطع المطلوبة (${items.length}):',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(height: 4),
                                            ...items.take(3).map((it) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '• ${it['name_ar'] ?? 'قطعة'}',
                                                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Text(
                                                      '×${it['quantity']}',
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                            if (items.length > 3)
                                              Text(
                                                '+ ${items.length - 3} قطع أخرى...',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('المبلغ الإجمالي:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                        Text(
                                          total,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.navyDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('تاريخ الطلب: $createdAt', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                        if (archivedAt != '—')
                                          Text('تاريخ الأرشفة: $archivedAt', style: const TextStyle(fontSize: 11, color: Color(0xFFD97706))),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _unarchiveOrder(id),
                                            icon: const Icon(Icons.restore_page_rounded, size: 16),
                                            label: const Text(
                                              'استعادة الطلب للنشط',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.navyDark,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () => _deletePermanently(id),
                                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                          style: IconButton.styleFrom(
                                            backgroundColor: const Color(0xFFFFF1F2),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
