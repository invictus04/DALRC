import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late Dio dio;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  // Use the physical machine's local IP address for external mobile testing
  String get _baseUrl {
    return 'http://192.168.0.103:3000';
  }

  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        log('REQUEST: ${options.method} ${options.uri}');
        final token = await secureStorage.read(key: 'jwt');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle global errors here
        log(e.message.toString());
        return handler.next(e);
      },
    ));
  }
}
