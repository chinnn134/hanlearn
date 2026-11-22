import 'dart:convert';

import 'package:flutter_app/features/auth/auth_session.dart';
import 'package:flutter_app/features/dictionary/dictionary_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class TokenAuthRepository implements AuthRepository {
  final requests = <bool>[];

  @override
  Stream<AuthIdentity?> authStateChanges() => const Stream.empty();
  @override
  Future<String> getIdToken({bool forceRefresh = false}) async {
    requests.add(forceRefresh);
    return forceRefresh ? 'refreshed-token' : 'firebase-token';
  }

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

  test('API repository refreshes an expired token once after 401', () async {
    final auth = TokenAuthRepository();
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) {
        expect(request.headers['authorization'], 'Bearer firebase-token');
        return http.Response(
          jsonEncode({
            'detail': {'message': 'Firebase ID token không hợp lệ.'},
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      }
      expect(request.headers['authorization'], 'Bearer refreshed-token');
      return http.Response(
        jsonEncode({
          'items': <Map<String, dynamic>>[],
          'nextCursor': null,
          'request_id': 'retry',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiDictionaryRepository(
      auth,
      client,
      'https://api.example',
    );

    final items = await repository.search('学习');

    expect(items, isEmpty);
    expect(calls, 2);
    expect(auth.requests, [false, true]);
  });

  test(
    'API repository does not retry a second unauthorized response',
    () async {
      final auth = TokenAuthRepository();
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({
            'detail': {'message': 'Phiên đăng nhập đã hết hạn.'},
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = ApiDictionaryRepository(
        auth,
        client,
        'https://api.example',
      );

      await expectLater(
        repository.search('学习'),
        throwsA(
          isA<DictionaryApiException>().having(
            (error) => error.message,
            'message',
            'Phiên đăng nhập đã hết hạn.',
          ),
        ),
      );

      expect(calls, 2);
      expect(auth.requests, [false, true]);
    },
  );

  test(
    'API repository fails before token access when backend is missing',
    () async {
      final auth = TokenAuthRepository();
      final repository = ApiDictionaryRepository(
        auth,
        MockClient((_) async => http.Response('{}', 200)),
        '',
      );

      await expectLater(
        repository.search('学习'),
        throwsA(
          isA<DictionaryApiException>().having(
            (error) => error.message,
            'message',
            'Backend API chưa được cấu hình.',
          ),
        ),
      );
      expect(auth.requests, isEmpty);
    },
  );

  test('API repository hides low-level network details', () async {
    final repository = ApiDictionaryRepository(
      TokenAuthRepository(),
      MockClient((request) async {
        throw http.ClientException(
          'SocketException: Network is unreachable, uri=${request.url}',
          request.url,
        );
      }),
      'http://10.0.2.2:8000',
    );

    await expectLater(
      repository.search('xue'),
      throwsA(
        isA<DictionaryApiException>().having(
          (error) => error.message,
          'message',
          'Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.',
        ),
      ),
    );
  });
}
