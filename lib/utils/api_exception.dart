import 'package:dio/dio.dart';

/// API例外クラス
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseData;
  final DioExceptionType? type;

  const ApiException({
    required this.message,
    this.statusCode,
    this.responseData,
    this.type,
  });

  /// DioExceptionから変換
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'リクエストがタイムアウトしました',
          type: error.type,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return ApiException(
            message: 'API設定に問題があります',
            statusCode: statusCode,
            responseData: error.response?.data,
            type: error.type,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ApiException(
            message: 'サーバーエラーが発生しました',
            statusCode: statusCode,
            responseData: error.response?.data,
            type: error.type,
          );
        }
        return ApiException(
          message: 'APIエラーが発生しました',
          statusCode: statusCode,
          responseData: error.response?.data,
          type: error.type,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'リクエストがキャンセルされました',
          type: error.type,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: 'ネットワークエラーが発生しました',
          type: error.type,
        );
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }
    return buffer.toString();
  }
}
