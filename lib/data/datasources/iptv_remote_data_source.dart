import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tiwee/data/models/category_model.dart';
import 'package:tiwee/data/models/country_model.dart';

/// Exception for API errors
class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Remote data source for the iptv-org API.
///
/// Only handles transport. The large catalog endpoints are returned as raw
/// bytes so decoding and merging can happen on a background isolate instead of
/// janking the UI — `channels.json` alone is ~10 MB.
class IptvRemoteDataSource {
  IptvRemoteDataSource({
    Dio? dio,
    this.baseUrl = 'https://iptv-org.github.io/api',
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  final Dio _dio;
  final String baseUrl;

  Future<Uint8List> getChannelsBytes() => _getBytes('channels.json');

  Future<Uint8List> getStreamsBytes() => _getBytes('streams.json');

  Future<Uint8List> getLogosBytes() => _getBytes('logos.json');

  Future<String> getCategoriesJson() => _getString('categories.json');

  Future<String> getCountriesJson() => _getString('countries.json');

  Future<Uint8List> _getBytes(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        '$baseUrl/$path',
        options: Options(responseType: ResponseType.bytes),
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        throw ApiException('Empty response from $path', response.statusCode);
      }

      return data is Uint8List ? data : Uint8List.fromList(data);
    } on DioException catch (error) {
      throw ApiException(_describe(error, path), error.response?.statusCode);
    }
  }

  Future<String> _getString(String path) async {
    try {
      final response = await _dio.get<String>(
        '$baseUrl/$path',
        options: Options(responseType: ResponseType.plain),
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        throw ApiException('Empty response from $path', response.statusCode);
      }

      return data;
    } on DioException catch (error) {
      throw ApiException(_describe(error, path), error.response?.statusCode);
    }
  }

  /// Turns transport failures into messages that are useful on screen.
  String _describe(DioException error, String path) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The connection timed out while loading $path.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        return 'The server rejected the request for $path.';
      case DioExceptionType.cancel:
        return 'The request for $path was cancelled.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return 'Could not load $path (${error.message ?? 'unknown error'}).';
    }
  }
}

/// Parses `categories.json`.
List<CategoryModel> parseCategories(String json) {
  return (jsonDecode(json) as List<dynamic>)
      .map((entry) => CategoryModel.fromJson(entry as Map<String, dynamic>))
      .toList();
}

/// Parses `countries.json`.
List<CountryModel> parseCountries(String json) {
  return (jsonDecode(json) as List<dynamic>)
      .map((entry) => CountryModel.fromJson(entry as Map<String, dynamic>))
      .toList();
}
