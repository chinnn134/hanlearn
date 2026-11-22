import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'image_selection_service.dart';

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final _manualText = TextEditingController();
  SelectedImage? _image;
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _manualText.dispose();
    super.dispose();
  }

  void _openDictionary() {
    final text = _manualText.text.trim();
    if (text.isEmpty) return;
    context.go(
      Uri(path: '/dictionary', queryParameters: {'q': text}).toString(),
    );
  }

  Future<void> _pick(ImageSelectionSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await ref.read(imageSelectionServiceProvider).pick(source);
      if (image != null && mounted) setState(() => _image = image);
    } on ImageSelectionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể mở bộ chọn ảnh. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scanner')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Chuẩn bị ảnh chữ Hán',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ảnh chỉ được preview trên thiết bị ở Phase 06. OCR chưa được cấu hình và không có dữ liệu nào được gửi lên service.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _pick(ImageSelectionSource.gallery),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(kIsWeb ? 'Chọn ảnh từ máy' : 'Chọn từ thư viện'),
                ),
                if (!kIsWeb)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _pick(ImageSelectionSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Chụp bằng camera'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Định dạng: JPEG/PNG/WebP · tối đa 8 MiB và 20 MP.'),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_image case final image?) ...[
              const SizedBox(height: 20),
              Semantics(
                label: 'Ảnh đã chọn để preview',
                image: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: Image.memory(
                      image.bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${image.fileName} · ${image.width}×${image.height} · '
                '${(image.bytes.length / 1024).toStringAsFixed(1)} KiB',
              ),
              const SizedBox(height: 8),
              const Text(
                'Codec Flutter áp dụng hướng EXIF khi preview. Metadata và ảnh không được lưu lâu dài trong Phase 06.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Nhận dạng — OCR chưa được cấu hình'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Nhập và xác nhận văn bản',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'OCR chưa được cấu hình. Nội dung dưới đây do bạn nhập thủ công, không phải kết quả nhận dạng từ ảnh.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualText,
              minLines: 2,
              maxLines: 5,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _openDictionary(),
              decoration: const InputDecoration(
                labelText: 'Văn bản thủ công',
                hintText: 'Nhập hoặc dán chữ Hán cần tra, ví dụ: 学习',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _manualText.text.trim().isEmpty
                    ? null
                    : _openDictionary,
                icon: const Icon(Icons.manage_search_outlined),
                label: const Text('Tra văn bản đã xác nhận'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
