import 'package:mobile_emi_manager/core/utils/logger.dart';

/// Represents a single cached HTTP response entry.
class CacheEntry {
  /// The raw response data payload (typically [Map<String, dynamic>]).
  final dynamic data;

  /// The timestamp when this entry was created or refreshed.
  final DateTime createdAt;

  /// Time-To-Live duration for this cache entry.
  final Duration ttl;

  const CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttl,
  });

  /// Returns true if the cache entry has exceeded its time-to-live.
  bool get isExpired => DateTime.now().isAfter(createdAt.add(ttl));

  /// Age of this cache entry since creation.
  Duration get age => DateTime.now().difference(createdAt);
}

/// Centralized in-memory cache manager for API GET requests.
///
/// Features:
/// - Default TTL of 15 minutes.
/// - Deterministic cache key generation including sorted query parameters.
/// - Automatic invalidation on write transactions (POST, PUT, PATCH, DELETE).
/// - Manual invalidation for targeted endpoints or full cache clearing.
/// - Metrics tracking for cache hits and misses.
class ApiCacheManager {
  /// Default TTL for cached responses: 15 minutes.
  static const Duration defaultTtl = Duration(minutes: 15);

  final Duration _defaultTtl;
  final Map<String, CacheEntry> _cache = <String, CacheEntry>{};

  DateTime? _lastWriteTransactionAt;
  String? _lastWriteOperation;
  int _cacheHits = 0;
  int _cacheMisses = 0;

  ApiCacheManager({Duration defaultTtl = defaultTtl})
      : _defaultTtl = defaultTtl;

  /// The configured default TTL duration (15 minutes by default).
  Duration get ttl => _defaultTtl;

  /// The number of currently cached entries.
  int get entryCount => _cache.length;

  /// Timestamp of the most recent write transaction that invalidated the cache.
  DateTime? get lastWriteTransactionAt => _lastWriteTransactionAt;

  /// Name of the most recent write operation (e.g. 'POST /api/v1/customers').
  String? get lastWriteOperation => _lastWriteOperation;

  /// Total count of successful cache hits.
  int get cacheHits => _cacheHits;

  /// Total count of cache misses.
  int get cacheMisses => _cacheMisses;

  /// Generates a normalized cache key from an endpoint path and query parameters.
  String generateKey(String path, [Map<String, dynamic>? queryParameters]) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return path;
    }

    final sortedKeys = queryParameters.keys.toList()..sort();
    final queryString = sortedKeys.map((key) {
      final value = queryParameters[key];
      final encodedValue = value != null ? Uri.encodeComponent(value.toString()) : '';
      return '$key=$encodedValue';
    }).join('&');

    return '$path?$queryString';
  }

  /// Retrieves a cached response if present and unexpired.
  /// Returns `null` on cache miss or if the entry has expired.
  dynamic get(String key) {
    final entry = _cache[key];
    if (entry == null) {
      _cacheMisses++;
      return null;
    }

    if (entry.isExpired) {
      AppLogger.network(
        '⏱️ [CACHE EXPIRED] $key (Age: ${entry.age.inMinutes}m, TTL: ${entry.ttl.inMinutes}m)',
      );
      _cache.remove(key);
      _cacheMisses++;
      return null;
    }

    _cacheHits++;
    AppLogger.network(
      '⚡ [CACHE HIT] $key (Age: ${entry.age.inSeconds}s, Total Hits: $_cacheHits)',
    );
    return entry.data;
  }

  /// Stores response data in the cache with the given or default TTL.
  void put(String key, dynamic data, {Duration? ttl}) {
    final effectiveTtl = ttl ?? _defaultTtl;
    _cache[key] = CacheEntry(
      data: data,
      createdAt: DateTime.now(),
      ttl: effectiveTtl,
    );
    AppLogger.network(
      '💾 [CACHE STORED] $key (TTL: ${effectiveTtl.inMinutes}m, Entries: ${_cache.length})',
    );
  }

  /// Checks if a valid, unexpired cache entry exists for [key].
  bool hasValid(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Invalidates the cache when any write transaction (POST, PUT, PATCH, DELETE) occurs.
  ///
  /// This ensures that no stale data remains in the cache across any feature
  /// in the app once a write has succeeded.
  void invalidateOnWriteTransaction({String? operation, String? path}) {
    _lastWriteTransactionAt = DateTime.now();
    _lastWriteOperation = operation != null && path != null ? '$operation $path' : operation ?? path;
    final clearedCount = _cache.length;
    _cache.clear();

    AppLogger.network(
      '🧹 [CACHE INVALIDATED] Write transaction detected (${_lastWriteOperation ?? "MUTATING ACTION"}). '
      'Cleared $clearedCount cached entries.',
    );
  }

  /// Invalidates entries matching a specific endpoint path or prefix.
  void invalidate(String pathOrPrefix) {
    final keysToRemove = _cache.keys
        .where((k) => k == pathOrPrefix || k.startsWith('$pathOrPrefix?') || k.startsWith(pathOrPrefix))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    AppLogger.network(
      '🧹 [CACHE INVALIDATED] Removed ${keysToRemove.length} entries matching "$pathOrPrefix".',
    );
  }

  /// Completely clears all cached data (e.g. on user logout).
  void clear() {
    final clearedCount = _cache.length;
    _cache.clear();
    AppLogger.network('🧹 [CACHE CLEARED] Cleared all $clearedCount cached entries.');
  }

  /// Resets hit/miss metrics and clear all cache.
  void reset() {
    _cache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _lastWriteTransactionAt = null;
    _lastWriteOperation = null;
  }
}
