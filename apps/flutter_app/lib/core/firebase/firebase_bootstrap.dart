import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  static late final FirebaseApp app;
  static FirebaseAuth get auth => FirebaseAuth.instanceFor(app: app);
  static FirebaseFirestore get firestore =>
      FirebaseFirestore.instanceFor(app: app);

  static const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

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

    app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
