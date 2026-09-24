import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../errors/app_failure.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.readAccess();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final options = error.requestOptions;
              final token = await TokenStorage.readAccess();
              options.headers['Authorization'] = 'Bearer $token';
              final retry = await _dio.fetch(options);
              return handler.resolve(retry);
            }
          }
          handler.next(error);
        },
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Future<bool> _tryRefresh() async {
    try {
      final refresh = await TokenStorage.readRefresh();
      if (refresh == null) return false;
      final resp = await Dio(
        BaseOptions(baseUrl: AppConstants.apiBaseUrl),
      ).post('/auth/refresh/', data: {'refresh': refresh});
      final access = resp.data['access'] as String;
      await TokenStorage.saveTokens(access: access, refresh: refresh);
      return true;
    } catch (_) {
      await TokenStorage.clear();
      return false;
    }
  }

  Map<String, dynamic> _body(Response resp) => (resp.data as Map<String, dynamic>?)?['data'] ?? {};

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return resp.data ?? {};
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(path, data: data);
      return resp.data ?? {};
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {Object? data}) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(path, data: data);
      return resp.data ?? {};
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  ApiException _toFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('Request timed out. Please check your connection and retry.');
      case DioExceptionType.connectionError:
        return const ApiException('Network error. Could not reach the TripGo server.');
      case DioExceptionType.badResponse:
        final body = e.response?.data;
        if (body is Map<String, dynamic>) {
          final error = (body['error'] ?? body['message'])?.toString();
          if (error != null && error.isNotEmpty) {
            return ApiException(error, statusCode: e.response?.statusCode);
          }
        }
        return ApiException(
          'Server error (${e.response?.statusCode ?? 'unknown'}). Please try again.',
          statusCode: e.response?.statusCode,
        );
      default:
        if (e.error is SocketException) {
          return const ApiException('No internet connection. Please retry.');
        }
        return ApiException(e.message ?? 'Something went wrong.', error: e.error);
    }
  }
}

Map<String, dynamic> unwrapData(Map<String, dynamic> resp) =>
    resp['data'] is Map<String, dynamic> ? resp['data'] as Map<String, dynamic> : <String, dynamic>{};