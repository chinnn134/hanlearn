import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static late final FirebaseApp app;
  static FirebaseAuth get auth => FirebaseAuth.instanceFor(app: app);
  static FirebaseFirestore get firestore =>
      FirebaseFirestore.instanceFor(app: app);

  static const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );

  static bool get hasProjectConfig =>
      projectId.isNotEmpty &&
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      (!kIsWeb || authDomain.isNotEmpty);

  static Future<void> initialize() async {
    if (useEmulator) {
      app = await Firebase.initializeApp(
        name: '[DEFAULT]',
        demoProjectId: 'demo-hanlearn',
      );
      final host = kIsWeb ? 'localhost' : '10.0.2.2';
      await auth.useAuthEmulator(host, 9099);
      firestore.useFirestoreEmulator(host, 8080);
      return;
    }

    if (!hasProjectConfig) {
      throw const FormatException(
        'Thiếu cấu hình Firebase Web/Android. Xem README Phase 02.',
      );
    }
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('HanLearn chỉ hỗ trợ Flutter Web và Android.');
    }

    app = await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: kIsWeb && authDomain.isNotEmpty ? authDomain : null,
      ),
    );
  }
}
