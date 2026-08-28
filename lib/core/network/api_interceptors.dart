import 'package:dio/dio.dart';
import '../../app/config/app_constants.dart';
import '../services/secure_storage_service.dart';
import '../utils/app_logger.dart';

class ApiInterceptors extends Interceptor {
  final SecureStorageService _secureStorage;

  ApiInterceptors(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Inject Bearer token if available
    final token = await _secureStorage.read(AppConstants.secureKeyAccessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Inject Admin Device ID if available
    final deviceId = await _secureStorage.read(AppConstants.secureKeyAdminDeviceId);
    if (deviceId != null && deviceId.isNotEmpty) {
      options.headers['x-admin-device-id'] = deviceId;
    }

    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    AppLogger.d('--> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d('<-- ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e('<!- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}
