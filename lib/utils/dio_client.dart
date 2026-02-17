import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

/// Dioクライアントのプロバイダー（シングルトン）
@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // リクエストインターセプター（ログ出力）
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('[DIO REQUEST] ${options.method} ${options.path}');
        debugPrint('[DIO REQUEST HEADERS] ${options.headers}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
          '[DIO RESPONSE] ${response.statusCode} ${response.requestOptions.path}',
        );
        debugPrint('[DIO RESPONSE DATA] ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('[DIO ERROR] ${error.type} ${error.message}');
        debugPrint('[DIO ERROR RESPONSE] ${error.response?.data}');
        return handler.next(error);
      },
    ),
  );

  return dio;
}
