import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _busy = false;
  String? _error;

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on FirebaseAuthException {
      if (mounted) setState(() => _error = 'Không thể đăng xuất. Thử lại.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể đăng xuất. Thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(authSessionProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Tài khoản', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(session.identity?.email ?? 'Tài khoản không có email'),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _busy ? null : _signOut,
            icon: const Icon(Icons.logout),
            label: Text(_busy ? 'Đang đăng xuất...' : 'Đăng xuất'),
          ),
        ),
      ],
    );
  }
}
