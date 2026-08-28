import 'package:dio/dio.dart';

class NetworkExceptions implements Exception {
  final String message;
  final int? statusCode;

  NetworkExceptions({required this.message, this.statusCode});

  factory NetworkExceptions.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkExceptions(message: 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة لاحقاً.');
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        final msg = error.response?.data?['message'] ?? 'خطأ في الخادم ($code)';
        return NetworkExceptions(message: msg.toString(), statusCode: code);
      case DioExceptionType.cancel:
        return NetworkExceptions(message: 'تم إلغاء الطلب.');
      case DioExceptionType.connectionError:
        return NetworkExceptions(message: 'تعذر الاتصال بالشبكة. يرجى التحقق من اتصالك.');
      default:
        return NetworkExceptions(message: 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.');
    }
  }

  @override
  String toString() => message;
}
