import 'dart:convert';

import 'package:flutter_app/features/auth/auth_session.dart';
import 'package:flutter_app/features/dictionary/dictionary_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class TokenAuthRepository implements AuthRepository {
  @override
  Stream<AuthIdentity?> authStateChanges() => const Stream.empty();
  @override
  Future<String> getIdToken() async => 'firebase-token';
  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}
  @override
  Future<void> signOut() async {}
}

void main() {
  test(
    'API repository sends Firebase token and decodes search results',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer firebase-token');
        expect(request.url.queryParameters['q'], '学习');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'vocabId': 'ocd-test',
                'hanzi': '学习',
                'pinyin': 'xué xí',
                'meaningVi': 'học tập',
                'levels': {'hsk3': 1},
                'sourceId': 'opencidian-17873f1',
              },
            ],
            'nextCursor': null,
            'request_id': 'test',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = ApiDictionaryRepository(
        TokenAuthRepository(),
        client,
        'https://api.example',
      );

      final items = await repository.search('学习');

      expect(items.single.hanzi, '学习');
      expect(items.single.meaningVi, 'học tập');
    },
  );
}
