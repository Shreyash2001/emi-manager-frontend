import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_emi_manager/core/network/api_cache_manager.dart';

void main() {
  group('ApiCacheManager', () {
    late ApiCacheManager cacheManager;

    setUp(() {
      cacheManager = ApiCacheManager(
        defaultTtl: const Duration(minutes: 15),
      );
    });

    test('default TTL is 15 minutes', () {
      expect(cacheManager.ttl, equals(const Duration(minutes: 15)));
      expect(cacheManager.entryCount, equals(0));
    });

    test('returns null and increments miss count on cache miss', () {
      final result = cacheManager.get('/dashboard');
      expect(result, isNull);
      expect(cacheManager.cacheMisses, equals(1));
      expect(cacheManager.cacheHits, equals(0));
    });

    test('stores and retrieves data on cache hit within TTL', () {
      final sampleData = {'success': true, 'data': {'totalCustomers': 42}};

      cacheManager.put('/dashboard', sampleData);
      expect(cacheManager.hasValid('/dashboard'), isTrue);
      expect(cacheManager.entryCount, equals(1));

      final retrieved = cacheManager.get('/dashboard');
      expect(retrieved, equals(sampleData));
      expect(cacheManager.cacheHits, equals(1));
      expect(cacheManager.cacheMisses, equals(0));
    });

    test('generates normalized keys regardless of query parameter order', () {
      final key1 = cacheManager.generateKey('/customers', {'page': 1, 'limit': 20});
      final key2 = cacheManager.generateKey('/customers', {'limit': 20, 'page': 1});

      expect(key1, equals(key2));
      expect(key1, equals('/customers?limit=20&page=1'));
    });

    test('distinguishes different query parameters as separate cache entries', () {
      final key1 = cacheManager.generateKey('/customers', {'search': 'alice'});
      final key2 = cacheManager.generateKey('/customers', {'search': 'bob'});

      cacheManager.put(key1, {'results': ['alice']});
      cacheManager.put(key2, {'results': ['bob']});

      expect(cacheManager.get(key1), equals({'results': ['alice']}));
      expect(cacheManager.get(key2), equals({'results': ['bob']}));
      expect(cacheManager.entryCount, equals(2));
    });

    test('entry expires after TTL duration', () {
      final shortTtlCache = ApiCacheManager(
        defaultTtl: const Duration(milliseconds: 10),
      );

      shortTtlCache.put('/reports', {'revenue': 1000});
      expect(shortTtlCache.hasValid('/reports'), isTrue);

      // Wait for expiration
      return Future.delayed(const Duration(milliseconds: 25), () {
        expect(shortTtlCache.hasValid('/reports'), isFalse);
        expect(shortTtlCache.get('/reports'), isNull);
        expect(shortTtlCache.entryCount, equals(0));
      });
    });

    test('invalidateOnWriteTransaction clears all cached GET data', () {
      cacheManager.put('/dashboard', {'stat': 1});
      cacheManager.put('/customers', {'list': []});
      cacheManager.put('/reports/summary', {'sum': 100});
      expect(cacheManager.entryCount, equals(3));

      // Simulate a write transaction (e.g. customer created or payment recorded)
      cacheManager.invalidateOnWriteTransaction(
        operation: 'POST',
        path: '/payments',
      );

      expect(cacheManager.entryCount, equals(0));
      expect(cacheManager.get('/dashboard'), isNull);
      expect(cacheManager.get('/customers'), isNull);
      expect(cacheManager.get('/reports/summary'), isNull);
      expect(cacheManager.lastWriteOperation, equals('POST /payments'));
      expect(cacheManager.lastWriteTransactionAt, isNotNull);
    });

    test('invalidate removes specific endpoint or matching path prefixes', () {
      cacheManager.put('/customers', {'all': []});
      cacheManager.put('/customers?page=1', {'page1': []});
      cacheManager.put('/customers?page=2', {'page2': []});
      cacheManager.put('/dashboard', {'dash': 1});

      cacheManager.invalidate('/customers');

      expect(cacheManager.get('/customers'), isNull);
      expect(cacheManager.get('/customers?page=1'), isNull);
      expect(cacheManager.get('/customers?page=2'), isNull);
      expect(cacheManager.get('/dashboard'), isNotNull);
      expect(cacheManager.entryCount, equals(1));
    });

    test('clear wipes all entries and reset wipes entries + metrics', () {
      cacheManager.put('/test', {'ok': true});
      cacheManager.get('/test'); // 1 hit
      cacheManager.get('/nonexistent'); // 1 miss

      expect(cacheManager.cacheHits, equals(1));
      expect(cacheManager.cacheMisses, equals(1));

      cacheManager.reset();
      expect(cacheManager.entryCount, equals(0));
      expect(cacheManager.cacheHits, equals(0));
      expect(cacheManager.cacheMisses, equals(0));
    });
  });
}
