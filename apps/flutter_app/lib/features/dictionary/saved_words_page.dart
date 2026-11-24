import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/confirm_action.dart';
import '../auth/auth_session.dart';
import 'dictionary_repository.dart';
import 'saved_word_repository.dart';

class SavedWordsPage extends ConsumerStatefulWidget {
  const SavedWordsPage({super.key});

  @override
  ConsumerState<SavedWordsPage> createState() => _SavedWordsPageState();
}

class _SavedWordsPageState extends ConsumerState<SavedWordsPage> {
  List<DictionaryDetail>? _items;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = null;
    });
    try {
      final uid = ref.read(authSessionProvider).identity!.uid;
      final saved = await ref.read(savedWordRepositoryProvider).list(uid);
      final details = await Future.wait(
        saved.map(
          (word) => ref.read(dictionaryRepositoryProvider).detail(word.vocabId),
        ),
      );
      if (mounted) setState(() => _items = details);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _remove(DictionaryDetail detail) async {
    final confirmed = await confirmAction(
      context,
      title: 'Bỏ lưu ${detail.item.hanzi}?',
      message: 'Từ sẽ bị xóa khỏi danh sách đã lưu. Lịch ôn và kết quả Quiz đã ghi vẫn được giữ.',
      confirmLabel: 'Bỏ lưu',
    );
    if (!confirmed || !mounted) return;
    try {
      final uid = ref.read(authSessionProvider).identity!.uid;
      await ref
          .read(savedWordRepositoryProvider)
          .remove(uid, detail.item.vocabId);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Từ đã lưu')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Không thể tải từ đã lưu: $_error'),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ],
                ),
              )
            : _items == null
            ? const Center(child: CircularProgressIndicator())
            : _items!.isEmpty
            ? const Center(child: Text('Bạn chưa lưu từ nào.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items!.length,
                itemBuilder: (context, index) {
                  final detail = _items![index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${detail.item.hanzi}  ${detail.item.pinyin}',
                      ),
                      subtitle: Text(detail.item.meaningVi),
                      trailing: IconButton(
                        tooltip: 'Bỏ lưu ${detail.item.hanzi}',
                        onPressed: () => _remove(detail),
                        icon: const Icon(Icons.bookmark_remove_outlined),
                      ),
                    ),
                  );
                },
              ),
      ),
    ),
  );
}
