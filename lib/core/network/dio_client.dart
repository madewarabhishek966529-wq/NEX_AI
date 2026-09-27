import 'package:dio/dio.dart';
import '../constants.dart';
import '../errors/failures.dart';

class DioClient {
  late final Dio _dio;
  String _baseUrl;

  DioClient({String? baseUrl}) : _baseUrl = baseUrl ?? AppConstants.defaultBaseUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // You can attach custom auth tokens or device IDs here
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl.endsWith('/') ? newUrl.substring(0, newUrl.length - 1) : newUrl;
    _dio.options.baseUrl = _baseUrl;
  }

  Failure handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure('Cannot reach companion server. Is the FastAPI backend running?');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        String msg = 'Server returned error ($status)';
        if (data is Map && data.containsKey('detail')) {
          msg = data['detail'].toString();
        }
        return ServerFailure(msg, status);
      case DioExceptionType.cancel:
        return const GeneralFailure('Request was cancelled');
      default:
        return GeneralFailure(e.message ?? 'Unknown network error');
    }
  }
}
