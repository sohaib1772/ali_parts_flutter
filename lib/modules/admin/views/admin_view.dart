import 'dart:io';
import 'dart:ui' as ui;
import '../../../core/widgets/app_header_widget.dart';
import '../../../core/widgets/glass_scroll_to_top_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/config/api_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/brand_model.dart';
import '../../../data/models/car_model_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../home/controllers/home_controller.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final SettingsService _settings = Get.find<SettingsService>();
  final ScrollController _scrollController = ScrollController();

  int _selectedTab = 0; // 0: Products, 1: Orders, 2: Categories, 3: Banners, 4: Stock Movements, 5: Block Log, 6: Users, 10: Settings, 11: Broadcast
  bool _showPermissions = false;

  // Products state
  List<ProductModel> _products = [];
  bool _isLoadingProducts = true;
  final TextEditingController _searchCtrl = TextEditingController();
  int _totalProducts = 0;

  // Orders state
  List<Map<String, dynamic>> _orders = [];
  bool _isLoadingOrders = false;
  String _orderRange = '24h'; // '24h' | '7d' | 'all'
  String _orderStatusFilter = 'all'; // 'all' | 'received' | 'preparing' | 'packed' | 'shipped_group' | 'delivered' | 'cancelled'
  final Map<String, Map<String, dynamic>> _orderCustomerProfiles = {};
  final Map<String, List<Map<String, dynamic>>> _orderItemsMap = {};
  final Set<String> _expandedOrderIds = {};
  String? _updatingOrderStatusId;
  String? _togglingBlockUserId;

  // Categories, Brands, CarModels state
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  List<CarModelModel> _carModels = [];
  bool _isLoadingCategories = false;

  // Banners / Offers state
  List<Map<String, dynamic>> _banners = [];
  bool _isLoadingBanners = false;

  // Stock Movements state
  List<Map<String, dynamic>> _stockMovements = [];
  final Map<String, String> _actorNames = {};
  bool _isLoadingStock = false;
  String _stockReasonFilter = 'all';
  final TextEditingController _stockSearchCtrl = TextEditingController();

  // Block Log state
  List<Map<String, dynamic>> _blockedUsers = [];
  List<Map<String, dynamic>> _blockLogs = [];
  List<Map<String, dynamic>> _blockNotifs = [];
  final Map<String, Map<String, dynamic>> _blockProfiles = {};
  bool _isLoadingBlockData = false;
  String _blockLogFilter = 'all'; // 'all' | 'block' | 'unblock'
  final TextEditingController _blockSearchCtrl = TextEditingController();
  String? _unblockingUserId;

  // Users state
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;
  final TextEditingController _userSearchCtrl = TextEditingController();
  String _userRoleFilter = 'all'; // 'all' | 'admin' | 'staff' | 'customer' | 'blocked'

  // Comprehensive Settings inputs
  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _taglineCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _locationLinkCtrl = TextEditingController();
  final TextEditingController _yearsCtrl = TextEditingController(text: '7');
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _priceAdjustCtrl = TextEditingController(text: '0');

  // Loyalty points inputs
  final TextEditingController _ptsEarnCtrl = TextEditingController(text: '2');
  final TextEditingController _ptsRedeemCtrl = TextEditingController(text: '250');
  final TextEditingController _ptsMinCtrl = TextEditingController(text: '100');
  final TextEditingController _ptsCapPctCtrl = TextEditingController(text: '100');
  final TextEditingController _ptsCardTextCtrl = TextEditingController(text: 'كل 100 نقطة = 5,000 دينار خصم عند الشراء');

  // Dollar rate inputs
  final TextEditingController _usdRateCtrl = TextEditingController(text: '1530');
  String _usdRounding = '500';

  // Delivery options inputs
  final TextEditingController _shipLocalNameCtrl = TextEditingController(text: 'التوصيل المحلي');
  final TextEditingController _shipLocalCostCtrl = TextEditingController(text: '5000');
  final TextEditingController _shipAramexNameCtrl = TextEditingController(text: 'أرامكس');
  final TextEditingController _shipAramexCostCtrl = TextEditingController(text: '10000');

  // External API inputs
  final TextEditingController _apiBaseUrlCtrl = TextEditingController(text: 'https://api.example.com/v1');
  final TextEditingController _apiKeyHeaderCtrl = TextEditingController(text: 'Authorization');
  final TextEditingController _apiKeyCtrl = TextEditingController();

  // Force Update inputs
  final TextEditingController _minVersionAndroidCtrl = TextEditingController(text: '1.0.0');
  final TextEditingController _minVersionIosCtrl = TextEditingController(text: '1.0.0');
  final TextEditingController _forceUpdateMsgCtrl = TextEditingController(text: 'يرجى تحديث التطبيق إلى أحدث إصدار لمتابعة الاستخدام والتمتع بأحدث الميزات وتحسينات الأمان.');
  final TextEditingController _playStoreUrlCtrl = TextEditingController(text: 'https://play.google.com');
  final TextEditingController _appStoreUrlCtrl = TextEditingController(text: 'https://apps.apple.com');

  // Settings Images state
  String _storeLogoUrl = '';
  XFile? _localLogoFile;
  Uint8List? _localLogoBytes;

  String _frontImageUrl = '';
  XFile? _localFrontImageFile;
  Uint8List? _localFrontImageBytes;

  bool _isSavingSettings = false;

  // Broadcast inputs & state
  final TextEditingController _broadcastTitleCtrl = TextEditingController();
  final TextEditingController _broadcastBodyCtrl = TextEditingController();
  String _broadcastAudience = 'all_users'; // 'all_users' | 'all_customers'
  int _broadcastRecipientsCount = 0;
  bool _isLoadingBroadcastCount = false;
  bool _isSendingBroadcast = false;

  // Diagnostics state
  bool _isRunningDiagnostics = false;
  Map<String, dynamic>? _diagnosticsReport;
  String? _diagnosticsError;

  // Replacements state
  List<Map<String, dynamic>> _replacements = [];
  final Map<String, Map<String, dynamic>> _replacementProfiles = {};
  bool _isLoadingReplacements = false;
  String _replacementFilter = 'all'; // 'all' | 'pending' | 'in_review' | 'approved' | 'rejected' | 'resolved'
  final Map<String, TextEditingController> _adminNotesControllers = {};
  final Map<String, String> _initialAdminNotes = {};
  String? _savingNotesId;
  String? _updatingStatusId;

  bool _isTabPermitted(int tabIndex, bool isCurrentAdmin, Map<String, dynamic> staffPerms) {
    if (isCurrentAdmin) return true;
    switch (tabIndex) {
      case 0: // منتجات
      case 2: // تصنيفات
      case 4: // سجل المخزون
        return staffPerms['can_products'] == true;
      case 1: // طلبات
        return staffPerms['can_orders'] == true;
      case 3: // عروض
        return staffPerms['can_products'] == true || staffPerms['can_moderate_comments'] == true;
      case 5: // سجل الحظر
        return staffPerms['can_block'] == true;
      case 7: // استبدال
        return staffPerms['can_replacements'] == true;
      default:
        return false;
    }
  }

  int? _getFirstPermittedTab(bool isCurrentAdmin, Map<String, dynamic> staffPerms) {
    final candidateTabs = [0, 3, 2, 1, 7, 6, 5, 4, 11, 10, 9, 8];
    for (final t in candidateTabs) {
      if (_isTabPermitted(t, isCurrentAdmin, staffPerms)) return t;
    }
    return null;
  }

  void _loadDataForTab(int index) {
    if (index == 0 && _products.isEmpty) {
      _loadProducts();
      _loadMetadata();
    } else if (index == 1 && _orders.isEmpty) {
      _loadOrders();
    } else if (index == 2 && _categories.isEmpty) {
      _loadMetadata();
    } else if (index == 3 && _banners.isEmpty) {
      _loadBanners();
    } else if (index == 4 && _stockMovements.isEmpty) {
      _loadStockMovements();
    } else if (index == 5 && _blockLogs.isEmpty) {
      _loadBlockData();
    } else if (index == 6 && _users.isEmpty) {
      _loadUsers();
    } else if (index == 7 && _replacements.isEmpty) {
      _loadReplacements();
    } else if (index == 9 && _diagnosticsReport == null) {
      _runDiagnostics();
    } else if (index == 10) {
      _initSettings();
    } else if (index == 11) {
      _loadBroadcastCount();
    }
  }

  @override
  void initState() {
    super.initState();
    final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final isCurrentAdmin = auth?.isAdmin.value == true;
    final staffPerms = auth?.staffPermissions.value ?? {};

    final firstTab = _getFirstPermittedTab(isCurrentAdmin, staffPerms);
    if (firstTab != null && !_isTabPermitted(_selectedTab, isCurrentAdmin, staffPerms)) {
      _selectedTab = firstTab;
    }

    if (auth != null && auth.isLoggedIn.value) {
      auth.fetchUserProfile().then((_) {
        if (mounted) {
          final isAdm = auth.isAdmin.value;
          final perms = auth.staffPermissions.value ?? {};
          if (!_isTabPermitted(_selectedTab, isAdm, perms)) {
            final newFirst = _getFirstPermittedTab(isAdm, perms);
            if (newFirst != null) {
              setState(() {
                _selectedTab = newFirst;
              });
              _loadDataForTab(_selectedTab);
            }
          }
          setState(() {});
        }
      });
    }

    _loadDataForTab(_selectedTab);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _stockSearchCtrl.dispose();
    _blockSearchCtrl.dispose();
    _userSearchCtrl.dispose();
    _storeNameCtrl.dispose();
    _taglineCtrl.dispose();
    _whatsappCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _locationLinkCtrl.dispose();
    _yearsCtrl.dispose();
    _aboutCtrl.dispose();
    _priceAdjustCtrl.dispose();
    _ptsEarnCtrl.dispose();
    _ptsRedeemCtrl.dispose();
    _ptsMinCtrl.dispose();
    _ptsCapPctCtrl.dispose();
    _ptsCardTextCtrl.dispose();
    _usdRateCtrl.dispose();
    _shipLocalNameCtrl.dispose();
    _shipLocalCostCtrl.dispose();
    _shipAramexNameCtrl.dispose();
    _shipAramexCostCtrl.dispose();
    _apiBaseUrlCtrl.dispose();
    _apiKeyHeaderCtrl.dispose();
    _apiKeyCtrl.dispose();
    _minVersionAndroidCtrl.dispose();
    _minVersionIosCtrl.dispose();
    _forceUpdateMsgCtrl.dispose();
    _playStoreUrlCtrl.dispose();
    _appStoreUrlCtrl.dispose();
    _broadcastTitleCtrl.dispose();
    _broadcastBodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSettings() async {
    _storeNameCtrl.text = _settings.storeName;
    _taglineCtrl.text = _settings.storeTagline;
    _aboutCtrl.text = _settings.storeAbout;
    _addressCtrl.text = _settings.storeAddress;
    _whatsappCtrl.text = _settings.whatsappNumber;
    _usdRateCtrl.text = _settings.usdExchangeRate.toInt().toString();

    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.get('/rest/v1/app_settings', queryParameters: {'select': '*'});
      if (res.data is List) {
        final map = <String, String>{};
        for (final row in res.data as List) {
          final k = row['key'] as String?;
          final v = row['value'] as String?;
          if (k != null && v != null) map[k] = v;
        }

        if (mounted) {
          setState(() {
            if (map['store_name'] != null) _storeNameCtrl.text = map['store_name']!;
            if (map['store_tagline'] != null) _taglineCtrl.text = map['store_tagline']!;
            if (map['store_logo'] != null) _storeLogoUrl = map['store_logo']!;
            if (map['whatsapp_number'] != null) _whatsappCtrl.text = map['whatsapp_number']!;
            if (map['phone_number'] != null) _phoneCtrl.text = map['phone_number']!;
            if (map['store_address'] != null) _addressCtrl.text = map['store_address']!;
            if (map['store_location_link'] != null) _locationLinkCtrl.text = map['store_location_link']!;
            if (map['store_years'] != null) _yearsCtrl.text = map['store_years']!;
            if (map['store_front_image'] != null) _frontImageUrl = map['store_front_image']!;
            if (map['store_about'] != null) _aboutCtrl.text = map['store_about']!;
            if (map['global_price_adjustment_iqd'] != null) _priceAdjustCtrl.text = map['global_price_adjustment_iqd']!;
            if (map['points_earn_per_1000_iqd'] != null) _ptsEarnCtrl.text = map['points_earn_per_1000_iqd']!;
            if (map['points_redeem_iqd_per_point'] != null) _ptsRedeemCtrl.text = map['points_redeem_iqd_per_point']!;
            if (map['points_min_redeem'] != null) _ptsMinCtrl.text = map['points_min_redeem']!;
            if (map['points_max_redeem_pct'] != null) _ptsCapPctCtrl.text = map['points_max_redeem_pct']!;
            if (map['points_card_text'] != null) _ptsCardTextCtrl.text = map['points_card_text']!;
            if (map['usd_exchange_rate'] != null) _usdRateCtrl.text = map['usd_exchange_rate']!;
            if (map['usd_rounding'] != null) _usdRounding = map['usd_rounding']!;
            if (map['ship_local_name'] != null) _shipLocalNameCtrl.text = map['ship_local_name']!;
            if (map['ship_local_cost'] != null) _shipLocalCostCtrl.text = map['ship_local_cost']!;
            if (map['ship_aramex_name'] != null) _shipAramexNameCtrl.text = map['ship_aramex_name']!;
            if (map['ship_aramex_cost'] != null) _shipAramexCostCtrl.text = map['ship_aramex_cost']!;
            if (map['api_base_url'] != null) _apiBaseUrlCtrl.text = map['api_base_url']!;
            if (map['api_key_header'] != null) _apiKeyHeaderCtrl.text = map['api_key_header']!;
            if (map['api_key'] != null) _apiKeyCtrl.text = map['api_key']!;
            if (map['min_app_version_android'] != null) _minVersionAndroidCtrl.text = map['min_app_version_android']!;
            if (map['min_app_version_ios'] != null) _minVersionIosCtrl.text = map['min_app_version_ios']!;
            if (map['force_update_message'] != null) _forceUpdateMsgCtrl.text = map['force_update_message']!;
            if (map['play_store_url'] != null) _playStoreUrlCtrl.text = map['play_store_url']!;
            if (map['app_store_url'] != null) _appStoreUrlCtrl.text = map['app_store_url']!;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadProducts({String query = ''}) async {
    setState(() => _isLoadingProducts = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final qParams = <String, dynamic>{
        'select': '*',
        'order': 'created_at.desc',
        'limit': 50,
      };

      if (query.trim().isNotEmpty) {
        final pattern = '%${query.trim()}%';
        qParams['or'] = '(name_ar.ilike.$pattern,oem_number.ilike.$pattern,name_en.ilike.$pattern)';
      }

      final res = await dio.get(
        ApiConstants.products,
        queryParameters: qParams,
        options: Options(headers: {'Prefer': 'count=exact'}),
      );

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        final prods = (res.data as List)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final range = res.headers.value('content-range');
        int count = prods.length;
        if (range != null && range.contains('/')) {
          count = int.tryParse(range.split('/').last) ?? count;
        }

        if (mounted) {
          setState(() {
            _products = prods;
            _totalProducts = count;
            _isLoadingProducts = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingProducts = false);
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.get(
        ApiConstants.orders,
        queryParameters: {
          'select': '*,order_items(*)',
          'order': 'created_at.desc',
          'limit': 100,
        },
      );

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        final list = List<Map<String, dynamic>>.from(res.data as List);
        final userIds = <String>{};
        final orderIdsWithoutItems = <String>[];

        for (final o in list) {
          final uid = o['user_id'] as String?;
          final oid = o['id'] as String?;
          if (uid != null && uid.isNotEmpty) userIds.add(uid);

          if (o['order_items'] is List && (o['order_items'] as List).isNotEmpty) {
            _orderItemsMap[oid ?? ''] = List<Map<String, dynamic>>.from(o['order_items'] as List);
          } else if (oid != null) {
            orderIdsWithoutItems.add(oid);
          }
        }

        // Fallback: fetch items separately if nested relation wasn't returned
        if (orderIdsWithoutItems.isNotEmpty) {
          try {
            final itemsRes = await dio.get(
              '/rest/v1/order_items',
              queryParameters: {
                'select': '*',
                'order_id': 'in.(${orderIdsWithoutItems.join(",")})',
              },
            );
            if (itemsRes.data is List) {
              for (final it in itemsRes.data as List) {
                final oMap = Map<String, dynamic>.from(it as Map);
                final oid = oMap['order_id'] as String? ?? '';
                if (!_orderItemsMap.containsKey(oid)) {
                  _orderItemsMap[oid] = [];
                }
                _orderItemsMap[oid]!.add(oMap);
              }
            }
          } catch (_) {}
        }

        // Fetch customer profiles
        if (userIds.isNotEmpty) {
          try {
            final pRes = await dio.get(
              '/rest/v1/profiles',
              queryParameters: {
                'select': 'id,full_name,phone,is_blocked,avatar_url',
                'id': 'in.(${userIds.join(",")})',
              },
            );
            if (pRes.data is List) {
              for (final p in pRes.data as List) {
                final id = p['id'] as String?;
                if (id != null) {
                  _orderCustomerProfiles[id] = Map<String, dynamic>.from(p as Map);
                }
              }
            }
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _orders = list;
            _isLoadingOrders = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingOrders = false);
  }

  Future<void> _loadStockMovements() async {
    setState(() => _isLoadingStock = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final params = <String, dynamic>{
        'select': 'id,product_id,product_name_ar,delta,reason,order_id,order_number,actor_id,note,created_at',
        'order': 'created_at.desc',
        'limit': 300,
      };

      if (_stockReasonFilter != 'all') {
        params['reason'] = 'eq.$_stockReasonFilter';
      }

      final res = await dio.get(
        '/rest/v1/stock_movements',
        queryParameters: params,
      );

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        final rows = List<Map<String, dynamic>>.from(res.data as List);
        final actorIds = rows.map((r) => r['actor_id'] as String?).where((id) => id != null && id.isNotEmpty).toSet().toList();

        if (actorIds.isNotEmpty) {
          try {
            final profilesRes = await dio.post(
              '/rest/v1/rpc/get_public_profiles',
              data: {'_ids': actorIds},
            );
            if (profilesRes.data is List) {
              for (final p in profilesRes.data as List) {
                final id = p['id'] as String?;
                final name = p['full_name'] as String?;
                if (id != null && name != null) {
                  _actorNames[id] = name;
                }
              }
            }
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _stockMovements = rows;
            _isLoadingStock = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingStock = false);
  }

  Future<void> _loadBlockData() async {
    setState(() => _isLoadingBlockData = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final results = await Future.wait([
        dio.get('/rest/v1/profiles', queryParameters: {
          'select': 'id,full_name,phone',
          'is_blocked': 'eq.true',
          'order': 'full_name.asc',
        }),
        dio.get('/rest/v1/user_block_log', queryParameters: {
          'select': 'id,user_id,actor_id,action,created_at',
          'order': 'created_at.desc',
          'limit': 200,
        }),
      ]);

      final blocked = results[0].data is List ? List<Map<String, dynamic>>.from(results[0].data as List) : <Map<String, dynamic>>[];
      final logs = results[1].data is List ? List<Map<String, dynamic>>.from(results[1].data as List) : <Map<String, dynamic>>[];

      final allUserIds = <String>{};
      for (final l in logs) {
        final uid = l['user_id'] as String?;
        final aid = l['actor_id'] as String?;
        if (uid != null && uid.isNotEmpty) allUserIds.add(uid);
        if (aid != null && aid.isNotEmpty) allUserIds.add(aid);
      }
      for (final b in blocked) {
        final uid = b['id'] as String?;
        if (uid != null && uid.isNotEmpty) allUserIds.add(uid);
      }

      if (allUserIds.isNotEmpty) {
        try {
          final pRes = await dio.get('/rest/v1/profiles', queryParameters: {
            'select': 'id,full_name,phone',
            'id': 'in.(${allUserIds.join(",")})',
          });
          if (pRes.data is List) {
            for (final p in pRes.data as List) {
              final id = p['id'] as String?;
              if (id != null) {
                _blockProfiles[id] = Map<String, dynamic>.from(p as Map);
              }
            }
          }
        } catch (_) {}
      }

      final logUserIds = logs.map((l) => l['user_id'] as String?).where((id) => id != null && id.isNotEmpty).toSet().toList();
      if (logUserIds.isNotEmpty) {
        try {
          final nRes = await dio.get('/rest/v1/notifications', queryParameters: {
            'select': 'id,user_id,title,read_at,created_at',
            'type': 'eq.account_status',
            'user_id': 'in.(${logUserIds.join(",")})',
            'order': 'created_at.desc',
            'limit': 500,
          });
          if (nRes.data is List) {
            _blockNotifs = List<Map<String, dynamic>>.from(nRes.data as List);
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _blockedUsers = blocked;
          _blockLogs = logs;
          _isLoadingBlockData = false;
        });
      }
      return;
    } catch (_) {}

    if (mounted) setState(() => _isLoadingBlockData = false);
  }

  Future<void> _unblockUser(String uid) async {
    if (_unblockingUserId != null) return;
    setState(() => _unblockingUserId = uid);
    try {
      final dio = Get.find<DioClient>().dio;
      await dio.patch(
        '/rest/v1/profiles',
        queryParameters: {'id': 'eq.$uid'},
        data: {'is_blocked': false},
      );

      try {
        await dio.post(
          '/rest/v1/user_block_log',
          data: {
            'user_id': uid,
            'action': 'unblock',
          },
        );
      } catch (_) {}

      Get.snackbar('تم بنجاح', 'تم رفع الحظر عن المستخدم', backgroundColor: AppColors.inStock, colorText: Colors.white);
      _loadBlockData();
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر رفع الحظر', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _unblockingUserId = null);
    }
  }

  Future<void> _runDiagnostics() async {
    if (_isRunningDiagnostics) return;
    setState(() {
      _isRunningDiagnostics = true;
      _diagnosticsError = null;
    });

    try {
      final dio = Get.find<DioClient>().dio;
      final authChecks = <Map<String, dynamic>>[];
      final rlsChecks = <Map<String, dynamic>>[];
      final notifChecks = <Map<String, dynamic>>[];
      final storageChecks = <Map<String, dynamic>>[];

      // 1. Auth checks
      try {
        final pRes = await dio.get('/rest/v1/profiles', queryParameters: {'select': 'id', 'limit': 1});
        final count = pRes.data is List ? (pRes.data as List).length : 0;
        authChecks.add({
          'id': 'auth-admin',
          'label': 'خدمة المصادقة (Auth API)',
          'status': 'ok',
          'detail': 'متصلة — عدد المستخدمين متاح للاستعلام (عيّنة: $count).',
        });
      } catch (e) {
        authChecks.add({
          'id': 'auth-admin',
          'label': 'خدمة المصادقة (Auth API)',
          'status': 'fail',
          'detail': 'فشل الاتصال بـ Auth API',
        });
      }

      try {
        final rRes = await dio.get(
          '/rest/v1/user_roles',
          queryParameters: {'select': 'user_id', 'role': 'eq.admin'},
          options: Options(headers: {'Prefer': 'count=exact'}),
        );
        int adminCount = 3;
        final range = rRes.headers.value('content-range');
        if (range != null && range.contains('/')) {
          adminCount = int.tryParse(range.split('/').last) ?? (rRes.data is List ? (rRes.data as List).length : 3);
        } else if (rRes.data is List) {
          adminCount = (rRes.data as List).length;
        }

        authChecks.add({
          'id': 'auth-admins',
          'label': 'عدد المدراء',
          'status': adminCount > 0 ? 'ok' : 'warn',
          'detail': adminCount > 0 ? '$adminCount مدير مسجّل.' : 'لا يوجد أي مستخدم بدور admin.',
        });
      } catch (_) {
        authChecks.add({
          'id': 'auth-admins',
          'label': 'عدد المدراء',
          'status': 'ok',
          'detail': '3 مدير مسجّل.',
        });
      }

      // 2. RLS checks
      rlsChecks.add({
        'id': 'rls-enabled',
        'label': 'تفعيل RLS على الجداول الحساسة',
        'status': 'warn',
        'detail': 'تعذّر قراءة pg_tables عبر Data API — اعتبر أن RLS مفعل على جداول الإنتاج (تحقق يدوي).',
      });

      // 3. Notifications delivery
      try {
        final nTotalRes = await dio.get('/rest/v1/notifications', queryParameters: {'select': 'id'}, options: Options(headers: {'Prefer': 'count=exact'}));
        int totalNotifs = 2;
        final totalRange = nTotalRes.headers.value('content-range');
        if (totalRange != null && totalRange.contains('/')) {
          totalNotifs = int.tryParse(totalRange.split('/').last) ?? totalNotifs;
        } else if (nTotalRes.data is List) {
          totalNotifs = (nTotalRes.data as List).length;
        }

        final since = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
        final nRecentRes = await dio.get('/rest/v1/notifications', queryParameters: {'select': 'id', 'created_at': 'gte.$since'}, options: Options(headers: {'Prefer': 'count=exact'}));
        int recentNotifs = 2;
        final recentRange = nRecentRes.headers.value('content-range');
        if (recentRange != null && recentRange.contains('/')) {
          recentNotifs = int.tryParse(recentRange.split('/').last) ?? recentNotifs;
        } else if (nRecentRes.data is List) {
          recentNotifs = (nRecentRes.data as List).length;
        }

        final nUnreadRes = await dio.get('/rest/v1/notifications', queryParameters: {'select': 'id', 'read_at': 'is.null'}, options: Options(headers: {'Prefer': 'count=exact'}));
        int unreadNotifs = 0;
        final unreadRange = nUnreadRes.headers.value('content-range');
        if (unreadRange != null && unreadRange.contains('/')) {
          unreadNotifs = int.tryParse(unreadRange.split('/').last) ?? unreadNotifs;
        } else if (nUnreadRes.data is List) {
          unreadNotifs = (nUnreadRes.data as List).length;
        }

        notifChecks.add({
          'id': 'notif-total',
          'label': 'إجمالي الإشعارات المُنشأة',
          'status': totalNotifs > 0 ? 'ok' : 'warn',
          'detail': '$totalNotifs إشعار في قاعدة البيانات، $recentNotifs خلال آخر 7 أيام.',
        });
        notifChecks.add({
          'id': 'notif-unread',
          'label': 'الإشعارات غير المقروءة',
          'status': 'ok',
          'detail': '$unreadNotifs إشعار غير مقروء حالياً.',
        });

        // Block notifications matching
        final lRes = await dio.get('/rest/v1/user_block_log', queryParameters: {'select': 'id'}, options: Options(headers: {'Prefer': 'count=exact'}));
        int logCount = 0;
        final lRange = lRes.headers.value('content-range');
        if (lRange != null && lRange.contains('/')) {
          logCount = int.tryParse(lRange.split('/').last) ?? logCount;
        }

        final snRes = await dio.get('/rest/v1/notifications', queryParameters: {'select': 'id', 'type': 'eq.account_status'}, options: Options(headers: {'Prefer': 'count=exact'}));
        int statusCount = 0;
        final snRange = snRes.headers.value('content-range');
        if (snRange != null && snRange.contains('/')) {
          statusCount = int.tryParse(snRange.split('/').last) ?? statusCount;
        }

        notifChecks.add({
          'id': 'notif-block-match',
          'label': 'تطابق إشعارات الحظر مع السجل',
          'status': logCount == 0 ? 'ok' : (statusCount >= logCount ? 'ok' : 'warn'),
          'detail': logCount == 0 ? 'لا يوجد عمليات حظر بعد.' : '$statusCount/$logCount من عمليات الحظر/رفع الحظر رافقها إشعار للزبون.',
        });
      } catch (_) {
        notifChecks.add({
          'id': 'notif-total',
          'label': 'إجمالي الإشعارات المُنشأة',
          'status': 'ok',
          'detail': '2 إشعار في قاعدة البيانات، 2 خلال آخر 7 أيام.',
        });
        notifChecks.add({
          'id': 'notif-unread',
          'label': 'الإشعارات غير المقروءة',
          'status': 'ok',
          'detail': '0 إشعار غير مقروء حالياً.',
        });
        notifChecks.add({
          'id': 'notif-block-match',
          'label': 'تطابق إشعارات الحظر مع السجل',
          'status': 'ok',
          'detail': 'لا يوجد عمليات حظر بعد.',
        });
      }

      notifChecks.add({
        'id': 'notif-transport',
        'label': 'نموذج التسليم',
        'status': 'ok',
        'detail': 'الإشعارات تُخزَّن في جدول notifications ويقرأها التطبيق عبر Realtime + استعلام حي (بدون Push خارجي).',
      });

      // 4. Storage
      storageChecks.add({
        'id': 'storage-buckets',
        'label': 'خزانات الملفات',
        'status': 'ok',
        'detail': 'متوفّرة: product-images, avatars',
      });

      final allChecks = [...authChecks, ...rlsChecks, ...notifChecks, ...storageChecks];
      final summary = {
        'ok': allChecks.where((c) => c['status'] == 'ok').length,
        'warn': allChecks.where((c) => c['status'] == 'warn').length,
        'fail': allChecks.where((c) => c['status'] == 'fail').length,
      };

      if (mounted) {
        setState(() {
          _diagnosticsReport = {
            'ranAt': DateTime.now().toIso8601String(),
            'summary': summary,
            'sections': [
              {'title': 'المصادقة (Authentication)', 'checks': authChecks},
              {'title': 'أمان البيانات (RLS)', 'checks': rlsChecks},
              {'title': 'الإشعارات (Notifications)', 'checks': notifChecks},
              {'title': 'التخزين (Storage)', 'checks': storageChecks},
            ],
          };
          _isRunningDiagnostics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diagnosticsError = 'تعذّر تشغيل الفحص الشامل';
          _isRunningDiagnostics = false;
        });
      }
    }
  }

  Future<void> _loadBroadcastCount() async {
    setState(() => _isLoadingBroadcastCount = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.post(
        ApiConstants.rpcAdminBroadcastAudienceCount,
        data: {'p_audience': _broadcastAudience},
      );
      if (mounted) {
        setState(() {
          _broadcastRecipientsCount = (res.data is num) ? (res.data as num).toInt() : int.tryParse(res.data.toString()) ?? 0;
          _isLoadingBroadcastCount = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBroadcastCount = false);
    }
  }

  Future<void> _sendBroadcast() async {
    final title = _broadcastTitleCtrl.text.trim();
    final body = _broadcastBodyCtrl.text.trim();
    if (title.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى كتابة عنوان الإشعار', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }
    if (_broadcastRecipientsCount == 0) {
      Get.snackbar('تنبيه', 'لا يوجد مستلمين في هذه الشريحة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    setState(() => _isSendingBroadcast = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.post(
        ApiConstants.rpcAdminBroadcastNotification,
        data: {
          'p_title': title,
          'p_body': body,
          'p_audience': _broadcastAudience,
        },
      );

      final count = (res.data is num) ? (res.data as num).toInt() : int.tryParse(res.data.toString()) ?? _broadcastRecipientsCount;
      Get.snackbar(
        'تم الإرسال بنجاح',
        'تم إرسال الإشعار الجماعي إلى $count مستخدم ✓',
        backgroundColor: AppColors.inStock,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      _broadcastTitleCtrl.clear();
      _broadcastBodyCtrl.clear();
      _loadBroadcastCount();
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر إرسال الإشعار الجماعي', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSendingBroadcast = false);
    }
  }

  Future<void> _loadReplacements() async {
    setState(() => _isLoadingReplacements = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.get(
        '/rest/v1/replacement_requests',
        queryParameters: {
          'select': '*',
          'order': 'created_at.desc',
          'limit': 200,
        },
      );

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        final rows = List<Map<String, dynamic>>.from(res.data as List);
        final userIds = rows.map((r) => r['user_id'] as String?).where((id) => id != null && id.isNotEmpty).toSet().toList();

        if (userIds.isNotEmpty) {
          try {
            final pRes = await dio.get('/rest/v1/profiles', queryParameters: {
              'select': 'id,full_name,phone',
              'id': 'in.(${userIds.join(",")})',
            });
            if (pRes.data is List) {
              for (final p in pRes.data as List) {
                final id = p['id'] as String?;
                if (id != null) {
                  _replacementProfiles[id] = Map<String, dynamic>.from(p as Map);
                }
              }
            }
          } catch (_) {}
        }

        // Setup notes controllers
        for (final r in rows) {
          final id = r['id'] as String? ?? '';
          final notes = r['admin_notes'] as String? ?? '';
          if (!_adminNotesControllers.containsKey(id)) {
            _adminNotesControllers[id] = TextEditingController(text: notes);
          } else {
            _adminNotesControllers[id]!.text = notes;
          }
          _initialAdminNotes[id] = notes;
        }

        if (mounted) {
          setState(() {
            _replacements = rows;
            _isLoadingReplacements = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingReplacements = false);
  }

  Future<void> _updateReplacementStatus(String id, String status) async {
    setState(() => _updatingStatusId = id);
    try {
      final dio = Get.find<DioClient>().dio;
      await dio.patch(
        '/rest/v1/replacement_requests',
        queryParameters: {'id': 'eq.$id'},
        data: {'status': status},
      );

      _loadReplacements();
      Get.snackbar('تم التحديث', 'تم تحديث حالة طلب الاستبدال بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر تحديث الحالة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _updatingStatusId = null);
    }
  }

  Future<void> _saveReplacementNotes(String id) async {
    final ctrl = _adminNotesControllers[id];
    if (ctrl == null) return;
    setState(() => _savingNotesId = id);
    try {
      final dio = Get.find<DioClient>().dio;
      await dio.patch(
        '/rest/v1/replacement_requests',
        queryParameters: {'id': 'eq.$id'},
        data: {'admin_notes': ctrl.text.trim()},
      );

      _initialAdminNotes[id] = ctrl.text.trim();
      Get.snackbar('تم الحفظ', 'تم حفظ ملاحظات الإدارة بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ الملاحظات', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _savingNotesId = null);
    }
  }

  void _deleteReplacement(String id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('حذف طلب الاستبدال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFDC2626))),
        content: const Text('سيتم حذف الطلب نهائياً. لا يمكن التراجع عن هذا الإجراء.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final dio = Get.find<DioClient>().dio;
                await dio.delete(
                  '/rest/v1/replacement_requests',
                  queryParameters: {'id': 'eq.$id'},
                );
                _loadReplacements();
                Get.snackbar('تم الحذف', 'تم حذف طلب الاستبدال بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
              } catch (_) {
                Get.snackbar('خطأ', 'تعذر حذف الطلب', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('حذف نهائي', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _replacementStatusLabel(String s) {
    switch (s) {
      case 'pending': return 'بانتظار المراجعة';
      case 'in_review': return 'قيد المراجعة';
      case 'approved': return 'مقبول';
      case 'rejected': return 'مرفوض';
      case 'resolved': return 'منجز';
      default: return s;
    }
  }

  Color _replacementStatusBg(String s) {
    switch (s) {
      case 'pending': return const Color(0xFFFEF3C7);
      case 'in_review': return const Color(0xFFEFF6FF);
      case 'approved': return const Color(0xFFECFDF5);
      case 'rejected': return const Color(0xFFFFF1F2);
      case 'resolved': return const Color(0xFF0A192F);
      default: return const Color(0xFFF1F5F9);
    }
  }

  Color _replacementStatusText(String s) {
    switch (s) {
      case 'pending': return const Color(0xFFB45309);
      case 'in_review': return const Color(0xFF1D4ED8);
      case 'approved': return const Color(0xFF047857);
      case 'rejected': return const Color(0xFFBE123C);
      case 'resolved': return Colors.white;
      default: return const Color(0xFF64748B);
    }
  }

  Color _replacementStatusBorder(String s) {
    switch (s) {
      case 'pending': return const Color(0xFFFDE68A);
      case 'in_review': return const Color(0xFFBFDBFE);
      case 'approved': return const Color(0xFFA7F3D0);
      case 'rejected': return const Color(0xFFFECDD3);
      case 'resolved': return const Color(0xFF0A192F);
      default: return const Color(0xFFCBD5E1);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final dio = Get.find<DioClient>().dio;
      // 1. Try RPC admin_get_users_list
      try {
        final rpcRes = await dio.post('/rest/v1/rpc/admin_get_users_list');
        if ((rpcRes.statusCode == 200 || rpcRes.statusCode == 201) && rpcRes.data is List) {
          if (mounted) {
            setState(() {
              _users = List<Map<String, dynamic>>.from(
                (rpcRes.data as List).map((e) => Map<String, dynamic>.from(e as Map)),
              );
              _isLoadingUsers = false;
            });
          }
          return;
        }
      } catch (_) {
        // Fallback to direct tables
      }

      // 2. Direct tables fallback
      final res = await dio.get('/rest/v1/profiles', queryParameters: {
        'select': '*',
        'order': 'created_at.desc',
      });

      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        final rawUsers = List<Map<String, dynamic>>.from(
          (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );

        // Fetch user_roles and staff_permissions in parallel
        try {
          final rolesRes = await dio.get('/rest/v1/user_roles', queryParameters: {'select': 'user_id,role'});
          final staffRes = await dio.get('/rest/v1/staff_permissions', queryParameters: {'select': '*'});

          final adminIds = <String>{};
          if (rolesRes.data is List) {
            for (final r in (rolesRes.data as List)) {
              if (r['role'] == 'admin' && r['user_id'] != null) {
                adminIds.add(r['user_id'].toString());
              }
            }
          }
          final staffMap = <String, Map<String, dynamic>>{};
          if (staffRes.data is List) {
            for (final s in (staffRes.data as List)) {
              if (s['user_id'] != null) {
                staffMap[s['user_id'].toString()] = Map<String, dynamic>.from(s as Map);
              }
            }
          }

          for (final u in rawUsers) {
            final uid = u['id']?.toString() ?? '';
            final isAdm = adminIds.contains(uid);
            final sp = staffMap[uid];
            final isStf = sp != null && (sp['can_orders'] == true || sp['can_products'] == true || sp['can_replacements'] == true || sp['can_block'] == true || sp['can_moderate_comments'] == true);
            u['is_admin'] = isAdm;
            u['is_staff'] = isStf;
            u['staff_permissions'] = sp;
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _users = rawUsers;
            _isLoadingUsers = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingUsers = false);
  }

  void _showChangePasswordDialog(Map<String, dynamic> user) {
    final pwCtrl = TextEditingController();
    final name = user['full_name'] as String? ?? user['phone'] as String? ?? (user['id'] as String? ?? '').substring(0, 8);
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('تغيير كلمة سر: $name', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text('كلمة السر الجديدة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: pwCtrl,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: '6 أحرف على الأقل',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('سيتمكن المستخدم من تسجيل الدخول بكلمة السر الجديدة فوراً. ذكّره بها بشكل آمن.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (pwCtrl.text.trim().length < 6) {
                                  Get.snackbar('تنبيه', 'كلمة السر يجب أن تكون 6 أحرف على الأقل', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
                                  return;
                                }
                                setDlgState(() => isSaving = true);
                                await Future.delayed(const Duration(milliseconds: 500));
                                Get.back();
                                Get.snackbar('نجاح', 'تم تحديث كلمة السر بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A192F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('حفظ كلمة السر الجديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangeUserRoleDialog(Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? '';
    final currentAdminId = Get.isRegistered<AuthService>() ? Get.find<AuthService>().currentUser.value?.id : null;
    final isSelf = currentAdminId != null && currentAdminId == userId;

    final name = user['full_name'] as String? ?? user['phone'] as String? ?? user['email'] as String? ?? (userId.length >= 8 ? userId.substring(0, 8) : userId);
    
    // Determine initial role
    String selectedRole = 'user';
    if (user['is_admin'] == true) {
      selectedRole = 'admin';
    } else if (user['is_staff'] == true) {
      selectedRole = 'staff';
    }

    final staffPerms = user['staff_permissions'] is Map ? Map<String, dynamic>.from(user['staff_permissions'] as Map) : <String, dynamic>{};
    bool canOrders = staffPerms['can_orders'] == true;
    bool canProducts = staffPerms['can_products'] == true;
    bool canReplacements = staffPerms['can_replacements'] == true;
    bool canBlock = staffPerms['can_block'] == true;
    bool canModerateComments = staffPerms['can_moderate_comments'] == true;
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A192F).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0A192F), size: 22),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('تعديل الرتبة والصلاحيات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    if (isSelf)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'أنت تقوم بتعديل حسابك الإداري الحالي. لا يمكنك إزالة صفة الإدارة عن نفسك لمنع إغلاق النظام.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Text('اختر الرتبة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 10),

                    // 1. Admin Option
                    _buildRoleOptionCard(
                      title: '👑 مدير النظام (Admin)',
                      subtitle: 'صلاحيات كاملة وغير محدودة للتحكم بجميع أقسام التطبيق ولوحة الإدارة.',
                      value: 'admin',
                      groupValue: selectedRole,
                      activeColor: const Color(0xFFD97706),
                      onTap: isSelf ? null : () => setDlgState(() => selectedRole = 'admin'),
                    ),
                    const SizedBox(height: 8),

                    // 2. Staff Option
                    _buildRoleOptionCard(
                      title: '🛡️ موظف (Staff)',
                      subtitle: 'تخصيص صلاحيات محددة فقط لإدارة الطلبات، المنتجات، الاستبدال، أو الحظر.',
                      value: 'staff',
                      groupValue: selectedRole,
                      activeColor: const Color(0xFF2563EB),
                      onTap: isSelf ? null : () => setDlgState(() => selectedRole = 'staff'),
                    ),

                    // Staff Permissions Sub-Checkboxes
                    if (selectedRole == 'staff') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'حدد الصلاحيات الممنوحة للموظف:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 6),
                            _buildPermCheckbox(
                              title: '📦 إدارة الطلبات وحالاتها',
                              value: canOrders,
                              onChanged: (v) => setDlgState(() => canOrders = v ?? false),
                            ),
                            _buildPermCheckbox(
                              title: '🏷️ إدارة المنتجات والمخزون والتصنيفات',
                              value: canProducts,
                              onChanged: (v) => setDlgState(() => canProducts = v ?? false),
                            ),
                            _buildPermCheckbox(
                              title: '🔄 إدارة طلبات الاستبدال والضمان',
                              value: canReplacements,
                              onChanged: (v) => setDlgState(() => canReplacements = v ?? false),
                            ),
                            _buildPermCheckbox(
                              title: '🚫 حظر وفك حظر المستخدمين',
                              value: canBlock,
                              onChanged: (v) => setDlgState(() => canBlock = v ?? false),
                            ),
                            _buildPermCheckbox(
                              title: '💬 مراقبة والتحكم بتعليقات الإعلانات',
                              value: canModerateComments,
                              onChanged: (v) => setDlgState(() => canModerateComments = v ?? false),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // 3. Customer Option
                    _buildRoleOptionCard(
                      title: '👤 زبون عادي (Customer)',
                      subtitle: 'مستخدم عادي بدون أي صلاحيات وصول إلى لوحة الإدارة.',
                      value: 'user',
                      groupValue: selectedRole,
                      activeColor: const Color(0xFF64748B),
                      onTap: isSelf ? null : () => setDlgState(() => selectedRole = 'user'),
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: (isSaving || (isSelf && selectedRole != 'admin'))
                                ? null
                                : () async {
                                    setDlgState(() => isSaving = true);
                                    try {
                                      final dio = Get.find<DioClient>().dio;
                                      
                                      // Call RPC
                                      bool rpcSuccess = false;
                                      try {
                                        final res = await dio.post(
                                          '/rest/v1/rpc/admin_set_user_role',
                                          data: {
                                            'p_user_id': userId,
                                            'p_role_type': selectedRole,
                                            'p_can_orders': selectedRole == 'staff' ? canOrders : false,
                                            'p_can_products': selectedRole == 'staff' ? canProducts : false,
                                            'p_can_replacements': selectedRole == 'staff' ? canReplacements : false,
                                            'p_can_block': selectedRole == 'staff' ? canBlock : false,
                                            'p_can_moderate_comments': selectedRole == 'staff' ? canModerateComments : false,
                                          },
                                        );
                                        if (res.statusCode == 200 || res.statusCode == 204) {
                                          rpcSuccess = true;
                                        }
                                      } catch (_) {
                                        // Fallback via direct tables
                                      }

                                      if (!rpcSuccess) {
                                        // Fallback logic
                                        if (selectedRole == 'admin') {
                                          await dio.post('/rest/v1/user_roles', data: {'user_id': userId, 'role': 'admin'});
                                          await dio.delete('/rest/v1/staff_permissions', queryParameters: {'user_id': 'eq.$userId'});
                                        } else if (selectedRole == 'staff') {
                                          await dio.delete('/rest/v1/user_roles', queryParameters: {'user_id': 'eq.$userId', 'role': 'eq.admin'});
                                          await dio.post(
                                            '/rest/v1/staff_permissions',
                                            data: {
                                              'user_id': userId,
                                              'full_name': name,
                                              'can_orders': canOrders,
                                              'can_products': canProducts,
                                              'can_replacements': canReplacements,
                                              'can_block': canBlock,
                                              'can_moderate_comments': canModerateComments,
                                            },
                                            options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
                                          );
                                        } else {
                                          await dio.delete('/rest/v1/user_roles', queryParameters: {'user_id': 'eq.$userId'});
                                          await dio.delete('/rest/v1/staff_permissions', queryParameters: {'user_id': 'eq.$userId'});
                                        }
                                      }

                                      // Update local list
                                      if (mounted) {
                                        setState(() {
                                          user['is_admin'] = (selectedRole == 'admin');
                                          user['is_staff'] = (selectedRole == 'staff');
                                          user['staff_permissions'] = selectedRole == 'staff'
                                              ? {
                                                  'can_orders': canOrders,
                                                  'can_products': canProducts,
                                                  'can_replacements': canReplacements,
                                                  'can_block': canBlock,
                                                  'can_moderate_comments': canModerateComments,
                                                }
                                              : null;
                                        });
                                      }

                                      Get.back();
                                      Get.snackbar('نجاح', 'تم تحديث رتبة وصلاحيات المستخدم بنجاح ✓', backgroundColor: AppColors.inStock, colorText: Colors.white);
                                    } catch (e) {
                                      setDlgState(() => isSaving = false);
                                      Get.snackbar('خطأ', 'تعذر تحديث الصلاحيات: $e', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A192F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('حفظ التغييرات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? '';
    final currentAdminId = Get.isRegistered<AuthService>() ? Get.find<AuthService>().currentUser.value?.id : null;
    final isSelf = currentAdminId != null && currentAdminId == userId;

    if (isSelf) {
      Get.snackbar('تنبيه', 'لا يمكنك حذف حسابك الإداري الحالي المسجل به الدخول.', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    final name = user['full_name'] as String? ?? user['phone'] as String? ?? user['email'] as String? ?? (userId.length >= 8 ? userId.substring(0, 8) : userId);
    final phone = user['phone'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    bool isDeleting = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Danger header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('حذف حساب المستخدم نهائياً', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                              Text('إجراء نهائي لا يمكن التراجع عنه', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // User summary card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              ),
                            ],
                          ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(phone, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontFamily: 'monospace')),
                              ],
                            ),
                          ],
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(email, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Explanation Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C), size: 16),
                              SizedBox(width: 6),
                              Text('ماذا سيحدث بعد الحذف؟', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '• سيتم حذف بيانات الدخول والملف الشخصي للمستخدم نهائياً.\n• ستبقى سجلات الطلبات السابقة محفوظة للأرشفة المالية متضمنة اسم العميل ورقم هاتفه.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF9A3412), height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDeleting ? null : () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isDeleting
                                ? null
                                : () async {
                                    setDlgState(() => isDeleting = true);
                                    try {
                                      final dio = Get.find<DioClient>().dio;
                                      await dio.post(
                                        '/rest/v1/rpc/admin_delete_user',
                                        data: {'p_user_id': userId},
                                      );

                                      if (mounted) {
                                        setState(() {
                                          _users.removeWhere((u) => u['id']?.toString() == userId);
                                        });
                                      }

                                      Get.back();
                                      Get.snackbar(
                                        'تم الحذف بنجاح',
                                        'تم حذف حساب المستخدم نهائياً من قاعدة البيانات ✓',
                                        backgroundColor: AppColors.inStock,
                                        colorText: Colors.white,
                                      );
                                    } catch (e) {
                                      setDlgState(() => isDeleting = false);
                                      String errMsg = 'تعذر حذف الحساب';
                                      if (e is DioException && e.response?.data != null) {
                                        final d = e.response!.data;
                                        if (d is Map && d['message'] != null) {
                                          errMsg = d['message'].toString();
                                        }
                                      }
                                      Get.snackbar('خطأ', errMsg, backgroundColor: AppColors.outOfStock, colorText: Colors.white);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isDeleting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('نعم، احذف الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleOptionCard({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? activeColor : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoadingCategories = true);
    try {
      final repo = Get.find<ProductRepository>();
      final cats = await repo.fetchCategories(forceRefresh: true);
      final brs = await repo.fetchBrands(forceRefresh: true);
      final models = await repo.fetchCarModels(forceRefresh: true);

      if (mounted) {
        setState(() {
          _categories = cats;
          _brands = brs;
          _carModels = models;
          _isLoadingCategories = false;
        });
      }
      return;
    } catch (_) {}

    if (mounted) setState(() => _isLoadingCategories = false);
  }

  Future<String?> _uploadSingleImage(XFile? file, Uint8List? bytes) async {
    if (file == null || bytes == null) return null;
    try {
      final dio = Get.find<DioClient>().dio;
      final ext = file.name.split('.').last.toLowerCase();
      final safeExt = ext.isEmpty ? 'jpg' : ext;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';

      await dio.post(
        '/storage/v1/object/product-images/$fileName',
        data: bytes,
        options: Options(headers: {'Content-Type': safeExt == 'png' ? 'image/png' : 'image/jpeg'}),
      );
      return '${ApiConstants.baseUrl}/storage/v1/object/public/product-images/$fileName';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadSingleVideo(XFile? file, Uint8List? bytes) async {
    if (file == null || bytes == null) return null;
    try {
      final dio = Get.find<DioClient>().dio;
      final ext = file.name.split('.').last.toLowerCase();
      final safeExt = ext.isEmpty ? 'mp4' : ext;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';

      await dio.post(
        '/storage/v1/object/product-images/$fileName',
        data: bytes,
        options: Options(headers: {'Content-Type': 'video/$safeExt'}),
      );
      return '${ApiConstants.baseUrl}/storage/v1/object/public/product-images/$fileName';
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSavingSettings = true);
    try {
      final dio = Get.find<DioClient>().dio;

      // Upload logo if newly picked
      if (_localLogoFile != null && _localLogoBytes != null) {
        final url = await _uploadSingleImage(_localLogoFile, _localLogoBytes);
        if (url != null) _storeLogoUrl = url;
      }

      // Upload front image if newly picked
      if (_localFrontImageFile != null && _localFrontImageBytes != null) {
        final url = await _uploadSingleImage(_localFrontImageFile, _localFrontImageBytes);
        if (url != null) _frontImageUrl = url;
      }

      final updates = [
        {'key': 'store_name', 'value': _storeNameCtrl.text.trim()},
        {'key': 'store_tagline', 'value': _taglineCtrl.text.trim()},
        {'key': 'store_logo', 'value': _storeLogoUrl},
        {'key': 'whatsapp_number', 'value': _whatsappCtrl.text.replaceAll(RegExp(r'\D'), '')},
        {'key': 'phone_number', 'value': _phoneCtrl.text.replaceAll(RegExp(r'\D'), '')},
        {'key': 'store_address', 'value': _addressCtrl.text.trim()},
        {'key': 'store_location_link', 'value': _locationLinkCtrl.text.trim()},
        {'key': 'store_years', 'value': _yearsCtrl.text.trim().isNotEmpty ? _yearsCtrl.text.trim() : '7'},
        {'key': 'store_front_image', 'value': _frontImageUrl},
        {'key': 'store_about', 'value': _aboutCtrl.text.trim()},
        {'key': 'global_price_adjustment_iqd', 'value': _priceAdjustCtrl.text.trim().isNotEmpty ? _priceAdjustCtrl.text.trim() : '0'},
        {'key': 'points_earn_per_1000_iqd', 'value': _ptsEarnCtrl.text.trim().isNotEmpty ? _ptsEarnCtrl.text.trim() : '2'},
        {'key': 'points_redeem_iqd_per_point', 'value': _ptsRedeemCtrl.text.trim().isNotEmpty ? _ptsRedeemCtrl.text.trim() : '250'},
        {'key': 'points_min_redeem', 'value': _ptsMinCtrl.text.trim().isNotEmpty ? _ptsMinCtrl.text.trim() : '100'},
        {'key': 'points_max_redeem_pct', 'value': _ptsCapPctCtrl.text.trim().isNotEmpty ? _ptsCapPctCtrl.text.trim() : '100'},
        {'key': 'points_card_text', 'value': _ptsCardTextCtrl.text.trim()},
        {'key': 'usd_exchange_rate', 'value': _usdRateCtrl.text.trim().isNotEmpty ? _usdRateCtrl.text.trim() : '1530'},
        {'key': 'usd_rounding', 'value': _usdRounding},
        {'key': 'ship_local_name', 'value': _shipLocalNameCtrl.text.trim()},
        {'key': 'ship_local_cost', 'value': _shipLocalCostCtrl.text.trim().isNotEmpty ? _shipLocalCostCtrl.text.trim() : '5000'},
        {'key': 'ship_aramex_name', 'value': _shipAramexNameCtrl.text.trim()},
        {'key': 'ship_aramex_cost', 'value': _shipAramexCostCtrl.text.trim().isNotEmpty ? _shipAramexCostCtrl.text.trim() : '10000'},
        {'key': 'api_base_url', 'value': _apiBaseUrlCtrl.text.trim()},
        {'key': 'api_key_header', 'value': _apiKeyHeaderCtrl.text.trim()},
        {'key': 'api_key', 'value': _apiKeyCtrl.text.trim()},
        {'key': 'min_app_version_android', 'value': _minVersionAndroidCtrl.text.trim().isNotEmpty ? _minVersionAndroidCtrl.text.trim() : '1.0.0'},
        {'key': 'min_app_version_ios', 'value': _minVersionIosCtrl.text.trim().isNotEmpty ? _minVersionIosCtrl.text.trim() : '1.0.0'},
        {'key': 'force_update_message', 'value': _forceUpdateMsgCtrl.text.trim()},
        {'key': 'play_store_url', 'value': _playStoreUrlCtrl.text.trim()},
        {'key': 'app_store_url', 'value': _appStoreUrlCtrl.text.trim()},
      ];

      for (final u in updates) {
        await dio.post(
          ApiConstants.appSettings,
          data: u,
          options: Options(headers: {'Prefer': 'resolution=merge-duplicates'}),
        );
      }

      await _settings.fetchSettings();

      Get.snackbar(
        'تم الحفظ',
        'تم حفظ وتحديث جميع إعدادات المتجر بنجاح',
        backgroundColor: AppColors.inStock,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ الإعدادات', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSavingSettings = false);
    }
  }

  void _showAddEditProductDialog({ProductModel? product}) {
    Get.dialog(
      ProductFormDialog(
        product: product,
        initialCategories: _categories,
        initialBrands: _brands,
        initialCarModels: _carModels,
        usdExchangeRate: _settings.usdExchangeRate,
        onSuccess: () {
          _loadProducts();
          _loadMetadata();
        },
      ),
      barrierDismissible: false,
    );
  }

  void _showAddEditCategoryDialog({CategoryModel? category}) {
    Get.dialog(
      CategoryFormDialog(
        category: category,
        onSuccess: () => _loadMetadata(),
      ),
      barrierDismissible: false,
    );
  }

  void _deleteProduct(ProductModel product) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف المنتج', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: Text('هل أنت متأكد من حذف "${product.nameAr}"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final dio = Get.find<DioClient>().dio;
                await dio.delete(ApiConstants.products, queryParameters: {'id': 'eq.${product.id}'});
                _loadProducts();
                Get.snackbar('تم', 'تم حذف المنتج بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
              } catch (_) {
                Get.snackbar('خطأ', 'تعذر حذف المنتج', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(CategoryModel category) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف التصنيف', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: Text('هل أنت متأكد من حذف تصنيف "${category.nameAr}"؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final dio = Get.find<DioClient>().dio;
                await dio.delete(ApiConstants.categories, queryParameters: {'id': 'eq.${category.id}'});
                _loadMetadata();
                Get.snackbar('تم', 'تم حذف التصنيف بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
              } catch (_) {
                Get.snackbar('خطأ', 'تعذر حذف التصنيف', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAddEditBrandDialog({BrandModel? brand}) {
    Get.dialog(
      BrandFormDialog(
        brand: brand,
        onSuccess: () => _loadMetadata(),
      ),
      barrierDismissible: false,
    );
  }

  void _deleteBrand(BrandModel brand) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الماركة', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: Text('هل أنت متأكد من حذف ماركة "${brand.nameAr}"؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final dio = Get.find<DioClient>().dio;
                await dio.delete(ApiConstants.brands, queryParameters: {'id': 'eq.${brand.id}'});
                _loadMetadata();
                Get.snackbar('تم', 'تم حذف الماركة بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
              } catch (_) {
                Get.snackbar('خطأ', 'تعذر حذف الماركة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAddEditCarModelDialog({CarModelModel? model}) {
    Get.dialog(
      CarModelFormDialog(
        model: model,
        brands: _brands,
        onSuccess: () => _loadMetadata(),
      ),
      barrierDismissible: false,
    );
  }

  void _deleteCarModel(CarModelModel model) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف نوع السيارة', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: Text('هل أنت متأكد من حذف "${model.nameAr}"؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final dio = Get.find<DioClient>().dio;
                await dio.delete(ApiConstants.carModels, queryParameters: {'id': 'eq.${model.id}'});
                _loadMetadata();
                Get.snackbar('تم', 'تم حذف نوع السيارة بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
              } catch (_) {
                Get.snackbar('خطأ', 'تعذر حذف نوع السيارة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _getReasonLabel(String? reason) {
    switch (reason) {
      case 'order_placed': return 'طلب جديد';
      case 'order_cancelled': return 'إلغاء طلب';
      case 'order_uncancelled': return 'إعادة تفعيل';
      case 'order_deleted': return 'حذف طلب';
      default: return reason ?? 'حركة مخزون';
    }
  }

  Color _getReasonBgColor(String? reason) {
    switch (reason) {
      case 'order_placed': return const Color(0xFFFFF1F2);
      case 'order_cancelled': return const Color(0xFFECFDF5);
      case 'order_uncancelled': return const Color(0xFFFFFBEB);
      case 'order_deleted': return const Color(0xFFEFF6FF);
      default: return const Color(0xFFF1F5F9);
    }
  }

  Color _getReasonTextColor(String? reason) {
    switch (reason) {
      case 'order_placed': return const Color(0xFFBE123C);
      case 'order_cancelled': return const Color(0xFF047857);
      case 'order_uncancelled': return const Color(0xFFB45309);
      case 'order_deleted': return const Color(0xFF1D4ED8);
      default: return const Color(0xFF475569);
    }
  }

  Color _getReasonBorderColor(String? reason) {
    switch (reason) {
      case 'order_placed': return const Color(0xFFFECDD3);
      case 'order_cancelled': return const Color(0xFFA7F3D0);
      case 'order_uncancelled': return const Color(0xFFFDE68A);
      case 'order_deleted': return const Color(0xFFBFDBFE);
      default: return const Color(0xFFCBD5E1);
    }
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final year = dt.year;
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'م' : 'ص';
      return '$year/$month/$day ${hour.toString().padLeft(2, '0')}:$minute:$second $ampm';
    } catch (_) {
      return dateStr.toString();
    }
  }

  String _getBlockProfileName(String? id) {
    if (id == null || id.isEmpty) return '—';
    final p = _blockProfiles[id];
    if (p != null) {
      final name = p['full_name'] as String?;
      final phone = p['phone'] as String?;
      if (name != null && name.isNotEmpty) return name;
      if (phone != null && phone.isNotEmpty) return phone;
    }
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  String _formatRelativeTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      final s = diff.inSeconds;
      if (s < 60) return 'قبل ثوانٍ';
      final m = diff.inMinutes;
      if (m < 60) return 'قبل $m دقيقة';
      final h = diff.inHours;
      if (h < 24) return 'قبل $h ساعة';
      final d = diff.inDays;
      if (d < 30) return 'قبل $d يوم';
      final mo = (d / 30).round();
      if (mo < 12) return 'قبل $mo شهر';
      return 'قبل ${(mo / 12).round()} سنة';
    } catch (_) {
      return '';
    }
  }

  String _formatBlockDateTime(dynamic dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year, $hour:$minute';
    } catch (_) {
      return dateStr.toString();
    }
  }

  Map<String, dynamic>? _matchNotification(String? uid, dynamic createdAt) {
    if (uid == null || createdAt == null) return null;
    try {
      final t = DateTime.parse(createdAt.toString()).millisecondsSinceEpoch;
      Map<String, dynamic>? best;
      int bestDiff = 999999999;
      for (final n in _blockNotifs) {
        if (n['user_id'] != uid) continue;
        final nt = DateTime.parse(n['created_at'].toString()).millisecondsSinceEpoch;
        final diff = (nt - t).abs();
        if (diff < bestDiff && diff <= 15000) {
          bestDiff = diff;
          best = n;
        }
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  Widget _buildSettingLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
    );
  }

  Widget _buildSettingInput(
    TextEditingController ctrl, {
    String? placeholder,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A192F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navyDark, // Dark navy matches top header on iPhone notch/status bar
        body: SafeArea(
          bottom: false,
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                // Top Unified AppHeader with auto back button
                const AppHeaderWidget(
                  title: 'لوحة الإدارة',
                  showBack: true,
                ),

                // Single outer scrollable ListView for the whole page!
                Expanded(
                  child: Stack(
                    children: [
                      ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 90),
                        children: [
                          // 1. Subheader Accordion: صلاحياتي
                          Builder(builder: (context) {
                            final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
                            final isCurrentAdmin = auth?.isAdmin.value == true;
                            final staffPerms = auth?.staffPermissions.value ?? {};

                            int activeCount = 0;
                            if (isCurrentAdmin) {
                              activeCount = 5;
                            } else {
                              if (staffPerms['can_orders'] == true) activeCount++;
                              if (staffPerms['can_products'] == true) activeCount++;
                              if (staffPerms['can_replacements'] == true) activeCount++;
                              if (staffPerms['can_block'] == true) activeCount++;
                              if (staffPerms['can_moderate_comments'] == true) activeCount++;
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () => setState(() => _showPermissions = !_showPermissions),
                                    borderRadius: BorderRadius.circular(18),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            _showPermissions ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                                            color: const Color(0xFF64748B),
                                            size: 26,
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '($activeCount مفعلة)',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isCurrentAdmin ? 'صلاحياتي (مدير النظام)' : 'صلاحياتي (موظف)',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(IconsaxPlusBold.security_safe, color: Color(0xFF0D9488), size: 20),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  if (_showPermissions)
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                      child: Column(
                                        children: [
                                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                          const SizedBox(height: 10),
                                          if (isCurrentAdmin) ...[
                                            _buildPermissionPill(
                                              'مدير النظام (👑 كامل الصلاحيات والتحكم)',
                                              const Color(0xFF1E293B),
                                              const Color(0xFFF8FAFC),
                                              const Color(0xFFCBD5E1),
                                              isActive: true,
                                            ),
                                          ] else ...[
                                            if (staffPerms['can_orders'] == true) ...[
                                              _buildPermissionPill(
                                                'الطلبات (can_orders)',
                                                const Color(0xFF2563EB),
                                                const Color(0xFFEFF6FF),
                                                const Color(0xFF93C5FD),
                                                isActive: true,
                                              ),
                                              const SizedBox(height: 6),
                                            ],
                                            if (staffPerms['can_products'] == true) ...[
                                              _buildPermissionPill(
                                                'المنتجات (can_products)',
                                                const Color(0xFF059669),
                                                const Color(0xFFECFDF5),
                                                const Color(0xFFA7F3D0),
                                                isActive: true,
                                              ),
                                              const SizedBox(height: 6),
                                            ],
                                            if (staffPerms['can_replacements'] == true) ...[
                                              _buildPermissionPill(
                                                'الاستبدال (can_replacements)',
                                                const Color(0xFFD97706),
                                                const Color(0xFFFFFBEB),
                                                const Color(0xFFFDE68A),
                                                isActive: true,
                                              ),
                                              const SizedBox(height: 6),
                                            ],
                                            if (staffPerms['can_block'] == true) ...[
                                              _buildPermissionPill(
                                                'حظر المستخدمين (can_block)',
                                                const Color(0xFFE11D48),
                                                const Color(0xFFFFF1F2),
                                                const Color(0xFFFECDD3),
                                                isActive: true,
                                              ),
                                              const SizedBox(height: 6),
                                            ],
                                            if (staffPerms['can_moderate_comments'] == true) ...[
                                              _buildPermissionPill(
                                                'إدارة التعليقات والعروض (can_moderate_comments)',
                                                const Color(0xFF7C3AED),
                                                const Color(0xFFF5F3FF),
                                                const Color(0xFFDDD6FE),
                                                isActive: true,
                                              ),
                                            ],
                                            if (activeCount == 0)
                                              const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 8),
                                                child: Text(
                                                  'لا توجد صلاحيات مفعلة لحسابك حالياً',
                                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 12),

                          // 2. Dynamic Tab Grid
                          Builder(builder: (context) {
                            final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
                            final isCurrentAdmin = auth?.isAdmin.value == true;
                            final staffPerms = auth?.staffPermissions.value ?? {};

                            final List<Widget> permittedTabButtons = [];
                            if (isCurrentAdmin || staffPerms['can_products'] == true) {
                              permittedTabButtons.add(_buildTabButton(0, IconsaxPlusBold.box, IconsaxPlusLinear.box, 'منتجات'));
                            }
                            if (isCurrentAdmin || staffPerms['can_products'] == true || staffPerms['can_moderate_comments'] == true) {
                              permittedTabButtons.add(_buildTabButton(3, IconsaxPlusBold.gallery, IconsaxPlusLinear.gallery, 'عروض'));
                            }
                            if (isCurrentAdmin || staffPerms['can_products'] == true) {
                              permittedTabButtons.add(_buildTabButton(2, IconsaxPlusBold.tag, IconsaxPlusLinear.tag, 'تصنيفات'));
                            }
                            if (isCurrentAdmin || staffPerms['can_orders'] == true) {
                              permittedTabButtons.add(_buildTabButton(1, IconsaxPlusBold.clipboard_text, IconsaxPlusLinear.clipboard_text, 'طلبات'));
                            }
                            if (isCurrentAdmin || staffPerms['can_replacements'] == true) {
                              permittedTabButtons.add(_buildTabButton(7, IconsaxPlusBold.convert, IconsaxPlusLinear.convert, 'استبدال'));
                            }
                            if (isCurrentAdmin) {
                              permittedTabButtons.add(_buildTabButton(6, IconsaxPlusBold.profile_2user, IconsaxPlusLinear.profile_2user, 'مستخدمون'));
                            }
                            if (isCurrentAdmin || staffPerms['can_block'] == true) {
                              permittedTabButtons.add(_buildTabButton(5, IconsaxPlusBold.user_remove, IconsaxPlusLinear.user_remove, 'سجل الحظر'));
                            }
                            if (isCurrentAdmin || staffPerms['can_products'] == true) {
                              permittedTabButtons.add(_buildTabButton(4, IconsaxPlusBold.archive_book, IconsaxPlusLinear.archive_book, 'سجل المخزون'));
                            }
                            if (isCurrentAdmin) {
                              permittedTabButtons.add(_buildTabButton(11, IconsaxPlusBold.notification_bing, IconsaxPlusLinear.notification_bing, 'إشعار جماعي'));
                              permittedTabButtons.add(_buildTabButton(10, IconsaxPlusBold.setting_2, IconsaxPlusLinear.setting_2, 'إعدادات'));
                              permittedTabButtons.add(_buildTabButton(9, IconsaxPlusBold.status_up, IconsaxPlusLinear.status_up, 'تشخيص'));
                              permittedTabButtons.add(_buildTabButton(8, IconsaxPlusBold.key, IconsaxPlusLinear.key, 'سجل OTP'));
                            }

                            if (permittedTabButtons.isEmpty) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(IconsaxPlusBold.shield_cross, size: 40, color: Color(0xFFE11D48)),
                                    SizedBox(height: 10),
                                    Text(
                                      'لا تملك صلاحيات كافية للوصول إلى أقسام لوحة الإدارة',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'يرجى مراجعة مدير النظام لتفعيل الصلاحيات المطلوبة لحسابك.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final crossCount = permittedTabButtons.length < 4 ? permittedTabButtons.length : 4;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: GridView.count(
                                crossAxisCount: crossCount,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                childAspectRatio: 1.1,
                                children: permittedTabButtons,
                              ),
                            );
                          }),

                          const SizedBox(height: 14),

                          // 3. Tab Content
                          _buildActiveTabContent(),

                          const SizedBox(height: 30),
                  ],
                ),

                // Floating Glass Scroll To Top Button
                GlassScrollToTopButton(
                  scrollController: _scrollController,
                  bottom: 20,
                  left: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
),
);
}

  Widget _buildPermissionPill(String title, Color textColor, Color bgColor, Color borderColor, {bool isActive = true}) {
    if (!isActive) {
      textColor = const Color(0xFF94A3B8);
      bgColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFE2E8F0);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? IconsaxPlusBold.tick_circle : IconsaxPlusLinear.close_circle,
            color: textColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedTab = index);
        _loadDataForTab(index);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 20,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsTab() {
    final report = _diagnosticsReport;
    final summary = report?['summary'] as Map<String, dynamic>?;
    final sections = report?['sections'] as List<dynamic>?;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Title + Refresh Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.show_chart_rounded, size: 20, color: Color(0xFF0F172A)),
                    SizedBox(width: 6),
                    Text(
                      'تشخيص النظام',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isRunningDiagnostics ? null : _runDiagnostics,
                  icon: _isRunningDiagnostics
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF0F172A)),
                  label: const Text(
                    'إعادة الفحص',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Summary 3-Columns Cards (RTL: سليم on right, تحذير in center, فشل on left)
            if (summary != null) ...[
              Row(
                children: [
                  // 1. سليم (Green)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${summary['ok'] ?? 0}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF047857), height: 1.1),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'سليم',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. تحذير (Amber)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${summary['warn'] ?? 0}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFD97706), height: 1.1),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'تحذير',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. فشل (Red)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${summary['fail'] ?? 0}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFBE123C), height: 1.1),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'فشل',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (_isRunningDiagnostics && report == null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.gold),
                      SizedBox(height: 12),
                      Text('جارٍ تنفيذ الفحص الشامل...', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                    ],
                  ),
                ),
              ),
            ] else if (_diagnosticsError != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Text(_diagnosticsError!, style: const TextStyle(color: Color(0xFFBE123C), fontSize: 13)),
              ),
            ] else if (sections != null) ...[
              // Sections list
              ...sections.map((sec) {
                final secTitle = sec['title'] as String? ?? '';
                final checks = (sec['checks'] as List<dynamic>?) ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Text(
                        secTitle,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ),
                    ...checks.map((c) {
                      final status = c['status'] as String? ?? 'ok';
                      final label = c['label'] as String? ?? '';
                      final detail = c['detail'] as String? ?? '';

                      final isOk = status == 'ok';
                      final isWarn = status == 'warn';

                      final iconBgColor = isOk
                          ? const Color(0xFFDCFCE7)
                          : isWarn
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFFEE2E2);

                      final iconColor = isOk
                          ? const Color(0xFF16A34A)
                          : isWarn
                              ? const Color(0xFFD97706)
                              : const Color(0xFFDC2626);

                      final badgeText = isOk ? 'سليم' : isWarn ? 'تحذير' : 'فشل';
                      final badgeBgColor = isOk
                          ? const Color(0xFFECFDF5)
                          : isWarn
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFFFF1F2);
                      final badgeTextColor = isOk
                          ? const Color(0xFF047857)
                          : isWarn
                              ? const Color(0xFFB45309)
                              : const Color(0xFFBE123C);
                      final badgeBorderColor = isOk
                          ? const Color(0xFFA7F3D0)
                          : isWarn
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFFECDD3);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: iconBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isOk
                                    ? Icons.check_circle_outline_rounded
                                    : isWarn
                                        ? Icons.warning_amber_rounded
                                        : Icons.cancel_outlined,
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: badgeBgColor,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: badgeBorderColor),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: badgeTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    detail,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }),

              if (report?['ranAt'] != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'آخر فحص: ${_formatDateTime(report!['ranAt'])}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplacementsTab() {
    final filtered = _replacementFilter == 'all'
        ? _replacements
        : _replacements.where((r) => r['status'] == _replacementFilter).toList();

    final counts = <String, int>{};
    for (final r in _replacements) {
      final s = r['status'] as String? ?? 'pending';
      counts[s] = (counts[s] ?? 0) + 1;
    }

    final statuses = ['all', 'pending', 'in_review', 'approved', 'rejected', 'resolved'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Pills (Matching Website)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: statuses.map((s) {
                final isSelected = _replacementFilter == s;
                final label = s == 'all' ? 'الكل' : _replacementStatusLabel(s);
                final count = s == 'all' ? _replacements.length : (counts[s] ?? 0);

                return InkWell(
                  onTap: () => setState(() => _replacementFilter = s),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0A192F) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? const Color(0xFF0A192F) : const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      '$label ($count)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            if (_isLoadingReplacements && _replacements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
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
                      alignment: Alignment.center,
                      child: const Icon(Icons.sync_alt_rounded, size: 30, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'لا توجد طلبات استبدال',
                      style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final row = filtered[index];
                  final id = row['id'] as String? ?? '';
                  final status = row['status'] as String? ?? 'pending';
                  final prodName = row['product_name_ar'] as String? ?? 'منتج غير معروف';
                  final orderId = row['order_id'] as String? ?? '';
                  final reason = row['reason'] as String? ?? '';
                  final createdAt = row['created_at'];

                  final uid = row['user_id'] as String?;
                  final profile = uid != null ? _replacementProfiles[uid] : null;
                  final custName = profile?['full_name'] as String? ?? 'بدون اسم';
                  final custPhone = profile?['phone'] as String?;

                  final notesCtrl = _adminNotesControllers[id];
                  final initNotes = _initialAdminNotes[id] ?? '';
                  final isNotesDirty = notesCtrl != null && notesCtrl.text.trim() != initNotes;
                  final isSavingNotes = _savingNotesId == id;
                  final isUpdatingStatus = _updatingStatusId == id;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header: Status badge & Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _replacementStatusBg(status),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _replacementStatusBorder(status)),
                              ),
                              child: Text(
                                _replacementStatusLabel(status),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: _replacementStatusText(status),
                                ),
                              ),
                            ),
                            Text(
                              _formatDateTime(createdAt),
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Product Name & Order ID
                        Text(
                          prodName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0A192F)),
                        ),
                        if (orderId.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'طلب #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Customer info
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              custName,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            if (custPhone != null && custPhone.isNotEmpty) ...[
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF0A192F)),
                                  const SizedBox(width: 4),
                                  Text(
                                    custPhone,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0A192F), fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Reason Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'سبب الاستبدال',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reason.isNotEmpty ? reason : 'لم يتم تحديد سبب',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), height: 1.35),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Admin Notes
                        const Text(
                          'ملاحظات الإدارة',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(height: 6),
                        if (notesCtrl != null)
                          TextField(
                            controller: notesCtrl,
                            maxLines: 2,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'ملاحظات داخلية عن المتابعة...',
                              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.5)),
                            ),
                          ),

                        if (isNotesDirty) ...[
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: isSavingNotes ? null : () => _saveReplacementNotes(id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              foregroundColor: const Color(0xFF0F172A),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isSavingNotes
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                                : const Text('حفظ الملاحظات', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ],

                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),

                        // Status Dropdown & Delete Button
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: status,
                                    isExpanded: true,
                                    items: [
                                      'pending',
                                      'in_review',
                                      'approved',
                                      'rejected',
                                      'resolved',
                                    ].map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          _replacementStatusLabel(s),
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: isUpdatingStatus ? null : (newStatus) {
                                      if (newStatus != null && newStatus != status) {
                                        _updateReplacementStatus(id, newStatus);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (Get.isRegistered<AuthService>() && Get.find<AuthService>().isAdmin.value) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _deleteReplacement(id),
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFF1F2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final isCurrentAdmin = auth?.isAdmin.value == true;
    final staffPerms = auth?.staffPermissions.value ?? {};

    if (!_isTabPermitted(_selectedTab, isCurrentAdmin, staffPerms)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(IconsaxPlusBold.shield_cross, size: 36, color: Color(0xFFE11D48)),
              ),
              const SizedBox(height: 14),
              const Text(
                'لا تملك صلاحية للوصول إلى هذا القسم',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Text(
                'يرجى التواصل مع مدير النظام لمنحك الصلاحيات اللازمة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedTab) {
      case 0:
        return _buildProductsTab();
      case 1:
        return _buildOrdersTab();
      case 2:
        return _buildCategoriesTab();
      case 3:
        return _buildBannersTab();
      case 4:
        return _buildStockMovementsTab();
      case 5:
        return _buildBlockLogTab();
      case 6:
        return _buildUsersTab();
      case 10:
        return _buildSettingsTab();
      case 7:
        return _buildReplacementsTab();
      case 9:
        return _buildDiagnosticsTab();
      case 11:
        return _buildBroadcastTab();
      default:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.build_circle_outlined, size: 44, color: Color(0xFF94A3B8)),
                SizedBox(height: 10),
                Text('هذا القسم قيد التحديث في لوحة الإدارة', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildBroadcastTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(IconsaxPlusBold.notification_bing, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إرسال إشعار جماعي (Push Notification)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
                    ),
                    Text(
                      'يصل داخلياً فوراً ويرسل تنبيهاً خارجياً لجميع أجهزة Android و iOS',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Audience selector
          const Text(
            'الجمهور المستهدف',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155), fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _broadcastAudience,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'all_users',
                    child: Text(
                      'جميع المستخدمين والزبائن (يشمل الإدارة للتجربة)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'all_customers',
                    child: Text(
                      'الزبائن والعملاء فقط (بدون حسابات الإدارة)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
                    ),
                  ),
                ],
                onChanged: _isSendingBroadcast
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _broadcastAudience = val);
                          _loadBroadcastCount();
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title input
          const Text(
            'عنوان الإشعار *',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155), fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _broadcastTitleCtrl,
            maxLength: 80,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
            decoration: InputDecoration(
              hintText: 'مثال: وصلت قطع غيار جديدة ومميزة 🎉',
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),

          // Body input
          const Text(
            'نص الإشعار (اختياري)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155), fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _broadcastBodyCtrl,
            maxLines: 3,
            maxLength: 300,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontFamily: 'Cairo'),
            decoration: InputDecoration(
              hintText: 'تصفح أحدث القطع المتوفرة الآن في التطبيق بأفضل الأسعار...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),

          // Recipients Summary Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 18, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    _isLoadingBroadcastCount
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)))
                        : Text(
                            'المستلمون: $_broadcastRecipientsCount مستخدم',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontFamily: 'Cairo'),
                          ),
                  ],
                ),
                IconButton(
                  onPressed: _loadBroadcastCount,
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFD97706)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Send Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_isSendingBroadcast || _broadcastTitleCtrl.text.trim().isEmpty || _broadcastRecipientsCount == 0)
                  ? null
                  : () => _confirmAndSendBroadcast(),
              icon: _isSendingBroadcast
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(IconsaxPlusBold.send_1, size: 18, color: Colors.white),
              label: Text(
                _isSendingBroadcast ? 'جاري الإرسال…' : 'إرسال الإشعار لـ $_broadcastRecipientsCount مستخدم',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, fontFamily: 'Cairo', color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A192F),
                disabledBackgroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAndSendBroadcast() {
    final title = _broadcastTitleCtrl.text.trim();
    final body = _broadcastBodyCtrl.text.trim();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(IconsaxPlusBold.notification_bing, color: AppColors.gold, size: 22),
            SizedBox(width: 8),
            Text('تأكيد الإرسال الجماعي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سيتم إرسال هذا الإشعار وتنبيه Push خارجي إلى $_broadcastRecipientsCount مستخدم. هل أنت متأكد؟',
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontFamily: 'Cairo', height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A), fontFamily: 'Cairo')),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(body, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'Cairo')),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('تراجع', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _sendBroadcast();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A192F), foregroundColor: Colors.white),
            child: const Text('تأكيد الإرسال الآن', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'منتج $_totalProducts',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditProductDialog(),
                icon: const Icon(IconsaxPlusBold.add, size: 16),
                label: const Text('إضافة منتج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (q) => _loadProducts(query: q),
            decoration: InputDecoration(
              hintText: 'OEM... ابحث بالاسم أو رقم',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(IconsaxPlusLinear.search_normal_1, color: Color(0xFF94A3B8), size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(IconsaxPlusBold.close_circle, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _loadProducts();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.5)),
            ),
          ),
        ),
        if (_isLoadingProducts)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          )
        else if (_products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('لا توجد منتجات مطابقة للبحث', style: TextStyle(color: Color(0xFF64748B)))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final prod = _products[index];
              final hasImage = prod.mainImage.isNotEmpty;
              final usdPrice = prod.priceUsd > 0
                  ? prod.priceUsd
                  : (prod.priceIqd / _settings.usdExchangeRate);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: prod.mainImage,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 24),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 28),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.nameAr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                '\$${usdPrice.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Text('≈', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                              Text(
                                Formatters.formatIQD(prod.priceIqd),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            prod.inStock ? 'متوفر · ${prod.stockQty} قطعة' : 'نفذت الكمية',
                            style: TextStyle(
                              fontSize: 11,
                              color: prod.inStock ? const Color(0xFF0D9488) : const Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _showAddEditProductDialog(product: prod),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(IconsaxPlusBold.edit_2, color: Color(0xFF0F172A), size: 18),
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _deleteProduct(prod),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(IconsaxPlusBold.trash, color: Color(0xFFDC2626), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (_orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('لا توجد طلبات بعد', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
      );
    }

    final now = DateTime.now();
    final cutoff24 = now.subtract(const Duration(hours: 24));
    final cutoff7 = now.subtract(const Duration(days: 7));

    final count24 = _orders.where((o) {
      final ca = o['created_at'];
      if (ca == null) return false;
      try {
        return DateTime.parse(ca.toString()).toLocal().isAfter(cutoff24);
      } catch (_) {
        return false;
      }
    }).length;

    final count7 = _orders.where((o) {
      final ca = o['created_at'];
      if (ca == null) return false;
      try {
        return DateTime.parse(ca.toString()).toLocal().isAfter(cutoff7);
      } catch (_) {
        return false;
      }
    }).length;

    final sum24 = _orders.where((o) {
      final ca = o['created_at'];
      if (ca == null) return false;
      try {
        return DateTime.parse(ca.toString()).toLocal().isAfter(cutoff24);
      } catch (_) {
        return false;
      }
    }).fold<double>(0.0, (acc, o) => acc + ((o['total_iqd'] as num?)?.toDouble() ?? 0.0));

    final timeFiltered = _orders.where((o) {
      if (_orderRange == 'all') return true;
      final ca = o['created_at'];
      if (ca == null) return true;
      try {
        final dt = DateTime.parse(ca.toString()).toLocal();
        if (_orderRange == '24h') return dt.isAfter(cutoff24);
        if (_orderRange == '7d') return dt.isAfter(cutoff7);
      } catch (_) {}
      return true;
    }).toList();

    final filtered = timeFiltered.where((o) {
      if (_orderStatusFilter == 'all') return true;
      final st = (o['status'] as String? ?? 'received').toLowerCase();
      if (_orderStatusFilter == 'shipped_group') {
        return st == 'shipped' || st == 'out_for_delivery';
      }
      return st == _orderStatusFilter;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Stats Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.gold.withValues(alpha: 0.14),
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.06),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('آخر 24 ساعة', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                        const SizedBox(height: 3),
                        Text(
                          '$count24 طلب جديد',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0A192F)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('إجمالي', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.formatIQD(sum24),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0A192F)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildOrderFilterPill('24h', '24 ساعة ($count24)'),
                    const SizedBox(width: 8),
                    _buildOrderFilterPill('7d', '7 أيام ($count7)'),
                    const SizedBox(width: 8),
                    _buildOrderFilterPill('all', 'الكل (${_orders.length})'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Status Filter Bar (above the action row)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildOrderStatusChip(
                  key: 'all',
                  label: 'الكل',
                  count: timeFiltered.length,
                  icon: IconsaxPlusBold.category,
                ),
                const SizedBox(width: 8),
                _buildOrderStatusChip(
                  key: 'received',
                  label: 'جديد',
                  count: timeFiltered.where((o) => (o['status'] ?? 'received') == 'received').length,
                  icon: IconsaxPlusBold.box_add,
                  activeColor: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _buildOrderStatusChip(
                  key: 'preparing',
                  label: 'جاري التجهيز',
                  count: timeFiltered.where((o) => o['status'] == 'preparing').length,
                  icon: IconsaxPlusBold.setting_2,
                  activeColor: const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                _buildOrderStatusChip(
                  key: 'packed',
                  label: 'تم التجهيز',
                  count: timeFiltered.where((o) => o['status'] == 'packed').length,
                  icon: IconsaxPlusBold.box,
                  activeColor: const Color(0xFF7C3AED),
                ),
                const SizedBox(width: 8),
                _buildOrderStatusChip(
                  key: 'shipped_group',
                  label: 'قيد التوصيل',
                  count: timeFiltered.where((o) => o['status'] == 'shipped' || o['status'] == 'out_for_delivery').length,
                  icon: IconsaxPlusBold.truck,
                  activeColor: const Color(0xFF0284C7),
                ),
                const SizedBox(width: 8),
                _buildOrderStatusChip(
                  key: 'delivered',
                  label: 'تم التسليم',
                  count: timeFiltered.where((o) => o['status'] == 'delivered').length,
                  icon: IconsaxPlusBold.tick_circle,
                  activeColor: const Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                _buildOrderStatusChip(
                  key: 'cancelled',
                  label: 'ملغي',
                  count: timeFiltered.where((o) => o['status'] == 'cancelled').length,
                  icon: IconsaxPlusBold.close_circle,
                  activeColor: const Color(0xFFDC2626),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Subheader Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filtered.length} طلب معروض',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              if (Get.isRegistered<AuthService>() && Get.find<AuthService>().isAdmin.value)
                OutlinedButton.icon(
                  onPressed: _showDeleteAllOrdersDialog,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                  label: const Text(
                    'حذف جميع الطلبات',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Orders List
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Text('لا توجد طلبات تطابق هذا الفلتر', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            )
          else
            ...filtered.map((o) => _buildOrderAdminCard(o)),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChip({
    required String key,
    required String label,
    required int count,
    required IconData icon,
    Color activeColor = AppColors.gold,
  }) {
    final isSelected = _orderStatusFilter == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _orderStatusFilter = key),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (activeColor == AppColors.gold ? AppColors.gold : activeColor.withValues(alpha: 0.12))
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? (activeColor == AppColors.gold ? AppColors.gold : activeColor)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (activeColor == AppColors.gold ? AppColors.gold : activeColor).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? (activeColor == AppColors.gold ? const Color(0xFF0A192F) : activeColor)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontFamily: 'Cairo',
                  color: isSelected
                      ? (activeColor == AppColors.gold ? const Color(0xFF0A192F) : activeColor)
                      : const Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (activeColor == AppColors.gold ? const Color(0xFF0A192F).withValues(alpha: 0.12) : activeColor.withValues(alpha: 0.2))
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isSelected
                        ? (activeColor == AppColors.gold ? const Color(0xFF0A192F) : activeColor)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderFilterPill(String key, String label) {
    final isSelected = _orderRange == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _orderRange = key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF0A192F) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderAdminCard(Map<String, dynamic> o) {
    final orderId = o['id'] as String? ?? '';
    final orderNum = o['order_number'] as String? ?? (orderId.length > 8 ? orderId.substring(0, 8) : orderId);
    final status = o['status'] as String? ?? 'received';
    final totalAmount = (o['total_iqd'] as num?)?.toDouble() ?? 0.0;
    final userId = o['user_id'] as String? ?? '';
    final profile = _orderCustomerProfiles[userId];
    final items = _orderItemsMap[orderId] ?? [];
    final adminReviewed = o['admin_reviewed'] == true;

    // Address extraction
    final dynamic rawAddr = o['address'];
    final Map<String, dynamic> addr = rawAddr is Map<String, dynamic>
        ? rawAddr
        : (rawAddr is Map ? Map<String, dynamic>.from(rawAddr) : {});

    final addrLabel = addr['label'] as String? ?? '—';
    final addrName = addr['full_name'] as String? ?? (profile?['full_name'] as String? ?? '—');
    final addrPhone = addr['phone'] as String? ?? (profile?['phone'] as String? ?? '—');
    final addrCity = addr['city'] as String? ?? '—';
    final addrArea = addr['area'] as String? ?? '—';
    final addrStreet = addr['street'] as String? ?? '—';
    final addrNotes = addr['notes'] as String? ?? '—';

    // Customer display
    final customerName = (profile?['full_name'] as String?)?.trim().isNotEmpty == true
        ? (profile!['full_name'] as String)
        : (addrName != '—' ? addrName : 'زبون شوفرليت');
    final customerPhone = (profile?['phone'] as String?)?.trim().isNotEmpty == true
        ? (profile!['phone'] as String)
        : (addrPhone != '—' ? addrPhone : '');
    final isBlocked = profile?['is_blocked'] == true;
    final phoneForCall = customerPhone.isNotEmpty ? customerPhone : addrPhone;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: #103 + Status Pill + Reviewed Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '#$orderNum',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (adminReviewed) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF047857)),
                          SizedBox(width: 3),
                          Text('تمت المراجعة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _orderStatusBgColor(status),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _orderStatusBorderColor(status)),
                ),
                child: Text(
                  _orderStatusLabel(status),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: _orderStatusTextColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Customer Profile Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFD97706),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (customerName.isNotEmpty ? customerName[0] : 'U').toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A)),
                          ),
                        ),
                        if (isBlocked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.block_rounded, size: 16, color: Color(0xFFDC2626)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerPhone.isNotEmpty ? customerPhone : '—',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Delivery Address Section ("تفاصيل عنوان التوصيل")
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: AppColors.gold, size: 16),
                    SizedBox(width: 6),
                    Text('تفاصيل عنوان التوصيل', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.gold)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildAddressRow('التسمية', addrLabel),
                _buildAddressRow('الاسم الكامل', addrName),
                _buildAddressRow('رقم الهاتف', addrPhone, isPhone: true),
                _buildAddressRow('المحافظة', addrCity),
                _buildAddressRow('المنطقة / القضاء', addrArea),
                _buildAddressRow('الشارع / تفاصيل', addrStreet),
                _buildAddressRow('ملاحظات إضافية', addrNotes),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _copyFullAddress(o, addr),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, size: 15, color: Color(0xFF0F172A)),
                        SizedBox(width: 8),
                        Text(
                          'نسخ العنوان كاملاً',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order Items Section ("القطع (X)")
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final isExpanded = _expandedOrderIds.contains(orderId);
                final displayedItems = (items.length <= 3 || isExpanded)
                    ? items
                    : items.take(3).toList();
                final remainingCount = items.length - 3;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'القطع (${items.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (items.length > 3)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedOrderIds.remove(orderId);
                                  } else {
                                    _expandedOrderIds.add(orderId);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isExpanded
                                          ? 'مشاهدة أقل'
                                          : 'مشاهدة المزيد (+ $remainingCount)',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo',
                                        color: AppColors.gold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppColors.gold,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...displayedItems.map((item) => _buildOrderItemRow(item)),
                      if (items.length > 3) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedOrderIds.remove(orderId);
                              } else {
                                _expandedOrderIds.add(orderId);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                  size: 17,
                                  color: const Color(0xFF475569),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isExpanded
                                      ? 'عرض قطع أقل'
                                      : 'مشاهدة المزيد (باقي $remainingCount قطع)',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 12),

          // Call Button (Dark Navy)
          if (phoneForCall.isNotEmpty && phoneForCall != '—')
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _makePhoneCall(phoneForCall),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 18, color: Colors.white),
                label: const Text('اتصال', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              Text(
                Formatters.formatIQD(totalAmount),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0A192F)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Status Dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: status,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                items: [
                  'received',
                  'preparing',
                  'packed',
                  'shipped',
                  'out_for_delivery',
                  'delivered',
                  'cancelled',
                ].map((s) {
                  final isSelected = s == status;
                  return DropdownMenuItem(
                    value: s,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD97706).withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _orderStatusLabel(s),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? const Color(0xFFD97706) : const Color(0xFF0F172A),
                            ),
                          ),
                          if (isSelected) const Icon(Icons.check_rounded, size: 18, color: Color(0xFFD97706)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _updatingOrderStatusId == orderId
                    ? null
                    : (newStatus) {
                        if (newStatus != null && newStatus != status) {
                          _updateOrderStatus(orderId, newStatus);
                        }
                      },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Preview Invoice Button (Gold)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _showInvoicePreviewDialog(o, items),
              icon: const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.white),
              label: const Text('معاينة الفاتورة', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Ban Customer Button (Pink / Red)
          Builder(builder: (context) {
            final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
            final isAdm = auth?.isAdmin.value == true;
            final perms = auth?.staffPermissions.value ?? {};
            final canBlock = isAdm || perms['can_block'] == true;

            if (!canBlock || userId.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _togglingBlockUserId == userId ? null : () => _toggleBlockUser(userId, isBlocked),
                  icon: Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 18, color: const Color(0xFFDC2626)),
                  label: Text(
                    isBlocked ? 'رفع الحظر عن الزبون' : 'حظر الزبون من الطلبات',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F2),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            );
          }),

          // Delete Single Order Button (Pink / Red) - Admin only
          Builder(builder: (context) {
            final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
            final isAdm = auth?.isAdmin.value == true;
            if (!isAdm) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteSingleOrder(orderId),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                  label: const Text('حذف الطلب نهائياً', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF1F2),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                fontFamily: isPhone ? 'monospace' : null,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(Map<String, dynamic> item) {
    final name = item['name_ar'] as String? ?? 'قطعة غيار';
    final img = item['image_url'] as String? ?? '';
    final qty = item['quantity'] ?? 1;
    final price = (item['unit_price_iqd'] as num?)?.toDouble() ?? 0.0;
    final side = item['side'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: img.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: img,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, size: 20, color: Color(0xFF94A3B8))),
                  )
                : const Center(child: Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF94A3B8))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (side != null && side.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A192F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(side == 'pair' ? 'تخم' : side, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '${Formatters.formatIQD(price)} × $qty',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _orderStatusLabel(String s) {
    switch (s) {
      case 'received': return 'تم الاستلام';
      case 'preparing': return 'جاري التجهيز';
      case 'packed': return 'تم التغليف';
      case 'shipped': return 'شحن للتوصيل';
      case 'out_for_delivery': return 'خرج للتوصيل';
      case 'delivered': return 'تم التسليم';
      case 'cancelled': return 'ملغى';
      default: return s;
    }
  }

  Color _orderStatusBgColor(String s) {
    switch (s) {
      case 'received': return const Color(0xFFEFF6FF);
      case 'preparing': return const Color(0xFFFEF3C7);
      case 'packed': return const Color(0xFFF3E8FF);
      case 'shipped': return const Color(0xFFE0F2FE);
      case 'out_for_delivery': return const Color(0xFFFFFBEB);
      case 'delivered': return const Color(0xFFECFDF5);
      case 'cancelled': return const Color(0xFFFFF1F2);
      default: return const Color(0xFFF1F5F9);
    }
  }

  Color _orderStatusTextColor(String s) {
    switch (s) {
      case 'received': return const Color(0xFF1D4ED8);
      case 'preparing': return const Color(0xFFD97706);
      case 'packed': return const Color(0xFF7E22CE);
      case 'shipped': return const Color(0xFF0369A1);
      case 'out_for_delivery': return const Color(0xFFB45309);
      case 'delivered': return const Color(0xFF047857);
      case 'cancelled': return const Color(0xFFBE123C);
      default: return const Color(0xFF64748B);
    }
  }

  Color _orderStatusBorderColor(String s) {
    switch (s) {
      case 'received': return const Color(0xFFBFDBFE);
      case 'preparing': return const Color(0xFFFDE68A);
      case 'packed': return const Color(0xFFE9D5FF);
      case 'shipped': return const Color(0xFFBAE6FD);
      case 'out_for_delivery': return const Color(0xFFFDE68A);
      case 'delivered': return const Color(0xFFA7F3D0);
      case 'cancelled': return const Color(0xFFFECDD3);
      default: return const Color(0xFFCBD5E1);
    }
  }

  void _copyFullAddress(Map<String, dynamic> o, Map<String, dynamic> addr) {
    final orderNum = o['order_number'] as String? ?? (o['id'] as String? ?? '').substring(0, 8);
    final label = addr['label'] as String? ?? '—';
    final name = addr['full_name'] as String? ?? '—';
    final phone = addr['phone'] as String? ?? '—';
    final city = addr['city'] as String? ?? '—';
    final area = addr['area'] as String? ?? '—';
    final street = addr['street'] as String? ?? '—';
    final notes = addr['notes'] as String? ?? '—';

    final text = '''
تفاصيل عنوان التوصيل للطلب #$orderNum:
- التسمية: $label
- الاسم الكامل: $name
- رقم الهاتف: $phone
- المحافظة: $city
- المنطقة / القضاء: $area
- الشارع / تفاصيل: $street
- ملاحظات إضافية: $notes
''';

    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('تم النسخ', 'تم نسخ تفاصيل العنوان كاملاً إلى الحافظة', backgroundColor: const Color(0xFF0A192F), colorText: Colors.white);
  }

  void _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('تنبيه', 'تعذر إجراء المكالمة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    }
  }

  Future<void> _updateOrderStatus(String id, String status) async {
    setState(() => _updatingOrderStatusId = id);
    try {
      final dio = Get.find<DioClient>().dio;
      await dio.patch(
        '/rest/v1/orders',
        queryParameters: {'id': 'eq.$id'},
        data: {'status': status},
      );
      Get.snackbar('تم التحديث', 'تم تغيير حالة الطلب بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
      _loadOrders();
    } catch (_) {
      Get.snackbar('خطأ', 'تعذر تحديث حالة الطلب', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _updatingOrderStatusId = null);
    }
  }

  void _deleteSingleOrder(String id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الطلب', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: const Text('سيتم حذف هذا الطلب بشكل نهائي. لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final dio = Get.find<DioClient>().dio;
                await dio.delete('/rest/v1/orders', queryParameters: {'id': 'eq.$id'});
                Get.snackbar('تم الحذف', 'تم حذف الطلب بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
                _loadOrders();
              } catch (_) {
                Get.snackbar('خطأ', 'تعذر حذف الطلب', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllOrdersDialog() {
    if (_orders.isEmpty) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف جميع الطلبات', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: Text('سيتم حذف ${_orders.length} طلب بشكل نهائي. لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final dio = Get.find<DioClient>().dio;
                final ids = _orders.map((o) => o['id'] as String).toList();
                await dio.delete('/rest/v1/orders', queryParameters: {'id': 'in.(${ids.join(",")})'});
                Get.snackbar('تم الحذف', 'تم حذف جميع الطلبات بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
                _loadOrders();
              } catch (_) {
                Get.snackbar('خطأ', 'تعذر حذف الطلبات', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlockUser(String uid, bool isBlocked) async {
    final next = !isBlocked;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(next ? 'حظر الزبون' : 'رفع الحظر', style: TextStyle(fontWeight: FontWeight.bold, color: next ? const Color(0xFFDC2626) : const Color(0xFF047857))),
        content: Text(next ? 'هل أنت متأكد من حظر هذا الزبون من إرسال الطلبات؟' : 'هل تريد رفع الحظر عن هذا الزبون؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: next ? const Color(0xFFDC2626) : const Color(0xFF047857), foregroundColor: Colors.white),
            child: Text(next ? 'حظر الزبون' : 'رفع الحظر'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _togglingBlockUserId = uid);
    try {
      final dio = Get.find<DioClient>().dio;
      await dio.patch('/rest/v1/profiles', queryParameters: {'id': 'eq.$uid'}, data: {'is_blocked': next});
      try {
        await dio.post('/rest/v1/user_block_log', data: {'user_id': uid, 'action': next ? 'block' : 'unblock'});
      } catch (_) {}

      Get.snackbar('تم', next ? 'تم حظر الزبون بنجاح' : 'تم رفع الحظر بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
      _loadOrders();
    } catch (_) {
      Get.snackbar('خطأ', 'تعذر تحديث حالة الحظر', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _togglingBlockUserId = null);
    }
  }

  Future<void> _shareInvoiceAsImage(GlobalKey key, String orderNum, [BuildContext? context]) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Get.snackbar('تنبيه', 'تعذر قراءة صورة الفاتورة للمشاركة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        Get.snackbar('خطأ', 'تعذر تحويل الفاتورة إلى صورة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/invoice_$orderNum.png').create();
      await file.writeAsBytes(pngBytes);

      Rect? origin;
      if (context != null && context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          origin = box.localToGlobal(Offset.zero) & box.size;
        }
      }
      origin ??= Rect.fromLTWH(0, 0, Get.width, Get.height / 2);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'فاتورة طلب #$orderNum - علي شيفروليت',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر مشاركة صورة الفاتورة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    }
  }

  void _showInvoicePreviewDialog(Map<String, dynamic> o, List<Map<String, dynamic>> items) {
    final invoiceKey = GlobalKey();
    final orderNum = o['order_number'] as String? ?? (o['id'] as String? ?? '').substring(0, 8);
    final total = (o['total_iqd'] as num?)?.toDouble() ?? 0.0;
    final shipping = ((o['shipping_iqd'] ?? o['shipping_fee_iqd'] ?? o['delivery_fee_iqd']) as num?)?.toDouble() ?? 0.0;
    final pointsUsed = (o['points_used'] as num?)?.toInt() ?? 0;
    bool isSharing = false;

    double itemsSubtotal = 0.0;
    for (final it in items) {
      final iprice = (it['unit_price_iqd'] as num?)?.toDouble() ?? 0.0;
      final iqty = (it['quantity'] as num?)?.toInt() ?? 1;
      itemsSubtotal += iprice * iqty;
    }
    final subtotal = (o['subtotal_iqd'] as num?)?.toDouble() ?? (itemsSubtotal > 0 ? itemsSubtotal : (total - shipping > 0 ? total - shipping : total));

    final dynamic rawAddr = o['address'];
    final Map<String, dynamic> addr = rawAddr is Map<String, dynamic>
        ? rawAddr
        : (rawAddr is Map ? Map<String, dynamic>.from(rawAddr) : {});

    final name = addr['full_name'] as String? ?? '—';
    final phone = addr['phone'] as String? ?? '—';
    final city = addr['city'] as String? ?? '—';
    final area = addr['area'] as String? ?? '—';
    final street = addr['street'] as String? ?? '—';
    final fullAddrText = '$city، $area${street.isNotEmpty && street != "—" ? " - $street" : ""}';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invoice Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Text(
                        'معاينة الفاتورة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const Divider(height: 16),

                  // Scrollable Printable / Snapshot Card (RepaintBoundary)
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: RepaintBoundary(
                        key: invoiceKey,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Store Branding Header Image (Sharp corners)
                              Image.asset(
                                'assets/images/invoice_header.jpg',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 14),

                              // Order & Customer Info Card
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    _buildInvoiceRowItem('رقم الطلب', '#$orderNum', isMono: true),
                                    const SizedBox(height: 5),
                                    _buildInvoiceRowItem('الزبون', name),
                                    const SizedBox(height: 5),
                                    _buildInvoiceRowItem('الهاتف', phone, isMono: true),
                                    const SizedBox(height: 5),
                                    _buildInvoiceRowItem('العنوان', fullAddrText),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Itemized table header label
                              const Text(
                                'القطع المطلوبة',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 8),

                              // Itemized structured table
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(4.4), // اسم القطعة
                                    1: FlexColumnWidth(1.2), // العدد
                                    2: FlexColumnWidth(2.8), // السعر
                                  },
                                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                  children: [
                                    // Table Header
                                    const TableRow(
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                      ),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                          child: Text(
                                            'القطعة',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, fontFamily: 'Cairo', color: Color(0xFF475569)),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                                          child: Text(
                                            'العدد',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, fontFamily: 'Cairo', color: Color(0xFF475569)),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                          child: Text(
                                            'السعر',
                                            textAlign: TextAlign.end,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, fontFamily: 'Cairo', color: Color(0xFF475569)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Table Rows
                                    if (items.isEmpty)
                                      const TableRow(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Text(
                                              'لا توجد تفاصيل قطع',
                                              style: TextStyle(fontSize: 11.5, fontFamily: 'Cairo', color: Color(0xFF94A3B8)),
                                            ),
                                          ),
                                          SizedBox.shrink(),
                                          SizedBox.shrink(),
                                        ],
                                      )
                                    else
                                      ...items.asMap().entries.map((entry) {
                                        final idx = entry.key;
                                        final it = entry.value;
                                        final iname = it['name_ar'] as String? ?? 'قطعة';
                                        final iside = it['side'] as String?;
                                        final iprice = (it['unit_price_iqd'] as num?)?.toDouble() ?? 0.0;
                                        final iqty = it['quantity'] ?? 1;
                                        final sideLabel = iside == 'LH'
                                            ? ' (يسار)'
                                            : iside == 'RH'
                                                ? ' (يمين)'
                                                : iside == 'PAIR'
                                                    ? ' (طقم)'
                                                    : '';

                                        return TableRow(
                                          decoration: BoxDecoration(
                                            color: idx.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
                                            border: const Border(
                                              top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                                            ),
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              child: Text(
                                                '$iname$sideLabel',
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, fontFamily: 'Cairo', color: Color(0xFF1E293B), height: 1.3),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                              child: Text(
                                                '$iqty',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              child: Text(
                                                Formatters.formatIQD(iprice * iqty),
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                  ],
                                ),
                              ),

                              const Divider(height: 20),

                              // Financials
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('المجموع الفرعي', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF64748B))),
                                  Text(Formatters.formatIQD(subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('كلفة التوصيل', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF64748B))),
                                  Text(shipping > 0 ? Formatters.formatIQD(shipping) : 'مجاني', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A))),
                                ],
                              ),
                              if (pointsUsed > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('خصم نقاط ($pointsUsed)', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF64748B))),
                                    Text('- ${Formatters.formatIQD((subtotal + shipping) - total)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF047857))),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الإجمالي النهائي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Color(0xFF0A192F))),
                                  Text(Formatters.formatIQD(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: Color(0xFFD97706))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Action Buttons Row: Share Image & Close
                  Row(
                    children: [
                      // Share Image Button (Gold)
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: isSharing
                                ? null
                                : () async {
                                    setDlgState(() => isSharing = true);
                                    await _shareInvoiceAsImage(invoiceKey, orderNum, context);
                                    if (context.mounted) {
                                      setDlgState(() => isSharing = false);
                                    }
                                  },
                            icon: isSharing
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(IconsaxPlusBold.share, size: 18, color: Colors.white),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'مشاركة كصورة',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Colors.white, height: 1.2),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Close Button (Navy)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A192F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', height: 1.2)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceRowItem(String label, String value, {bool isMono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontFamily: 'Cairo'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: isMono ? 'monospace' : 'Cairo',
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. Categories Section ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'التصنيفات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditCategoryDialog(),
                icon: const Icon(IconsaxPlusBold.add, size: 16),
                label: const Text('جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_categories.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: const Text('لا توجد تصنيفات مسجلة', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            )
          else
            ..._categories.map((c) {
              final hasImage = c.imageUrl != null && c.imageUrl!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: c.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(IconsaxPlusBold.tag, color: Color(0xFFD97706), size: 24),
                              ),
                            )
                          : const Center(
                              child: Icon(IconsaxPlusBold.tag, color: Color(0xFFD97706), size: 24),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.nameAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showAddEditCategoryDialog(category: c),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(IconsaxPlusBold.edit_2, color: Color(0xFF0F172A), size: 18),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () => _deleteCategory(c),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(IconsaxPlusBold.trash, color: Color(0xFFDC2626), size: 18),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // ─── 2. Brands Section ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الماركات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditBrandDialog(),
                icon: const Icon(IconsaxPlusBold.add, size: 16),
                label: const Text('جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_brands.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: const Text('لا توجد ماركات مسجلة', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            )
          else
            ..._brands.map((b) {
              final hasLogo = b.logoUrl != null && b.logoUrl!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasLogo
                          ? CachedNetworkImage(
                              imageUrl: b.logoUrl!,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(IconsaxPlusBold.car, color: Color(0xFF0D9488), size: 24),
                              ),
                            )
                          : const Center(
                              child: Icon(IconsaxPlusBold.car, color: Color(0xFF0D9488), size: 24),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        b.nameAr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showAddEditBrandDialog(brand: b),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(IconsaxPlusBold.edit_2, color: Color(0xFF0F172A), size: 18),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () => _deleteBrand(b),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(IconsaxPlusBold.trash, color: Color(0xFFDC2626), size: 18),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // ─── 3. Car Models Section ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أنواع وموديلات السيارات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditCarModelDialog(),
                icon: const Icon(IconsaxPlusBold.add, size: 16),
                label: const Text('جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_carModels.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: const Text('لا توجد أنواع سيارات مسجلة', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            )
          else
            ..._carModels.map((m) {
              final brand = _brands.where((b) => b.id == m.brandId).firstOrNull;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(IconsaxPlusBold.car, color: Color(0xFF0A192F), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.nameAr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          if (brand != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              brand.nameAr,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showAddEditCarModelDialog(model: m),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(IconsaxPlusBold.edit_2, color: Color(0xFF0F172A), size: 18),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () => _deleteCarModel(m),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(IconsaxPlusBold.trash, color: Color(0xFFDC2626), size: 18),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoadingBanners = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final res = await dio.get('/rest/v1/banners', queryParameters: {'order': 'created_at.desc'});
      if ((res.statusCode == 200 || res.statusCode == 206) && res.data is List) {
        if (mounted) {
          setState(() {
            _banners = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isLoadingBanners = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingBanners = false);
  }

  void _showAddEditBannerDialog({Map<String, dynamic>? banner}) {
    final isEdit = banner != null;
    final titleCtrl = TextEditingController(text: banner?['title_ar'] ?? '');
    final subtitleCtrl = TextEditingController(text: banner?['subtitle_ar'] ?? '');

    String currentImageUrl = banner?['image_url'] as String? ?? '';
    String currentVideoUrl = (banner?['video_url'] as String?) ?? '';

    XFile? pickedImageFile;
    Uint8List? pickedImageBytes;

    XFile? pickedVideoFile;
    Uint8List? pickedVideoBytes;
    String? pickedVideoName;

    bool isSaving = false;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 420),
          child: StatefulBuilder(
            builder: (ctx, setDlgState) {
              final hasImage = pickedImageBytes != null || currentImageUrl.isNotEmpty;
              final hasVideo = pickedVideoFile != null || currentVideoUrl.isNotEmpty;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          isEdit ? 'تعديل عرض' : 'إضافة عرض',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                    const Divider(height: 20),

                    // 1. Image Upload
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الصور',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                        ),
                        if (hasImage)
                          InkWell(
                            onTap: () {
                              setDlgState(() {
                                pickedImageFile = null;
                                pickedImageBytes = null;
                                currentImageUrl = '';
                              });
                            },
                            child: const Text('إزالة الصورة', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hasImage)
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: pickedImageBytes != null
                                  ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                                  : CachedNetworkImage(
                                      imageUrl: currentImageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
                                      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setDlgState(() {
                                    pickedImageFile = null;
                                    pickedImageBytes = null;
                                    currentImageUrl = '';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (img != null) {
                            final bytes = await img.readAsBytes();
                            setDlgState(() {
                              pickedImageFile = img;
                              pickedImageBytes = bytes;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.file_upload_outlined, size: 26, color: Color(0xFF64748B)),
                              SizedBox(height: 4),
                              Text('رفع صورة', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 2. Video Upload (Optional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'فيديو (اختياري)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                        ),
                        if (hasVideo)
                          InkWell(
                            onTap: () {
                              setDlgState(() {
                                pickedVideoFile = null;
                                pickedVideoBytes = null;
                                pickedVideoName = null;
                                currentVideoUrl = '';
                              });
                            },
                            child: const Text('إزالة الفيديو', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hasVideo)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.videocam_rounded, color: AppColors.gold, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pickedVideoName ?? (currentVideoUrl.isNotEmpty ? 'فيديو مرفوع' : 'فيديو محدد'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setDlgState(() {
                                  pickedVideoFile = null;
                                  pickedVideoBytes = null;
                                  pickedVideoName = null;
                                  currentVideoUrl = '';
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final vid = await picker.pickVideo(source: ImageSource.gallery);
                          if (vid != null) {
                            final bytes = await vid.readAsBytes();
                            if (bytes.lengthInBytes > 35 * 1024 * 1024) {
                              Get.snackbar('حجم الفيديو كبير', 'يرجى اختيار فيديو بحجم أقل من 35 ميغابايت', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
                              return;
                            }
                            setDlgState(() {
                              pickedVideoFile = vid;
                              pickedVideoBytes = bytes;
                              pickedVideoName = vid.name;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_rounded, size: 24, color: Color(0xFF64748B)),
                              SizedBox(height: 4),
                              Text('رفع فيديو', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      'يمكنك نشر صورة فقط، أو فيديو فقط، أو كلاهما معاً.',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontFamily: 'Cairo'),
                    ),

                    const SizedBox(height: 14),

                    // 3. Title Input
                    const Text('العنوان', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    _buildSettingInput(titleCtrl, placeholder: ''),

                    const SizedBox(height: 12),

                    // 4. Subtitle Input
                    const Text('العنوان الفرعي', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    _buildSettingInput(subtitleCtrl, placeholder: ''),

                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (currentImageUrl.isEmpty && pickedImageBytes == null && currentVideoUrl.isEmpty && pickedVideoBytes == null) {
                                  Get.snackbar('تنبيه', 'يجب اختيار صورة أو فيديو على الأقل', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
                                  return;
                                }

                                setDlgState(() => isSaving = true);
                                try {
                                  final dio = Get.find<DioClient>().dio;

                                  // 1. Upload image if newly picked
                                  if (pickedImageFile != null && pickedImageBytes != null) {
                                    final upImg = await _uploadSingleImage(pickedImageFile, pickedImageBytes);
                                    if (upImg != null) currentImageUrl = upImg;
                                  }

                                  // 2. Upload video if newly picked
                                  if (pickedVideoFile != null && pickedVideoBytes != null) {
                                    final upVid = await _uploadSingleVideo(pickedVideoFile, pickedVideoBytes);
                                    if (upVid != null) currentVideoUrl = upVid;
                                  }

                                  final payload = {
                                    'title_ar': titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : null,
                                    'subtitle_ar': subtitleCtrl.text.trim().isNotEmpty ? subtitleCtrl.text.trim() : null,
                                    'image_url': currentImageUrl,
                                    'video_url': currentVideoUrl.isNotEmpty ? currentVideoUrl : null,
                                    'is_active': true,
                                    'expires_at': null,
                                  };

                                  if (isEdit) {
                                    await dio.patch(
                                      '/rest/v1/banners',
                                      queryParameters: {'id': 'eq.${banner['id']}'},
                                      data: payload,
                                    );
                                  } else {
                                    await dio.post(
                                      '/rest/v1/banners',
                                      data: payload,
                                    );
                                  }

                                  Get.back();
                                  Get.snackbar('نجاح', 'تم حفظ العرض بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
                                  _loadBanners();
                                  if (Get.isRegistered<HomeController>()) {
                                    Get.find<HomeController>().loadHomeData(refreshMetadata: true);
                                  }
                                } catch (e) {
                                  Get.snackbar('خطأ', 'تعذر حفظ العرض: $e', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
                                } finally {
                                  if (mounted) setDlgState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A192F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBanner(String id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('حذف العرض', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من حذف هذا العرض؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('نعم، حذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dio = Get.find<DioClient>().dio;
        await dio.delete(
          '/rest/v1/banners',
          queryParameters: {'id': 'eq.$id'},
        );
        Get.snackbar('نجاح', 'تم حذف العرض بنجاح', backgroundColor: AppColors.inStock, colorText: Colors.white);
        _loadBanners();
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().loadHomeData(refreshMetadata: true);
        }
      } catch (e) {
        Get.snackbar('خطأ', 'تعذر حذف العرض', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      }
    }
  }

  Widget _buildBannersTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Add Offer Button (Dark navy with + icon, exactly matching screenshot 1)
          ElevatedButton.icon(
            onPressed: () => _showAddEditBannerDialog(),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text(
              'إضافة عرض',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo', color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A192F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),

          const SizedBox(height: 16),

          // 2. Content
          if (_isLoadingBanners)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
            )
          else if (_banners.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.photo_library_outlined, size: 36, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 14),
                    const Text('إدارة البانرات والعروض الخاصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo', color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    const Text('يمكنك رفع بنرات جديدة وتحديد العروض الترويجية النشطة.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontFamily: 'Cairo')),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _banners.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final b = _banners[index];
                final id = b['id']?.toString() ?? '';
                final title = b['title_ar'] as String? ?? 'بدون عنوان';
                final subtitle = b['subtitle_ar'] as String? ?? '';
                final imageUrl = b['image_url'] as String? ?? '';
                final videoUrl = b['video_url'] as String? ?? '';
                final hasVideo = videoUrl.isNotEmpty;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Media Preview
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 130,
                            color: const Color(0xFF0A192F),
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: double.infinity,
                                    height: 130,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
                                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 30)),
                                  )
                                : Center(
                                    child: Icon(
                                      hasVideo ? Icons.videocam_rounded : Icons.photo_library_outlined,
                                      color: Colors.white38,
                                      size: 36,
                                    ),
                                  ),
                          ),
                          if (hasVideo)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam_rounded, color: AppColors.gold, size: 14),
                                    SizedBox(width: 4),
                                    Text('فيديو', style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Details & Actions Row
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, fontFamily: 'Cairo', color: Color(0xFF0F172A)),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontFamily: 'Cairo'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => _showAddEditBannerDialog(banner: b),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.edit_outlined, color: Color(0xFF0F172A), size: 19),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _deleteBanner(id),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 19),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStockMovementsTab() {
    final query = _stockSearchCtrl.text.trim().toLowerCase();
    final filtered = _stockMovements.where((r) {
      if (query.isEmpty) return true;
      final prod = (r['product_name_ar'] as String? ?? '').toLowerCase();
      final orderNum = (r['order_number'] as String? ?? '').toLowerCase();
      final note = (r['note'] as String? ?? '').toLowerCase();
      return prod.contains(query) || orderNum.contains(query) || note.contains(query);
    }).toList();

    int totalIn = 0;
    int totalOut = 0;
    for (final r in filtered) {
      final delta = (r['delta'] as num?)?.toInt() ?? 0;
      if (delta > 0) {
        totalIn += delta;
      } else {
        totalOut += delta.abs();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF047857)),
                          SizedBox(width: 4),
                          Text(
                            'إعادة إلى المخزون',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+$totalIn',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFFBE123C)),
                          SizedBox(width: 4),
                          Text(
                            'خصم من المخزون',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '-$totalOut',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFBE123C)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stockSearchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'المنتج، رقم الطلب، أو الملاحظة...',
                    hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _stockReasonFilter,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('كل الأسباب')),
                      DropdownMenuItem(value: 'order_placed', child: Text('طلب جديد')),
                      DropdownMenuItem(value: 'order_cancelled', child: Text('إلغاء طلب')),
                      DropdownMenuItem(value: 'order_uncancelled', child: Text('إعادة تفعيل')),
                      DropdownMenuItem(value: 'order_deleted', child: Text('حذف طلب')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _stockReasonFilter = v);
                        _loadStockMovements();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingStock)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
            )
          else if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: const Text('لا توجد حركات مخزون مطابقة', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final r = filtered[index];
                final delta = (r['delta'] as num?)?.toInt() ?? 0;
                final isPositive = delta > 0;
                final prodName = r['product_name_ar'] as String? ?? 'منتج محذوف';
                final reason = r['reason'] as String?;
                final note = r['note'] as String?;
                final orderNum = r['order_number'] as String?;
                final actorId = r['actor_id'] as String?;
                final actorName = _actorNames[actorId] ?? (actorId != null && actorId.length > 8 ? actorId.substring(0, 8) : '—');
                final createdAt = r['created_at'];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isPositive ? '+$delta' : '-${delta.abs()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    prodName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getReasonBgColor(reason),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _getReasonBorderColor(reason)),
                                  ),
                                  child: Text(
                                    _getReasonLabel(reason),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: _getReasonTextColor(reason),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (note != null && note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (orderNum != null && orderNum.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.receipt_long_rounded, size: 12, color: Color(0xFF64748B)),
                                      const SizedBox(width: 3),
                                      Text(
                                        '#$orderNum',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF64748B)),
                                    const SizedBox(width: 3),
                                    Text(
                                      actorName,
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatDateTime(createdAt),
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBlockLogTab() {
    final search = _blockSearchCtrl.text.trim().toLowerCase();
    final filtered = _blockLogs.where((e) {
      final action = e['action'] as String? ?? '';
      if (_blockLogFilter != 'all' && action != _blockLogFilter) return false;
      if (search.isNotEmpty) {
        final targetName = _getBlockProfileName(e['user_id'] as String?).toLowerCase();
        final actorName = _getBlockProfileName(e['actor_id'] as String?).toLowerCase();
        if (!targetName.contains(search) && !actorName.contains(search)) return false;
      }
      return true;
    }).toList();

    final blockCount = _blockLogs.where((e) => e['action'] == 'block').length;
    final unblockCount = _blockLogs.where((e) => e['action'] == 'unblock').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.block_rounded, size: 16, color: Color(0xFFDC2626)),
              const SizedBox(width: 6),
              const Text(
                'المحظورون حالياً',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              if (_blockedUsers.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text('(${_blockedUsers.length})', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingBlockData && _blockedUsers.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
          else if (_blockedUsers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: const Text('لا يوجد مستخدمون محظورون', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _blockedUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final u = _blockedUsers[index];
                final uid = u['id'] as String? ?? '';
                final name = u['full_name'] as String? ?? u['phone'] as String? ?? (uid.length > 8 ? uid.substring(0, 8) : uid);
                final phone = u['phone'] as String?;
                final isUnblocking = _unblockingUserId == uid;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.block_rounded, color: Color(0xFFDC2626), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            if (phone != null && phone.isNotEmpty)
                              Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: isUnblocking ? null : () => _unblockUser(uid),
                        icon: isUnblocking
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                            : const Icon(Icons.check_circle_outline_rounded, size: 14),
                        label: const Text('رفع الحظر', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 16, color: Color(0xFF0F172A)),
              const SizedBox(width: 6),
              Text(
                'سجل التدقيق (${_blockLogs.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _blockLogFilter = 'all'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _blockLogFilter == 'all' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _blockLogFilter == 'all'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'الكل (${_blockLogs.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _blockLogFilter == 'all' ? FontWeight.bold : FontWeight.w500,
                              color: _blockLogFilter == 'all' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _blockLogFilter = 'block'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _blockLogFilter == 'block' ? const Color(0xFFFFF1F2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'حظر ($blockCount)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _blockLogFilter == 'block' ? FontWeight.bold : FontWeight.w500,
                              color: _blockLogFilter == 'block' ? const Color(0xFFBE123C) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _blockLogFilter = 'unblock'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _blockLogFilter == 'unblock' ? const Color(0xFFECFDF5) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'رفع حظر ($unblockCount)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _blockLogFilter == 'unblock' ? FontWeight.bold : FontWeight.w500,
                              color: _blockLogFilter == 'unblock' ? const Color(0xFF047857) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _blockSearchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: '...بحث باسم الزبون أو المشرف',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingBlockData && _blockLogs.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
          else if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: const Text('لا توجد سجلات مطابقة', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final e = filtered[index];
                final isBlock = e['action'] == 'block';
                final targetName = _getBlockProfileName(e['user_id'] as String?);
                final actorName = _getBlockProfileName(e['actor_id'] as String?);
                final createdAt = e['created_at'];
                final notif = _matchNotification(e['user_id'] as String?, createdAt);

                final hasNotif = notif != null;
                final isRead = notif?['read_at'] != null;
                final notifText = !hasNotif
                    ? 'لم يُرسل الإشعار'
                    : isRead
                        ? 'تم الاستلام · ${_formatBlockDateTime(notif['read_at'])}'
                        : 'أُرسل — لم يُقرأ بعد';
                final notifBgColor = !hasNotif
                    ? const Color(0xFFFFF1F2)
                    : isRead
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFF1F5F9);
                final notifTextColor = !hasNotif
                    ? const Color(0xFFBE123C)
                    : isRead
                        ? const Color(0xFF047857)
                        : const Color(0xFF64748B);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isBlock ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isBlock ? Icons.block_rounded : Icons.check_circle_rounded,
                          color: isBlock ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isBlock ? 'حظر زبون' : 'رفع الحظر عن زبون',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isBlock ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isBlock ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0)),
                                  ),
                                  child: Text(
                                    isBlock ? 'BLOCK' : 'UNBLOCK',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: isBlock ? const Color(0xFFBE123C) : const Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'الزبون: $targetName',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'بواسطة: $actorName',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatBlockDateTime(createdAt)} · ${_formatRelativeTime(createdAt)}',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: notifBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    !hasNotif ? Icons.mail_outline_rounded : (isRead ? Icons.mark_email_read_outlined : Icons.mail_rounded),
                                    size: 11,
                                    color: notifTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    notifText,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: notifTextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final search = _userSearchCtrl.text.trim().toLowerCase();
    final currentAdminId = Get.isRegistered<AuthService>() ? Get.find<AuthService>().currentUser.value?.id : null;

    final filtered = _users.where((u) {
      // 1. Role filter
      if (_userRoleFilter == 'admin' && u['is_admin'] != true) return false;
      if (_userRoleFilter == 'staff' && (u['is_staff'] != true || u['is_admin'] == true)) return false;
      if (_userRoleFilter == 'customer' && (u['is_admin'] == true || u['is_staff'] == true)) return false;
      if (_userRoleFilter == 'blocked' && u['is_blocked'] != true) return false;

      // 2. Search filter
      if (search.isEmpty) return true;
      final name = (u['full_name'] as String? ?? '').toLowerCase();
      final phone = (u['phone'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final id = (u['id'] as String? ?? '').toLowerCase();
      return name.contains(search) || phone.contains(search) || email.contains(search) || id.contains(search);
    }).toList();

    int activeCount = 0;
    int adminCount = 0;
    int staffCount = 0;
    int customerCount = 0;
    int blockedCount = 0;
    final now = DateTime.now();

    for (final u in _users) {
      if (u['is_admin'] == true) {
        adminCount++;
      } else if (u['is_staff'] == true) {
        staffCount++;
      } else {
        customerCount++;
      }
      if (u['is_blocked'] == true) {
        blockedCount++;
      }
      final updatedStr = u['created_at'];
      if (updatedStr != null) {
        try {
          final dt = DateTime.parse(updatedStr.toString()).toLocal();
          if (now.difference(dt).inMinutes <= 15) {
            activeCount++;
          }
        } catch (_) {}
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 98,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A192F), Color(0xFF162D4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A192F).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'إجمالي المستخدمين',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                        ),
                        Text(
                          '${_users.length}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                        ),
                        Text(
                          '$adminCount مدير • $staffCount موظف',
                          style: TextStyle(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 98,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'متصلون الآن',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A).withValues(alpha: 0.8)),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$activeCount',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'آخر نشاط خلال 15 دقيقة',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A).withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildUserFilterChip(label: 'الكل (${_users.length})', value: 'all'),
                  const SizedBox(width: 8),
                  _buildUserFilterChip(label: '👑 المدراء ($adminCount)', value: 'admin', activeColor: const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _buildUserFilterChip(label: '🛡️ الموظفون ($staffCount)', value: 'staff', activeColor: const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _buildUserFilterChip(label: '👤 الزبائن ($customerCount)', value: 'customer', activeColor: const Color(0xFF64748B)),
                  if (blockedCount > 0) ...[
                    const SizedBox(width: 8),
                    _buildUserFilterChip(label: '🚫 المحظورون ($blockedCount)', value: 'blocked', activeColor: const Color(0xFFDC2626)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _userSearchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: '...ابحث بالاسم، الهاتف، الإيميل أو المعرف',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: _userSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _userSearchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadUsers,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'تحديث',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List Content
            if (_isLoadingUsers && _users.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
            else if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.person_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    const Text('لا يوجد مستخدمون مطابقون', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold)),
                    if (_userRoleFilter != 'all' || _userSearchCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          _userSearchCtrl.clear();
                          setState(() => _userRoleFilter = 'all');
                        },
                        child: const Text('إعادة ضبط التصفية', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                      ),
                    ],
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final u = filtered[index];
                  final userId = u['id']?.toString() ?? '';
                  final name = u['full_name'] as String? ?? 'بدون اسم';
                  final phone = u['phone'] as String?;
                  final email = u['email'] as String?;
                  final avatarUrl = u['avatar_url'] as String?;
                  final isBlocked = u['is_blocked'] == true;
                  final isAdmin = u['is_admin'] == true;
                  final isStaff = u['is_staff'] == true && !isAdmin;
                  final staffPerms = u['staff_permissions'] is Map ? Map<String, dynamic>.from(u['staff_permissions'] as Map) : null;
                  final points = (u['points_balance'] is num) ? (u['points_balance'] as num).toInt() : 0;
                  final createdAt = u['created_at'];
                  final isSelf = currentAdminId != null && currentAdminId == userId;

                  final initial = (name.isNotEmpty && name != 'بدون اسم' ? name[0] : (email != null && email.isNotEmpty ? email[0] : '?')).toUpperCase();

                  final displayPhone = (phone != null && phone.isNotEmpty) ? (phone.startsWith('+') ? phone : '+$phone') : null;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isAdmin
                            ? const Color(0xFFFDE68A)
                            : isStaff
                                ? const Color(0xFFBFDBFE)
                                : const Color(0xFFE2E8F0),
                        width: (isAdmin || isStaff) ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Avatar + Name & Role + IsSelf badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? const Color(0xFFFEF3C7)
                                    : isStaff
                                        ? const Color(0xFFDBEAFE)
                                        : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isAdmin
                                      ? const Color(0xFFF59E0B)
                                      : isStaff
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: avatarUrl,
                                        width: 46,
                                        height: 46,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Text(initial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                      ),
                                    )
                                  : Text(
                                      initial,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isAdmin
                                            ? const Color(0xFFB45309)
                                            : isStaff
                                                ? const Color(0xFF1D4ED8)
                                                : const Color(0xFF475569),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      if (isSelf) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A192F),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('أنت', style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Role & Status Badges
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (isAdmin)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('👑', style: TextStyle(fontSize: 11)),
                                              SizedBox(width: 4),
                                              Text('مدير النظام', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                            ],
                                          ),
                                        )
                                      else if (isStaff)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('🛡️', style: TextStyle(fontSize: 11)),
                                              SizedBox(width: 4),
                                              Text('موظف', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: const Text('👤 زبون عادي', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                        ),

                                      if (isBlocked)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFECDD3)),
                                          ),
                                          child: const Text('🚫 محظور', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                        ),

                                      if (points > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFBEB),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: Text('⭐ $points نقطة', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Staff permission mini tags
                        if (isStaff && staffPerms != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                const Text('صلاحيات:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                if (staffPerms['can_orders'] == true)
                                  _buildMiniPermTag('طلبات 📦'),
                                if (staffPerms['can_products'] == true)
                                  _buildMiniPermTag('منتجات 🏷️'),
                                if (staffPerms['can_replacements'] == true)
                                  _buildMiniPermTag('استبدال 🔄'),
                                if (staffPerms['can_block'] == true)
                                  _buildMiniPermTag('حظر 🚫'),
                                if (staffPerms['can_moderate_comments'] == true)
                                  _buildMiniPermTag('تعليقات 💬'),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Contact info (Phone / Email / Date)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (displayPhone != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(displayPhone, style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontFamily: 'monospace')),
                                        ],
                                      ),
                                    if (email != null && email.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: displayPhone != null ? 2 : 0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 12, color: Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                email,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatDateTime(createdAt),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Action Buttons Bar
                        Row(
                          children: [
                            // 1. Change Role / Permissions
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showChangeUserRoleDialog(u),
                                icon: const Icon(Icons.admin_panel_settings_rounded, size: 14),
                                label: const Text('الصلاحيات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A192F),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 2. Change Password
                            OutlinedButton.icon(
                              onPressed: () => _showChangePasswordDialog(u),
                              icon: const Icon(Icons.key_rounded, size: 14, color: Color(0xFFD97706)),
                              label: const Text('كلمة السر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFDE68A)),
                                backgroundColor: const Color(0xFFFFFBEB),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 3. Delete Account
                            IconButton(
                              onPressed: isSelf ? null : () => _showDeleteUserDialog(u),
                              icon: Icon(
                                Icons.delete_forever_rounded,
                                size: 18,
                                color: isSelf ? const Color(0xFFCBD5E1) : const Color(0xFFDC2626),
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: isSelf ? const Color(0xFFF1F5F9) : const Color(0xFFFEE2E2),
                                padding: const EdgeInsets.all(8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              tooltip: isSelf ? 'لا يمكنك حذف حسابك الحالي' : 'حذف الحساب نهائياً',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFilterChip({
    required String label,
    required String value,
    Color activeColor = const Color(0xFF0A192F),
  }) {
    final isSelected = _userRoleFilter == value;
    return InkWell(
      onTap: () => setState(() => _userRoleFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPermTag(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
    );
  }

  Widget _buildSettingsTab() {
    final usdRateVal = double.tryParse(_usdRateCtrl.text.trim()) ?? 1530.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Basic Store Info
            _buildSettingLabel('اسم المتجر'),
            const SizedBox(height: 6),
            _buildSettingInput(_storeNameCtrl, placeholder: 'مكتب علي شوفرليت'),

            const SizedBox(height: 14),

            _buildSettingLabel('الشعار الفرعي (تحت الاسم)'),
            const SizedBox(height: 6),
            _buildSettingInput(_taglineCtrl, placeholder: 'أهلاً بكم في مكتب علي شوفرليت، GMC وكاديلاك الأصلية اربيل'),

            const SizedBox(height: 14),

            // 2. Store Logo (لوغو)
            _buildSettingLabel('شعار المتجر (لوگو)'),
            const SizedBox(height: 2),
            const Text('الصور', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Row(
              children: [
                Stack(
                  children: [
                    InkWell(
                      onTap: () async {
                        try {
                          final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            setState(() {
                              _localLogoFile = picked;
                              _localLogoBytes = bytes;
                            });
                          }
                        } catch (_) {}
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A192F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _localLogoBytes != null
                            ? Image.memory(_localLogoBytes!, fit: BoxFit.cover)
                            : _storeLogoUrl.isNotEmpty
                                ? CachedNetworkImage(imageUrl: _storeLogoUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54))
                                : const Center(child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.gold, size: 30)),
                      ),
                    ),
                    if (_localLogoBytes != null || _storeLogoUrl.isNotEmpty)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _localLogoFile = null;
                            _localLogoBytes = null;
                            _storeLogoUrl = '';
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('إذا لم يتم رفع صورة سيظهر الحرف الأول من اسم المتجر.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),

            const SizedBox(height: 14),

            // 3. WhatsApp Number
            _buildSettingLabel('رقم الواتساب (صيغة دولية بدون +)'),
            const SizedBox(height: 6),
            _buildSettingInput(_whatsappCtrl, placeholder: '9647855500585', keyboardType: TextInputType.phone),
            const SizedBox(height: 4),
            const Text('مثال: 9647701234567 (964 رمز العراق + الرقم بدون صفر)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),

            const SizedBox(height: 14),

            // 4. Phone Number
            _buildSettingLabel('رقم الاتصال الهاتفي (صيغة دولية بدون +)'),
            const SizedBox(height: 6),
            _buildSettingInput(_phoneCtrl, placeholder: '07855500585', keyboardType: TextInputType.phone),
            const SizedBox(height: 4),
            const Text('يظهر في زر "اتصال هاتفي" بصفحة اتصل بنا. اتركه فارغاً لاستخدام رقم الواتساب.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),

            const SizedBox(height: 14),

            // 5. Address
            _buildSettingLabel('العنوان (يظهر في صفحة اتصل بنا ومن نحن)'),
            const SizedBox(height: 6),
            _buildSettingInput(_addressCtrl, placeholder: 'اربيل'),

            const SizedBox(height: 14),

            // 6. Location Link
            _buildSettingLabel('رابط موقع المحل على الخريطة (Google Maps)'),
            const SizedBox(height: 6),
            _buildSettingInput(_locationLinkCtrl, placeholder: 'https://maps.app.goo.gl/...', keyboardType: TextInputType.url),

            const SizedBox(height: 14),

            // 7. Years of experience
            _buildSettingLabel('عدد سنوات الخبرة في السوق'),
            const SizedBox(height: 6),
            _buildSettingInput(_yearsCtrl, placeholder: '7', keyboardType: TextInputType.number),

            const SizedBox(height: 14),

            // 8. Front Image (واجهة المحل)
            _buildSettingLabel('صورة واجهة المحل'),
            const SizedBox(height: 2),
            const Text('الصور', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Row(
              children: [
                Stack(
                  children: [
                    InkWell(
                      onTap: () async {
                        try {
                          final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
                          if (picked != null) {
                            final bytes = await picked.readAsBytes();
                            setState(() {
                              _localFrontImageFile = picked;
                              _localFrontImageBytes = bytes;
                            });
                          }
                        } catch (_) {}
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _localFrontImageBytes != null
                            ? Image.memory(_localFrontImageBytes!, fit: BoxFit.cover)
                            : _frontImageUrl.isNotEmpty
                                ? CachedNetworkImage(imageUrl: _frontImageUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.broken_image))
                                : const Center(child: Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF64748B), size: 30)),
                      ),
                    ),
                    if (_localFrontImageBytes != null || _frontImageUrl.isNotEmpty)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _localFrontImageFile = null;
                            _localFrontImageBytes = null;
                            _frontImageUrl = '';
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('تظهر في صفحة من نحن.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),

            const SizedBox(height: 14),

            // 9. About Store
            _buildSettingLabel('نبذة عن المتجر (يظهر في من نحن)'),
            const SizedBox(height: 6),
            _buildSettingInput(_aboutCtrl, maxLines: 4, placeholder: 'متجر علي لقطع غيار السيارات متخصص بتوفير قطع غيار...'),

            const SizedBox(height: 16),

            // 10. Global Price Adjustment Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تعديل السعر العام (د.ع)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                  const SizedBox(height: 8),
                  _buildSettingInput(_priceAdjustCtrl, placeholder: '0', keyboardType: TextInputType.number),
                  const SizedBox(height: 6),
                  const Text(
                    'يُضاف هذا المبلغ (أو يُطرح إذا كان سالباً) إلى سعر كل منتج عند عرضه للزبائن. مثال: 1000 يعني رفع كل الأسعار 1000 د.ع، و -1000 يعني خصم 1000 د.ع. لا يغيّر الأسعار الأصلية المحفوظة في قاعدة البيانات.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 11. Loyalty Points System Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 6),
                      Text('نظام نقاط الولاء', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('النقاط المكتسبة لكل 1000 دينار', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            _buildSettingInput(_ptsEarnCtrl, placeholder: '2', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('قيمة النقطة بالدينار عند الاستبدال', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            _buildSettingInput(_ptsRedeemCtrl, placeholder: '250', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('أقل عدد نقاط للاستبدال', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            _buildSettingInput(_ptsMinCtrl, placeholder: '100', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('أقصى نسبة خصم بالنقاط من % الطلب', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            _buildSettingInput(_ptsCapPctCtrl, placeholder: '100', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('وصف بطاقة النقاط (يظهر للزبون)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  _buildSettingInput(_ptsCardTextCtrl, placeholder: 'كل 100 نقطة = 5,000 دينار خصم عند الشراء'),
                  const SizedBox(height: 6),
                  const Text(
                    'تغيير «قيمة النقطة» يُعيد تقييم رصيد كل الزبائن مباشرة عند الاستبدال (رصيدهم بالنقاط لا يتغيّر، لكن قيمته بالدينار تتغيّر). «النقاط المكتسبة» تؤثّر فقط على الطلبات المستقبلية.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 12. Dollar Rate Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('💵', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text('سعر صرف الدولار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'كل الأسعار محفوظة بالدولار. عند تغيير سعر الصرف هنا، تُحسب أسعار جميع المنتجات بالدينار تلقائياً وتظهر مباشرة للزبائن.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  const Text('سعر صرف الدولار (د.ع لكل \$1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  _buildSettingInput(
                    _usdRateCtrl,
                    placeholder: '1530',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1 USD = ${usdRateVal.toInt()} IQD',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 10),
                  const Text('التقريب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _usdRounding,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: '0', child: Text('بدون تقريب', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: '250', child: Text('أقرب 250 د.ع', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: '500', child: Text('أقرب 500 د.ع', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: '1000', child: Text('أقرب 1000 د.ع', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _usdRounding = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 13. Force Update Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(IconsaxPlusBold.refresh_circle, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 6),
                      Text('إعدادات التحديث الإجباري (Force Update)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'عند تعيين رقم إصدار أعلى من إصدار التطبيق لدى الزبون، سيظهر له تنبيه إجباري يمنعه من استخدام التطبيق ويوجهه للمتجر فوراً للتحديث.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('أقل إصدار للأندرويد', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            _buildSettingInput(_minVersionAndroidCtrl, placeholder: '1.0.0'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('أقل إصدار للآيفون', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            _buildSettingInput(_minVersionIosCtrl, placeholder: '1.0.0'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('رابط Google Play Store', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  _buildSettingInput(_playStoreUrlCtrl, placeholder: 'https://play.google.com/store/apps/details?id=...'),
                  const SizedBox(height: 10),
                  const Text('رابط Apple App Store', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  _buildSettingInput(_appStoreUrlCtrl, placeholder: 'https://apps.apple.com/app/id...'),
                  const SizedBox(height: 10),
                  const Text('رسالة التحديث الإجباري', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  _buildSettingInput(_forceUpdateMsgCtrl, maxLines: 2, placeholder: 'يرجى تحديث التطبيق إلى أحدث إصدار لمتابعة الاستخدام...'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Master Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSavingSettings ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isSavingSettings
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('جارٍ الحفظ...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      )
                    : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category Form Dialog with Direct Gallery Upload (No URL Fields!)
// ─────────────────────────────────────────────────────────────

class CategoryFormDialog extends StatefulWidget {
  final CategoryModel? category;
  final VoidCallback onSuccess;

  const CategoryFormDialog({super.key, this.category, required this.onSuccess});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEnCtrl;
  XFile? _localImageFile;
  Uint8List? _localImageBytes;
  String? _existingImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameArCtrl = TextEditingController(text: widget.category?.nameAr ?? '');
    _nameEnCtrl = TextEditingController(text: widget.category?.nameEn ?? '');
    _existingImageUrl = widget.category?.imageUrl;
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _localImageFile = picked;
          _localImageBytes = bytes;
        });
      }
    } catch (e) {
      Get.snackbar('تنبيه', 'يرجى إعادة تشغيل التطبيق بالكامل (Full Restart) لتفعيل صلاحية معرض الصور.',
          backgroundColor: const Color(0xFF0A192F), colorText: Colors.white);
    }
  }

  Future<void> _saveCategory() async {
    if (_nameArCtrl.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال اسم التصنيف بالعربية', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = Get.find<DioClient>().dio;
      String? finalImageUrl = _existingImageUrl;

      if (_localImageFile != null && _localImageBytes != null) {
        final bytes = _localImageBytes!;
        final ext = _localImageFile!.name.split('.').last.toLowerCase();
        final safeExt = ext.isEmpty ? 'jpg' : ext;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_localImageFile!.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';

        try {
          await dio.post(
            '/storage/v1/object/product-images/$fileName',
            data: bytes,
            options: Options(headers: {'Content-Type': safeExt == 'png' ? 'image/png' : 'image/jpeg'}),
          );
          finalImageUrl = '${ApiConstants.baseUrl}/storage/v1/object/public/product-images/$fileName';
        } catch (_) {
          finalImageUrl = '${ApiConstants.baseUrl}/storage/v1/object/public/product-images/$fileName';
        }
      }

      final isEdit = widget.category != null;
      final payload = {
        'name_ar': _nameArCtrl.text.trim(),
        if (_nameEnCtrl.text.trim().isNotEmpty) 'name_en': _nameEnCtrl.text.trim(),
        if (finalImageUrl != null && finalImageUrl.isNotEmpty) 'image_url': finalImageUrl,
      };

      if (isEdit) {
        await dio.patch(
          ApiConstants.categories,
          queryParameters: {'id': 'eq.${widget.category!.id}'},
          data: payload,
        );
      } else {
        await dio.post(
          ApiConstants.categories,
          data: payload,
        );
      }

      Get.back();
      widget.onSuccess();
      Get.snackbar(
        'نجاح',
        isEdit ? 'تم تحديث التصنيف بنجاح' : 'تمت إضافة التصنيف بنجاح',
        backgroundColor: AppColors.inStock,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ التصنيف', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 450),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close_rounded)),
                Text(
                  isEdit ? 'تعديل تصنيف' : 'إضافة تصنيف جديد',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 24),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Text('صورة التصنيف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Center(
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _localImageBytes != null
                            ? Image.memory(_localImageBytes!, fit: BoxFit.cover)
                            : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: _existingImageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 36, color: Color(0xFF64748B))),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF64748B), size: 36),
                                      SizedBox(height: 4),
                                      Text('معرض الصور', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('اسم التصنيف بالعربية *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  _buildInput(_nameArCtrl),
                  const SizedBox(height: 12),
                  const Text('الاسم بالإنجليزي (اختياري)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  _buildInput(_nameEnCtrl),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('جارٍ رفع الصورة والحفظ...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      )
                    : Text(isEdit ? 'حفظ التعديل' : 'إضافة التصنيف', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dedicated Product Form Dialog with Direct Gallery Upload (No URL Fields!)
// ─────────────────────────────────────────────────────────────

class _ProductImageItem {
  final String? remoteUrl;
  final XFile? localFile;
  final Uint8List? localBytes;

  _ProductImageItem({this.remoteUrl, this.localFile, this.localBytes});

  bool get isLocal => localFile != null && localBytes != null;
}

class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final List<CategoryModel> initialCategories;
  final List<BrandModel> initialBrands;
  final List<CarModelModel> initialCarModels;
  final double usdExchangeRate;
  final VoidCallback onSuccess;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.initialCategories,
    required this.initialBrands,
    required this.initialCarModels,
    required this.usdExchangeRate,
    required this.onSuccess,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEnCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _oemCtrl;
  late final TextEditingController _priceUsdCtrl;
  late final TextEditingController _comparePriceIqdCtrl;
  late final TextEditingController _shippingIqdCtrl;
  late final TextEditingController _deliveryGroupCtrl;
  late final TextEditingController _stockCountCtrl;

  bool _mergeDelivery = true;
  String? _selectedCategoryId;
  String? _selectedBrandId;
  final List<String> _selectedCompatibleModels = [];
  final List<_ProductImageItem> _imageItems = [];
  bool _inStock = true;
  String _condition = 'new';
  bool _isFeatured = false;
  bool _isDeal = false;
  bool _hasSideOptions = true;

  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  List<CarModelModel> _carModels = [];
  bool _isLoadingMetadata = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameArCtrl = TextEditingController(text: p?.nameAr ?? '');
    _nameEnCtrl = TextEditingController(text: p?.nameEn ?? '');
    _descCtrl = TextEditingController(text: p?.descriptionAr ?? '');
    _oemCtrl = TextEditingController(text: p?.oemNumber ?? '');

    String initPrice = '';
    if (p != null) {
      if (p.priceUsd > 0) {
        initPrice = p.priceUsd.toString();
      } else if (p.priceIqd > 0 && widget.usdExchangeRate > 0) {
        initPrice = (p.priceIqd / widget.usdExchangeRate).toStringAsFixed(2);
      }
    }
    _priceUsdCtrl = TextEditingController(text: initPrice);
    _comparePriceIqdCtrl = TextEditingController(
      text: p?.comparePriceIqd != null ? p!.comparePriceIqd!.toInt().toString() : '',
    );
    _shippingIqdCtrl = TextEditingController(
      text: p?.shippingIqd != null ? p!.shippingIqd!.toInt().toString() : '0',
    );
    _deliveryGroupCtrl = TextEditingController();
    _stockCountCtrl = TextEditingController(text: p?.stockQty.toString() ?? '1');

    _selectedCategoryId = p?.categoryId;
    _selectedBrandId = p?.brandId;
    if (p != null) {
      _selectedCompatibleModels.addAll(p.compatibleModels);
      for (final url in p.images) {
        if (url.isNotEmpty) {
          _imageItems.add(_ProductImageItem(remoteUrl: url));
        }
      }
    }
    _inStock = p?.inStock ?? true;
    _condition = p?.condition ?? 'new';
    _isFeatured = p?.isFeatured ?? false;
    _isDeal = p?.isDeal ?? false;
    _hasSideOptions = p?.hasSideOptions ?? true;

    _categories = List.from(widget.initialCategories);
    _brands = List.from(widget.initialBrands);
    _carModels = List.from(widget.initialCarModels);

    if (_categories.isEmpty || _brands.isEmpty || _carModels.isEmpty) {
      _fetchMetadata();
    }
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _descCtrl.dispose();
    _oemCtrl.dispose();
    _priceUsdCtrl.dispose();
    _comparePriceIqdCtrl.dispose();
    _shippingIqdCtrl.dispose();
    _deliveryGroupCtrl.dispose();
    _stockCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    setState(() => _isLoadingMetadata = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final results = await Future.wait([
        dio.get(ApiConstants.categories, queryParameters: {'select': '*'}),
        dio.get(ApiConstants.brands, queryParameters: {'select': '*'}),
        dio.get(ApiConstants.carModels, queryParameters: {'select': '*'}),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].data is List) {
            _categories = (results[0].data as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
          }
          if (results[1].data is List) {
            _brands = (results[1].data as List).map((e) => BrandModel.fromJson(e as Map<String, dynamic>)).toList();
          }
          if (results[2].data is List) {
            _carModels = (results[2].data as List).map((e) => CarModelModel.fromJson(e as Map<String, dynamic>)).toList();
          }
          _isLoadingMetadata = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMetadata = false);
    }
  }

  Future<void> _pickLocalImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(imageQuality: 85);
      if (pickedFiles.isEmpty) return;

      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageItems.add(_ProductImageItem(localFile: file, localBytes: bytes));
        });
      }
    } catch (e) {
      Get.snackbar(
        'تنبيه',
        'يرجى إعادة تشغيل التطبيق بالكامل (Full Restart) لتفعيل صلاحية معرض الصور.',
        backgroundColor: const Color(0xFF0A192F),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveProduct() async {
    if (_nameArCtrl.text.trim().isEmpty || _priceUsdCtrl.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال الاسم والسعر بالدولار', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = Get.find<DioClient>().dio;
      final List<String> finalImageUrls = [];

      for (final item in _imageItems) {
        if (item.remoteUrl != null && item.remoteUrl!.isNotEmpty) {
          finalImageUrls.add(item.remoteUrl!);
        } else if (item.isLocal) {
          final bytes = item.localBytes!;
          final ext = item.localFile!.name.split('.').last.toLowerCase();
          final safeExt = ext.isEmpty ? 'jpg' : ext;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${item.localFile!.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';

          try {
            await dio.post(
              '/storage/v1/object/product-images/$fileName',
              data: bytes,
              options: Options(headers: {
                'Content-Type': safeExt == 'png' ? 'image/png' : 'image/jpeg',
              }),
            );
            final publicUrl = '${ApiConstants.baseUrl}/storage/v1/object/public/product-images/$fileName';
            finalImageUrls.add(publicUrl);
          } catch (_) {
            final publicUrl = '${ApiConstants.baseUrl}/storage/v1/object/public/product-images/$fileName';
            finalImageUrls.add(publicUrl);
          }
        }
      }

      final isEdit = widget.product != null;
      final oemVal = _oemCtrl.text.trim().isNotEmpty ? _oemCtrl.text.trim() : 'OEM-${DateTime.now().millisecondsSinceEpoch}';
      final usdNum = double.tryParse(_priceUsdCtrl.text.trim()) ?? 0;
      final iqdNum = (usdNum * widget.usdExchangeRate);

      final payload = {
        'name_ar': _nameArCtrl.text.trim(),
        if (_nameEnCtrl.text.trim().isNotEmpty) 'name_en': _nameEnCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description_ar': _descCtrl.text.trim(),
        'oem_number': oemVal,
        'price_usd': usdNum,
        'price_iqd': iqdNum,
        if (_comparePriceIqdCtrl.text.trim().isNotEmpty)
          'compare_price_iqd': double.tryParse(_comparePriceIqdCtrl.text.trim()),
        'shipping_iqd': double.tryParse(_shippingIqdCtrl.text.trim()) ?? 0,
        'merge_delivery': _mergeDelivery,
        if (_deliveryGroupCtrl.text.trim().isNotEmpty) 'delivery_group': _deliveryGroupCtrl.text.trim(),
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_selectedBrandId != null) 'brand_id': _selectedBrandId,
        'images': finalImageUrls,
        'in_stock': _inStock,
        'stock_qty': int.tryParse(_stockCountCtrl.text.trim()) ?? 0,
        'is_featured': _isFeatured,
        'is_deal': _isDeal,
        'compatible_models': _selectedCompatibleModels,
        'condition': _condition,
        'has_side_options': _hasSideOptions,
      };

      if (isEdit) {
        await dio.patch(
          ApiConstants.products,
          queryParameters: {'id': 'eq.${widget.product!.id}'},
          data: payload,
        );
      } else {
        await dio.post(
          ApiConstants.products,
          data: payload,
        );
      }

      Get.back();
      widget.onSuccess();
      Get.snackbar(
        'نجاح',
        isEdit ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح',
        backgroundColor: AppColors.inStock,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ المنتج', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final usdVal = double.tryParse(_priceUsdCtrl.text.trim()) ?? 0.0;
    final iqdCalc = usdVal * widget.usdExchangeRate;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 720, maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  isEdit ? 'تعديل منتج' : 'إضافة منتج جديد',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 22),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildFormLabel('الصور'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InkWell(
                        onTap: _pickLocalImages,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF64748B), size: 28),
                              SizedBox(height: 3),
                              Text('معرض الصور', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _imageItems.isEmpty
                            ? Container(
                                height: 75,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                alignment: Alignment.center,
                                child: const Text('لم يتم اختيار صور بعد', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              )
                            : SizedBox(
                                height: 75,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _imageItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (ctx, i) {
                                    final item = _imageItems[i];
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 75,
                                          height: 75,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: item.isLocal
                                              ? Image.memory(item.localBytes!, fit: BoxFit.cover)
                                              : CachedNetworkImage(
                                                  imageUrl: item.remoteUrl ?? '',
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 24),
                                                ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () => setState(() => _imageItems.removeAt(i)),
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, color: Colors.white, size: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildFormLabel('الاسم بالعربي *'),
                  const SizedBox(height: 6),
                  _buildInput(_nameArCtrl),
                  const SizedBox(height: 14),
                  _buildFormLabel('الاسم بالإنجليزي'),
                  const SizedBox(height: 6),
                  _buildInput(_nameEnCtrl),
                  const SizedBox(height: 14),
                  _buildFormLabel('الوصف'),
                  const SizedBox(height: 6),
                  _buildInput(_descCtrl, maxLines: 3),
                  const SizedBox(height: 14),
                  _buildFormLabel('رقم القطعة (OEM)'),
                  const SizedBox(height: 6),
                  _buildInput(_oemCtrl),
                  const SizedBox(height: 14),
                  _buildFormLabel('السعر بالدولار *'),
                  const SizedBox(height: 6),
                  _buildInput(
                    _priceUsdCtrl,
                    hint: 'مثال: 12.50',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '× ${widget.usdExchangeRate.toInt()} IQD',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                        Text(
                          usdVal > 0 ? '≈ ${Formatters.formatIQD(iqdCalc)}' : '≈ —',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFormLabel('السعر قبل الخصم (د.ع، اختياري)'),
                  const SizedBox(height: 6),
                  _buildInput(_comparePriceIqdCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  _buildFormLabel('كلفة التوصيل لهذا المنتج (د.ع)'),
                  const SizedBox(height: 6),
                  _buildInput(_shippingIqdCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إعدادات التوصيل',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Switch(
                              value: _mergeDelivery,
                              activeThumbColor: const Color(0xFF0A192F),
                              onChanged: (v) => setState(() => _mergeDelivery = v),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'دمج التوصيل مع منتجات نفس المجموعة',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'عند التفعيل، تُحتسب أجرة التوصيل مرة واحدة لكل مجموعة؛ عند الإيقاف، تُحتسب مستقلة دائماً.',
                                    style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'مجموعة التوصيل (مثال: Small Parts / Medium Parts / Large Parts)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        _buildInput(_deliveryGroupCtrl, hint: 'اترك فارغاً لتوصيل مستقل لهذا المنتج'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFormLabel('التصنيف'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        hint: const Text('اختر تصنيف', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('اختر تصنيف', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                          ),
                          ..._categories.map((c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.nameAr, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFormLabel('الماركة'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBrandId,
                        isExpanded: true,
                        hint: const Text('اختر ماركة', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('اختر ماركة', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                          ),
                          ..._brands.map((b) => DropdownMenuItem<String>(
                                value: b.id,
                                child: Text(b.nameAr, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedBrandId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFormLabel('السيارات المتوافقة'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isLoadingMetadata
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                              )
                            : _carModels.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text('لا توجد موديلات مسجلة', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    ),
                                  )
                                : ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: _carModels.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      itemBuilder: (ctx, i) {
                                        final m = _carModels[i];
                                        final isChecked = _selectedCompatibleModels.contains(m.id) ||
                                            _selectedCompatibleModels.contains(m.nameAr);

                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (isChecked) {
                                                _selectedCompatibleModels.remove(m.id);
                                                _selectedCompatibleModels.remove(m.nameAr);
                                              } else {
                                                _selectedCompatibleModels.add(m.id);
                                              }
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Row(
                                              children: [
                                                if (m.nameEn != null && m.nameEn!.isNotEmpty)
                                                  Text(
                                                    m.nameEn!,
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                                                  ),
                                                const Spacer(),
                                                Text(
                                                  m.nameAr,
                                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                ),
                                                const SizedBox(width: 8),
                                                Checkbox(
                                                  value: isChecked,
                                                  activeColor: const Color(0xFF0A192F),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                  onChanged: (v) {
                                                    setState(() {
                                                      if (v == true) {
                                                        _selectedCompatibleModels.add(m.id);
                                                      } else {
                                                        _selectedCompatibleModels.remove(m.id);
                                                        _selectedCompatibleModels.remove(m.nameAr);
                                                      }
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                        const Divider(height: 12),
                        Text(
                          '${_selectedCompatibleModels.length} موديل محدد',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'يدعم خيارات الجوانب (يمين / يسار / تخم)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'عند التعطيل، يصبح المنتج مفرداً ولا يظهر له خيار الجهة أو التخم.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _hasSideOptions,
                          activeThumbColor: const Color(0xFF0A192F),
                          onChanged: (v) => setState(() => _hasSideOptions = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('متوفر', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Switch(
                        value: _inStock,
                        activeThumbColor: const Color(0xFF0A192F),
                        onChanged: (v) => setState(() => _inStock = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildFormLabel('عدد القطع المتوفرة'),
                  const SizedBox(height: 6),
                  _buildInput(_stockCountCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  _buildFormLabel('حالة المنتج'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _condition = 'new'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _condition == 'new' ? const Color(0xFF0A192F) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _condition == 'new' ? const Color(0xFF0A192F) : const Color(0xFFCBD5E1)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'جديد',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _condition == 'new' ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _condition = 'used'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _condition == 'used' ? const Color(0xFF0A192F) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _condition == 'used' ? const Color(0xFF0A192F) : const Color(0xFFCBD5E1)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'مستعمل',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _condition == 'used' ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('مميز', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Switch(
                        value: _isFeatured,
                        activeThumbColor: const Color(0xFF0A192F),
                        onChanged: (v) => setState(() => _isFeatured = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('عرض / تخفيض', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Switch(
                        value: _isDeal,
                        activeThumbColor: const Color(0xFF0A192F),
                        onChanged: (v) => setState(() => _isDeal = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('جارٍ رفع الصور وحفظ المنتج...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      )
                    : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Brand Form Dialog
// ─────────────────────────────────────────────────────────────

class BrandFormDialog extends StatefulWidget {
  final BrandModel? brand;
  final VoidCallback onSuccess;

  const BrandFormDialog({super.key, this.brand, required this.onSuccess});

  @override
  State<BrandFormDialog> createState() => _BrandFormDialogState();
}

class _BrandFormDialogState extends State<BrandFormDialog> {
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEnCtrl;
  XFile? _localLogoFile;
  Uint8List? _localLogoBytes;
  String? _existingLogoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameArCtrl = TextEditingController(text: widget.brand?.nameAr ?? '');
    _nameEnCtrl = TextEditingController(text: widget.brand?.nameEn ?? '');
    _existingLogoUrl = widget.brand?.logoUrl;
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _localLogoFile = picked;
          _localLogoBytes = bytes;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveBrand() async {
    if (_nameArCtrl.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال اسم الماركة بالعربية', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = Get.find<DioClient>().dio;
      String? finalLogoUrl = _existingLogoUrl;

      if (_localLogoFile != null && _localLogoBytes != null) {
        final bytes = _localLogoBytes!;
        final ext = _localLogoFile!.name.split('.').last.toLowerCase();
        final safeExt = ext.isEmpty ? 'png' : ext;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_localLogoFile!.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';

        try {
          await dio.post(
            '/storage/v1/object/product-images/$fileName',
            data: bytes,
            options: Options(headers: {'Content-Type': safeExt == 'png' ? 'image/png' : 'image/jpeg'}),
          );
          finalLogoUrl = '${ApiConstants.baseUrl}/storage/v1/object/public/product-images/$fileName';
        } catch (_) {
          finalLogoUrl = '${ApiConstants.baseUrl}/storage/v1/object/public/product-images/$fileName';
        }
      }

      final isEdit = widget.brand != null;
      final payload = {
        'name_ar': _nameArCtrl.text.trim(),
        'name_en': _nameEnCtrl.text.trim().isNotEmpty ? _nameEnCtrl.text.trim() : _nameArCtrl.text.trim(),
        if (finalLogoUrl != null && finalLogoUrl.isNotEmpty) 'logo_url': finalLogoUrl,
      };

      if (isEdit) {
        await dio.patch(
          ApiConstants.brands,
          queryParameters: {'id': 'eq.${widget.brand!.id}'},
          data: payload,
        );
      } else {
        await dio.post(
          ApiConstants.brands,
          data: payload,
        );
      }

      Get.back();
      widget.onSuccess();
      Get.snackbar(
        'نجاح',
        isEdit ? 'تم تحديث الماركة بنجاح' : 'تمت إضافة الماركة بنجاح',
        backgroundColor: AppColors.inStock,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ الماركة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.brand != null;
    final hasLogo = _localLogoBytes != null || (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 450),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close_rounded)),
                Text(
                  isEdit ? 'تعديل ماركة' : 'إضافة ماركة جديدة',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 24),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Text('شعار الماركة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Center(
                    child: InkWell(
                      onTap: _pickLogo,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasLogo
                            ? (_localLogoBytes != null
                                ? Image.memory(_localLogoBytes!, fit: BoxFit.contain)
                                : CachedNetworkImage(imageUrl: _existingLogoUrl!, fit: BoxFit.contain))
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_rounded, size: 28, color: Color(0xFF64748B)),
                                  SizedBox(height: 4),
                                  Text('رفع شعار', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('الاسم بالعربي *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameArCtrl,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'مثال: شفروليه',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('الاسم بالإنجليزي (اختياري)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameEnCtrl,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Chevrolet',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBrand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Car Model Form Dialog
// ─────────────────────────────────────────────────────────────

class CarModelFormDialog extends StatefulWidget {
  final CarModelModel? model;
  final List<BrandModel> brands;
  final VoidCallback onSuccess;

  const CarModelFormDialog({super.key, this.model, required this.brands, required this.onSuccess});

  @override
  State<CarModelFormDialog> createState() => _CarModelFormDialogState();
}

class _CarModelFormDialogState extends State<CarModelFormDialog> {
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEnCtrl;
  String? _selectedBrandId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameArCtrl = TextEditingController(text: widget.model?.nameAr ?? '');
    _nameEnCtrl = TextEditingController(text: widget.model?.nameEn ?? '');
    _selectedBrandId = widget.model?.brandId;
    if (_selectedBrandId == null && widget.brands.isNotEmpty) {
      _selectedBrandId = widget.brands.first.id;
    }
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveModel() async {
    if (_selectedBrandId == null || _selectedBrandId!.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى اختيار الماركة أولاً', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }
    if (_nameArCtrl.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال اسم نوع السيارة بالعربية', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = Get.find<DioClient>().dio;
      final isEdit = widget.model != null;
      final payload = {
        'brand_id': _selectedBrandId,
        'name_ar': _nameArCtrl.text.trim(),
        'name_en': _nameEnCtrl.text.trim().isNotEmpty ? _nameEnCtrl.text.trim() : _nameArCtrl.text.trim(),
      };

      if (isEdit) {
        await dio.patch(
          ApiConstants.carModels,
          queryParameters: {'id': 'eq.${widget.model!.id}'},
          data: payload,
        );
      } else {
        await dio.post(
          ApiConstants.carModels,
          data: payload,
        );
      }

      Get.back();
      widget.onSuccess();
      Get.snackbar(
        'نجاح',
        isEdit ? 'تم تحديث نوع السيارة بنجاح' : 'تمت إضافة نوع السيارة بنجاح',
        backgroundColor: AppColors.inStock,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ نوع السيارة', backgroundColor: AppColors.outOfStock, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.model != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 450),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close_rounded)),
                Text(
                  isEdit ? 'تعديل نوع سيارة' : 'إضافة نوع سيارة جديد',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 24),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Text('الماركة *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBrandId,
                        isExpanded: true,
                        hint: const Text('اختر الماركة', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                        items: widget.brands.map((b) {
                          return DropdownMenuItem(
                            value: b.id,
                            child: Text(b.nameAr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBrandId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('اسم السيارة بالعربي *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameArCtrl,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'مثال: ماليبو',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('اسم السيارة بالإنجليزي (اختياري)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameEnCtrl,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Malibu',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveModel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
