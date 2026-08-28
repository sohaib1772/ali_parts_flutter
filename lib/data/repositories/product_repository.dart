import 'package:dio/dio.dart';
import '../../app/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/banner_model.dart';
import '../models/brand_model.dart';
import '../models/car_model_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductQueryResult {
  final List<ProductModel> products;
  final int totalCount;

  ProductQueryResult({required this.products, required this.totalCount});
}

class ProductRepository {
  final DioClient _dioClient;

  List<CategoryModel>? _cachedCategories;
  List<BrandModel>? _cachedBrands;
  List<CarModelModel>? _cachedCarModels;

  ProductRepository(this._dioClient);

  Future<List<CategoryModel>> fetchCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.categories,
        queryParameters: {'select': '*', 'order': 'sort_order'},
      );
      if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List) {
        _cachedCategories = (response.data as List)
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return _cachedCategories!;
      }
    } catch (_) {}
    return _cachedCategories ?? [];
  }

  Future<List<BrandModel>> fetchBrands({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedBrands != null && _cachedBrands!.isNotEmpty) {
      return _cachedBrands!;
    }
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.brands,
        queryParameters: {'select': '*', 'order': 'sort_order'},
      );
      if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List) {
        _cachedBrands = (response.data as List)
            .map((e) => BrandModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return _cachedBrands!;
      }
    } catch (_) {}
    return _cachedBrands ?? [];
  }

  Future<List<CarModelModel>> fetchCarModels({String? brandId, bool forceRefresh = false}) async {
    if (brandId == null && !forceRefresh && _cachedCarModels != null && _cachedCarModels!.isNotEmpty) {
      return _cachedCarModels!;
    }
    final params = <String, dynamic>{'select': '*', 'order': 'sort_order'};
    if (brandId != null && brandId.isNotEmpty) {
      params['brand_id'] = 'eq.$brandId';
    }
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.carModels,
        queryParameters: params,
      );
      if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List) {
        final list = (response.data as List)
            .map((e) => CarModelModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (brandId == null) {
          _cachedCarModels = list;
        }
        return list;
      }
    } catch (_) {}
    return _cachedCarModels ?? [];
  }

  Future<List<BannerModel>> fetchBanners() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.banners,
        queryParameters: {
          'select': '*',
          'is_active': 'eq.true',
          'order': 'created_at.desc',
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List) {
        return (response.data as List)
            .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
            .where((b) => !b.isExpired)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<ProductModel>> fetchFeaturedProducts({int limit = 10}) async {
    final response = await _dioClient.dio.get(
      ApiConstants.products,
      queryParameters: {
        'select': '*',
        'is_featured': 'eq.true',
        'order': 'created_at.desc',
        'limit': limit,
      },
    );
    if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List) {
      return (response.data as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ProductModel>> fetchDeals({int limit = 10}) async {
    final response = await _dioClient.dio.get(
      ApiConstants.products,
      queryParameters: {
        'select': '*',
        'is_deal': 'eq.true',
        'order': 'created_at.desc',
        'limit': limit,
      },
    );
    if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List) {
      return (response.data as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ProductModel>> fetchBestSellers({int limit = 12}) async {
    final response = await _dioClient.dio.get(
      ApiConstants.products,
      queryParameters: {
        'select': '*',
        'order': 'sales_count.desc',
        'limit': limit,
      },
    );
    if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List) {
      return (response.data as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ProductQueryResult> fetchProducts({
    String? categoryId,
    String? brandId,
    String? carModelId,
    String? condition,
    String? searchQuery,
    String? sort,
    int offset = 0,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'select': '*',
      'offset': offset,
      'limit': limit,
    };

    if (categoryId != null && categoryId.isNotEmpty) {
      params['category_id'] = 'eq.$categoryId';
    }
    if (brandId != null && brandId.isNotEmpty) {
      params['brand_id'] = 'eq.$brandId';
    }
    if (carModelId != null && carModelId.isNotEmpty) {
      params['compatible_models'] = 'cs.{$carModelId}';
    }
    if (condition != null && condition.isNotEmpty && condition != 'all') {
      params['condition'] = 'eq.$condition';
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      params['or'] = '(name_ar.ilike.%$q%,name_en.ilike.%$q%,oem_number.ilike.%$q%)';
    }

    if (sort == 'price_asc') {
      params['order'] = 'price_iqd.asc';
    } else if (sort == 'price_desc') {
      params['order'] = 'price_iqd.desc';
    } else if (sort == 'sales') {
      params['order'] = 'sales_count.desc';
    } else {
      params['order'] = 'in_stock.desc,created_at.desc';
    }

    final response = await _dioClient.dio.get(
      ApiConstants.products,
      queryParameters: params,
      options: Options(headers: {'Prefer': 'count=exact'}),
    );

    if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List) {
      final list = (response.data as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      int total = list.length;
      final cr = response.headers.value('content-range');
      if (cr != null && cr.contains('/')) {
        final totalStr = cr.split('/').last;
        total = int.tryParse(totalStr) ?? list.length;
      }

      return ProductQueryResult(products: list, totalCount: total);
    }
    return ProductQueryResult(products: [], totalCount: 0);
  }

  Future<ProductModel?> fetchProductById(String id) async {
    final response = await _dioClient.dio.get(
      ApiConstants.products,
      queryParameters: {
        'select': '*',
        'id': 'eq.$id',
        'limit': 1,
      },
    );
    if ((response.statusCode == 200 || response.statusCode == 206) && response.data is List && (response.data as List).isNotEmpty) {
      return ProductModel.fromJson((response.data as List).first as Map<String, dynamic>);
    }
    return null;
  }
}
