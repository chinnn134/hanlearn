import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';

@immutable
class DictionaryItem {
  const DictionaryItem({
    required this.vocabId,
    required this.hanzi,
    required this.pinyin,
    required this.meaningVi,
    required this.levels,
    required this.sourceId,
  });

  final String vocabId;
  final String hanzi;
  final String pinyin;
  final String meaningVi;
  final Map<String, int> levels;
  final String sourceId;

  factory DictionaryItem.fromJson(Map<String, dynamic> json) => DictionaryItem(
    vocabId: json['vocabId'] as String,
    hanzi: json['hanzi'] as String,
    pinyin: json['pinyin'] as String,
    meaningVi: json['meaningVi'] as String,
    levels: (json['levels'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    ),
    sourceId: json['sourceId'] as String,
  );
}

@immutable
class DictionaryDetail {
  const DictionaryDetail({
    required this.item,
    required this.traditional,
    required this.pinyinNumeric,
    required this.meaningViSenses,
    required this.examples,
    required this.license,
    required this.attribution,
  });

  final DictionaryItem item;
  final String traditional;
  final String pinyinNumeric;
  final List<String> meaningViSenses;
  final List<Map<String, dynamic>> examples;
  final String license;
  final String attribution;

  factory DictionaryDetail.fromJson(Map<String, dynamic> json) =>
      DictionaryDetail(
        item: DictionaryItem.fromJson(json),
        traditional: json['traditional'] as String,
        pinyinNumeric: json['pinyinNumeric'] as String,
        meaningViSenses: List<String>.from(json['meaningViSenses'] as List),
        examples: List<Map<String, dynamic>>.from(
          (json['examples'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        ),
        license: json['license'] as String,
        attribution: json['attribution'] as String,
      );
}

abstract class DictionaryRepository {
  Future<List<DictionaryItem>> search(String query);
  Future<DictionaryDetail> detail(String vocabId);
}

class DictionaryApiException implements Exception {
  const DictionaryApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiDictionaryRepository implements DictionaryRepository {
  ApiDictionaryRepository(this._auth, this._client, this._baseUrl);

  final AuthRepository _auth;
  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> _get(Uri uri) async {
    if (_baseUrl.isEmpty) {
      throw const DictionaryApiException('Backend API chưa được cấu hình.');
    }
    var token = await _auth.getIdToken();
    var response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 401) {
      token = await _auth.getIdToken(forceRefresh: true);
      response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = payload['detail'];
      final message = detail is Map ? detail['message'] : null;
      throw DictionaryApiException(
        message is String ? message : 'Không thể tải dữ liệu từ điển.',
      );
    }
    return payload;
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${_baseUrl.replaceFirst(RegExp(r'/$'), '')}$path')
          .replace(queryParameters: query);

  @override
  Future<List<DictionaryItem>> search(String query) async {
    final payload = await _get(
      _uri('/api/v1/dictionary/search', {'q': query, 'limit': '20'}),
    );
    return (payload['items'] as List)
        .map((item) => DictionaryItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<DictionaryDetail> detail(String vocabId) async {
    final payload = await _get(
      _uri('/api/v1/dictionary/${Uri.encodeComponent(vocabId)}'),
    );
    return DictionaryDetail.fromJson(payload);
  }
}

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  const baseUrl = String.fromEnvironment('API_BASE_URL');
  final client = http.Client();
  ref.onDispose(client.close);
  return ApiDictionaryRepository(
    ref.watch(authRepositoryProvider),
    client,
    baseUrl,
  );
});
