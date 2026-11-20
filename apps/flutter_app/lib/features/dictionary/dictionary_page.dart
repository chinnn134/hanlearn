import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dictionary_repository.dart';

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});

  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends ConsumerState<DictionaryPage> {
  final _query = TextEditingController();
  List<DictionaryItem>? _items;
  DictionaryDetail? _detail;
  Object? _error;
  bool _loading = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _detail = null;
    });
    try {
      final items = await ref.read(dictionaryRepositoryProvider).search(query);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(DictionaryItem item) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(dictionaryRepositoryProvider)
          .detail(item.vocabId);
      if (mounted) setState(() => _detail = detail);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tra từ')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Nhập hoặc dán Hanzi/Pinyin',
                hintText: 'Ví dụ: 学习, xuéxí hoặc xue xi',
                suffixIcon: IconButton(
                  tooltip: 'Tra từ',
                  onPressed: _loading ? null : _search,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(
                'Không thể tra từ: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _search,
                  child: const Text('Thử lại'),
                ),
              ),
            ],
            if (!_loading &&
                _error == null &&
                _items != null &&
                _items!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('Không tìm thấy mục từ trong corpus hiện tại.'),
              ),
            if (_detail case final detail?) _DetailCard(detail: detail),
            if (_detail == null)
              for (final item in _items ?? const <DictionaryItem>[])
                Card(
                  child: ListTile(
                    title: Text('${item.hanzi}  ${item.pinyin}'),
                    subtitle: Text(item.meaningVi, maxLines: 2),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openDetail(item),
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.detail});
  final DictionaryDetail detail;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.item.hanzi,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          Text('Phồn thể: ${detail.traditional}'),
          Text('${detail.item.pinyin} · ${detail.pinyinNumeric}'),
          const Divider(),
          for (final sense in detail.meaningViSenses) Text('• $sense'),
          const SizedBox(height: 12),
          if (detail.examples.isEmpty)
            const Text('Chưa có ví dụ đã được xác minh cho mục từ này.'),
          const SizedBox(height: 12),
          Text(
            'Nguồn: OpenCidian · ${detail.license}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Xem ghi công đầy đủ'),
            children: [Text(detail.attribution)],
          ),
        ],
      ),
    ),
  );
}
