import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/auth_session.dart';
import '../../features/auth/profile_page.dart';
import '../../features/home/home_page.dart';
import '../widgets/app_shell.dart';
import '../widgets/feature_placeholder_page.dart';
import '../widgets/state_panel.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!session.ready) {
        return path == '/auth-loading' ? null : '/auth-loading';
      }
      if (session.error != null) {
        return path == '/auth-error' ? null : '/auth-error';
      }
      if (session.identity == null) {
        return path == '/login' ? null : '/login';
      }
      if (path == '/login' ||
          path == '/auth-loading' ||
          path == '/auth-error') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth-loading',
        builder: (context, state) => const Scaffold(
          body: StatePanel(
            state: ViewState.loading,
            title: 'Đang kiểm tra phiên đăng nhập',
            message: 'Vui lòng đợi trong giây lát.',
          ),
        ),
      ),
      GoRoute(
        path: '/auth-error',
        builder: (context, state) => Scaffold(
          body: StatePanel(
            state: ViewState.error,
            title: 'Không thể kiểm tra phiên đăng nhập',
            message: 'Kiểm tra kết nối mạng rồi thử lại.',
            onRetry: session.retry,
          ),
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(currentPath: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/dictionary',
            builder: (context, state) => const FeaturePlaceholderPage(
              title: 'Tra từ',
              phase: 'Phase 03',
              description: 'Tra Hanzi/Pinyin và xem nghĩa tiếng Việt có nguồn.',
            ),
          ),
          GoRoute(
            path: '/saved-words',
            builder: (context, state) => const FeaturePlaceholderPage(
              title: 'Từ đã lưu',
              phase: 'Phase 03',
              description: 'Quản lý danh sách từ của tài khoản.',
            ),
          ),
          GoRoute(
            path: '/flashcards',
            builder: (context, state) => const FeaturePlaceholderPage(
              title: 'Flashcard',
              phase: 'Phase 04',
              description: 'Học từ đã lưu và đánh giá mức độ nhớ.',
            ),
          ),
          GoRoute(
            path: '/quiz',
            builder: (context, state) => const FeaturePlaceholderPage(
              title: 'Quiz',
              phase: 'Phase 04',
              description: 'Làm câu hỏi từ tập từ đã lưu.',
            ),
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) => const FeaturePlaceholderPage(
              title: 'Tiến độ',
              phase: 'Phase 05',
              description: 'Xem lịch ôn, kết quả Quiz và tiến độ học.',
            ),
          ),
          GoRoute(
            path: '/scanner',
            builder: (context, state) => const FeaturePlaceholderPage(
              title: 'Scanner',
              phase: 'Phase 06 và Phase 09',
              description:
                  'Chọn ảnh sẽ có ở Phase 06. OCR thật chưa được cấu hình.',
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy trang')),
      body: Center(child: Text('Đường dẫn không hợp lệ: ${state.uri.path}')),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
