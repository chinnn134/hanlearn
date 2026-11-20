import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repository = ref.read(authRepositoryProvider);
    try {
      final email = _email.text.trim();
      if (_register) {
        await repository.register(email: email, password: _password.text);
      } else {
        await repository.signIn(email: email, password: _password.text);
      }
    } on FirebaseAuthException catch (failure) {
      if (mounted) setState(() => _error = authErrorMessage(failure.code));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể kết nối. Kiểm tra mạng và thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Tạo tài khoản' : 'Đăng nhập')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'HanLearn AI',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return email.contains('@') && email.length <= 254
                              ? null
                              : 'Nhập địa chỉ email hợp lệ.';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: [
                          _register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                        ),
                        validator: (value) => (value?.length ?? 0) >= 6
                            ? null
                            : 'Mật khẩu cần ít nhất 6 ký tự.',
                        onFieldSubmitted: (_) => _busy ? null : _submit(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: Text(
                            _busy
                                ? 'Đang xử lý...'
                                : _register
                                ? 'Tạo tài khoản'
                                : 'Đăng nhập',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _register = !_register;
                                _error = null;
                              }),
                        child: Text(
                          _register
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Tạo mới',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String authErrorMessage(String code) => switch (code) {
  'invalid-email' => 'Địa chỉ email không hợp lệ.',
  'email-already-in-use' => 'Email này đã được đăng ký.',
  'weak-password' => 'Mật khẩu quá yếu.',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' => 'Email hoặc mật khẩu không đúng.',
  'too-many-requests' => 'Thử quá nhiều lần. Vui lòng đợi rồi thử lại.',
  'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
  'operation-not-allowed' => 'Phương thức đăng nhập chưa được bật.',
  _ => 'Không thể đăng nhập. Vui lòng thử lại.',
};
