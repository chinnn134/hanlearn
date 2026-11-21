import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final identity = session.identity;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Cài đặt', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        _SettingsSection(
          title: 'Tài khoản và dữ liệu',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email đăng nhập'),
              subtitle: Text(identity?.email ?? 'Không có email'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fingerprint),
              title: const Text('UID dữ liệu'),
              subtitle: Text(identity?.uid ?? 'Không có phiên đăng nhập'),
            ),
            const Text(
              'Saved Words, lịch ôn và kết quả Quiz được tách riêng theo UID này.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SettingsSection(
          title: 'Cấu hình bản core',
          children: [
            _StatusTile(
              icon: Icons.dns_outlined,
              title: 'Backend từ điển',
              status: _apiBaseUrl.isEmpty ? 'Chưa cấu hình' : 'Đã cấu hình',
              detail: _apiBaseUrl.isEmpty
                  ? 'Truyền API_BASE_URL khi build hoặc run.'
                  : _apiBaseUrl,
              ready: _apiBaseUrl.isNotEmpty,
            ),
            const _StatusTile(
              icon: Icons.document_scanner_outlined,
              title: 'OCR',
              status: 'Chưa tích hợp',
              detail: 'Sẽ dùng service thật qua backend ở Phase 09.',
              ready: false,
            ),
            const _StatusTile(
              icon: Icons.auto_awesome_outlined,
              title: 'AI giải thích',
              status: 'Chưa tích hợp',
              detail: 'API key chỉ được cấu hình ở backend trong Phase 10.',
              ready: false,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SettingsSection(
          title: 'Quyền riêng tư',
          children: [
            Text(
              'Ứng dụng bản core không tải ảnh lên vì OCR chưa được tích hợp. '
              'Không lưu API key trong ứng dụng hoặc repository.',
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.status,
    required this.detail,
    required this.ready,
  });

  final IconData icon;
  final String title;
  final String status;
  final String detail;
  final bool ready;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(detail),
    trailing: Semantics(
      label: '$title: $status',
      child: Chip(
        avatar: Icon(
          ready ? Icons.check_circle_outline : Icons.info_outline,
          size: 18,
        ),
        label: Text(status),
      ),
    ),
  );
}
