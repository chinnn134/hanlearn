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

  Future<void> _editName(AuthSessionController session) async {
    var editedName = session.profile?.displayName ?? '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tên hiển thị'),
        content: TextFormField(
          initialValue: editedName,
          onChanged: (value) => editedName = value,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Tên hiển thị'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, editedName),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.updateDisplayName(name);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể lưu tên. Kiểm tra tên và thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Tài khoản', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(session.identity?.email ?? 'Tài khoản không có email'),
          const SizedBox(height: 16),
          if (session.profileLoading)
            const Text('Đang tải hồ sơ...')
          else if (session.profileError != null) ...[
            const Text('Không thể tải hồ sơ.'),
            TextButton(
              onPressed: session.retryProfile,
              child: const Text('Thử lại'),
            ),
          ] else if (session.profile != null) ...[
            Text('Tên hiển thị: ${session.profile!.displayName}'),
            TextButton(
              onPressed: _busy ? null : () => _editName(session),
              child: const Text('Sửa tên hiển thị'),
            ),
          ],
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
              label: Text(_busy ? 'Đang xử lý...' : 'Đăng xuất'),
            ),
          ),
        ],
      ),
    );
  }
}
