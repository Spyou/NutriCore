class LocalCache {
  final Map<String, _CacheEntry<dynamic>> _cache = {};
  static const Duration defaultTTL = Duration(minutes: 30);

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  void set<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = _CacheEntry(value, ttl ?? defaultTTL);
  }

  void invalidate(String key) => _cache.remove(key);

  void invalidateAll() => _cache.clear();
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  _CacheEntry(this.value, Duration ttl) : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
