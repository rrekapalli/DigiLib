import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api/api_error.dart';

/// Abstract interface for API client operations
abstract class ApiClient {
  /// Perform GET request
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParams});
  
  /// Perform POST request
  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? queryParams});
  
  /// Perform PUT request
  Future<T> put<T>(String path, {Object? body});
  
  /// Perform DELETE request
  Future<T> delete<T>(String path);
  
  /// Set authentication token
  void setAuthToken(String token);
  
  /// Clear authentication token
  void clearAuthToken();
  
  /// Check if client has authentication token
  bool get hasAuthToken;
  
  /// Get base URL
  String get baseUrl;
}

/// Configuration for API client
class ApiClientConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final int maxRetries;
  final Duration retryDelay;
  final bool enableLogging;

  const ApiClientConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableLogging = kDebugMode,
  });
}

/// Dio-based implementation of ApiClient
class DioApiClient implements ApiClient {
  final Dio _dio;
  final ApiClientConfig _config;
  String? _authToken;

  DioApiClient(this._config) : _dio = Dio() {
    _setupDio();
  }

  @override
  String get baseUrl => _config.baseUrl;

  @override
  bool get hasAuthToken => _authToken != null;

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: _config.connectTimeout,
      receiveTimeout: _config.receiveTimeout,
      sendTimeout: _config.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add request interceptor for authentication and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Add retry interceptor
    _dio.interceptors.add(_RetryInterceptor(_config));

    // Add logging interceptor in debug mode
    if (_config.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add authentication header if token is available
    if (_authToken != null) {
      options.headers['Authorization'] = 'Bearer $_authToken';
    }
    
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    final apiException = _handleDioError(error);
    handler.reject(DioException(
      requestOptions: error.requestOptions,
      error: apiException,
      type: error.type,
      response: error.response,
    ));
  }

  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          ApiError(
            message: 'Request timeout. Please check your internet connection.',
            code: 'TIMEOUT',
            status: null,
            timestamp: DateTime.now(),
          ),
          error.message,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          ApiError(
            message: 'Connection error. Please check your internet connection.',
            code: 'CONNECTION_ERROR',
            status: null,
            timestamp: DateTime.now(),
          ),
          error.message,
        );

      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null) {
          try {
            // Try to parse API error from response
            final errorData = response.data;
            if (errorData is Map<String, dynamic>) {
              return ApiException(ApiError.fromJson(errorData));
            }
          } catch (e) {
            // Fallback to generic error
          }
          
          return ApiException(
            ApiError(
              message: _getStatusMessage(response.statusCode ?? 0),
              code: 'HTTP_${response.statusCode}',
              status: response.statusCode,
              timestamp: DateTime.now(),
            ),
          );
        }
        break;

      case DioExceptionType.cancel:
        return ApiException(
          ApiError(
            message: 'Request was cancelled.',
            code: 'CANCELLED',
            status: null,
            timestamp: DateTime.now(),
          ),
          error.message,
        );

      case DioExceptionType.unknown:
        return ApiException(
          ApiError(
            message: 'An unexpected error occurred.',
            code: 'UNKNOWN',
            status: null,
            timestamp: DateTime.now(),
          ),
          error.message,
        );

      case DioExceptionType.badCertificate:
        return ApiException(
          ApiError(
            message: 'SSL certificate error.',
            code: 'SSL_ERROR',
            status: null,
            timestamp: DateTime.now(),
          ),
          error.message,
        );
    }

    return ApiException(
      ApiError(
        message: 'An unexpected error occurred.',
        code: 'UNKNOWN',
        status: null,
        timestamp: DateTime.now(),
      ),
      error.message,
    );
  }

  String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Authentication required. Please sign in.';
      case 403:
        return 'Access denied. You don\'t have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. The resource already exists or has been modified.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. The server took too long to respond.';
      default:
        return 'HTTP error $statusCode occurred.';
    }
  }

  @override
  void setAuthToken(String token) {
    _authToken = token;
  }

  @override
  void clearAuthToken() {
    _authToken = null;
  }

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParams,
      );
      return response.data as T;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      rethrow;
    }
  }

  @override
  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: body,
        queryParameters: queryParams,
      );
      return response.data as T;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      rethrow;
    }
  }

  @override
  Future<T> put<T>(String path, {Object? body}) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: body,
      );
      return response.data as T;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      rethrow;
    }
  }

  @override
  Future<T> delete<T>(String path) async {
    try {
      final response = await _dio.delete<T>(path);
      return response.data as T;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      rethrow;
    }
  }
}

/// Retry interceptor for handling network failures
class _RetryInterceptor extends Interceptor {
  final ApiClientConfig _config;

  _RetryInterceptor(this._config);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && err.requestOptions.extra['retryCount'] == null) {
      err.requestOptions.extra['retryCount'] = 0;
    }

    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    
    if (_shouldRetry(err) && retryCount < _config.maxRetries) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      
      // Wait before retrying with exponential backoff
      final delay = _config.retryDelay * (retryCount + 1);
      await Future.delayed(delay);
      
      try {
        final dio = Dio();
        dio.options = err.requestOptions.copyWith() as BaseOptions;
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continue with original error handling
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException error) {
    // Retry on network errors and 5xx server errors
    return error.type == DioExceptionType.connectionError ||
           error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           (error.response?.statusCode != null && 
            error.response!.statusCode! >= 500);
  }
}