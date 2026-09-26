import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../app/config/api_constants.dart';
import '../../app/config/app_constants.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';

class DioClient {
  final SecureStorageService _secureStorage;
  late final Dio dio;

  DioClient(this._secureStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'apikey': ApiConstants.anonKey,
        },
      ),
    );

    dio.interceptors.add(PrettyDioLogger());

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Use user's access token if logged in, else use anon key
          final token = await _secureStorage.read(
            AppConstants.secureKeyAccessToken,
          );
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers['Authorization'] = 'Bearer ${ApiConstants.anonKey}';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Auto-refresh on 401 Unauthorized
          if (error.response?.statusCode == 401) {
            try {
              if (Get.isRegistered<AuthService>()) {
                final authService = Get.find<AuthService>();
                final refreshed = await authService.refreshAndRetry();
                if (refreshed) {
                  // Retry the original request with new token
                  final token = await _secureStorage.read(
                    AppConstants.secureKeyAccessToken,
                  );
                  if (token != null) {
                    error.requestOptions.headers['Authorization'] =
                        'Bearer $token';
                    final retryResponse = await dio.fetch(error.requestOptions);
                    return handler.resolve(retryResponse);
                  }
                }
              }
            } catch (_) {}
          }

          return handler.next(error);
        },
      ),
    );
  }
}
