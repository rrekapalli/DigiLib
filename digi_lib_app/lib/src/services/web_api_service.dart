import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class WebApiService {
  static Dio? _dio;

  static Dio get dio {
    if (_dio == null) {
      _dio = Dio();

      // Configure Dio for web with CORS handling
      _dio!.options = BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Add interceptor for web-specific handling
      if (kIsWeb) {
        _dio!.interceptors.add(WebCorsInterceptor());
      }
    }
    return _dio!;
  }
}

class WebCorsInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add CORS-friendly headers for web requests
    options.headers.addAll({
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers':
          'Origin, Content-Type, Accept, Authorization',
    });

    debugPrint('🌐 Web request to: ${options.uri}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kIsWeb && err.type == DioExceptionType.connectionError) {
      debugPrint('🚫 CORS Error detected: ${err.message}');
      debugPrint('💡 Consider configuring CORS on your API server');
    }
    handler.next(err);
  }
}
