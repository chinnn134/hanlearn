class SyncSnapshot<T> {
  const SyncSnapshot({
    required this.items,
    required this.isFromCache,
    required this.readLimit,
  });

  final List<T> items;
  final bool isFromCache;
  final int readLimit;

  bool get mayHaveMore => items.length >= readLimit;
}
