import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile_emi_manager/app/config/app_config.dart';
import 'package:mobile_emi_manager/core/network/api_cache_manager.dart';
import 'package:mobile_emi_manager/core/network/api_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('ApiClient Caching & Invalidation', () {
    late MockDio mockDio;
    late AppConfig appConfig;
    late ApiCacheManager cacheManager;
    late ApiClient apiClient;

    setUp(() {
      mockDio = MockDio();
      appConfig = const AppConfig(
        environment: Environment.development,
        apiBaseUrl: 'https://example.com/api/v1',
        appName: 'EMI Manager',
        enableLogging: false,
        requestTimeout: Duration(seconds: 5),
        connectTimeout: Duration(seconds: 5),
        cacheTtl: Duration(minutes: 15),
      );
      cacheManager = ApiCacheManager(defaultTtl: const Duration(minutes: 15));
      apiClient = ApiClient(
        config: appConfig,
        dio: mockDio,
        cacheManager: cacheManager,
      );
    });

    test('GET request calls Dio on initial fetch and caches the response', () async {
      when(() => mockDio.get(
            '/dashboard',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/dashboard'),
          statusCode: 200,
          data: {
            'success': true,
            'message': 'OK',
            'data': {'totalCustomers': 10},
          },
        ),
      );

      final res1 = await apiClient.get<Map<String, dynamic>>(
        '/dashboard',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(res1.success, isTrue);
      expect(res1.data?['totalCustomers'], equals(10));
      verify(() => mockDio.get(
            '/dashboard',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
      expect(cacheManager.hasValid('/dashboard'), isTrue);

      // Second GET request should hit the cache without calling Dio
      final res2 = await apiClient.get<Map<String, dynamic>>(
        '/dashboard',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(res2.success, isTrue);
      expect(res2.data?['totalCustomers'], equals(10));
      // Dio.get should STILL have only been called once!
      verifyNever(() => mockDio.get(
            '/dashboard',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          ));
      expect(cacheManager.cacheHits, equals(1));
    });

    test('GET request with forceRefresh=true bypasses cache and updates it', () async {
      when(() => mockDio.get(
            '/dashboard',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/dashboard'),
          statusCode: 200,
          data: {
            'success': true,
            'message': 'OK',
            'data': {'totalCustomers': 20},
          },
        ),
      );

      // Populate cache initially
      cacheManager.put('/dashboard', {
        'success': true,
        'data': {'totalCustomers': 5},
      });

      final res = await apiClient.get<Map<String, dynamic>>(
        '/dashboard',
        forceRefresh: true,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(res.data?['totalCustomers'], equals(20));
      verify(() => mockDio.get(
            '/dashboard',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('POST write transaction invalidates cached GET data', () async {
      // 1. Populate cache with customer data
      cacheManager.put('/customers', {
        'success': true,
        'data': {'items': []},
      });
      cacheManager.put('/dashboard', {
        'success': true,
        'data': {'totalCustomers': 1},
      });
      expect(cacheManager.entryCount, equals(2));

      // 2. Mock a POST write transaction
      when(() => mockDio.post(
            '/customers',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/customers'),
          statusCode: 201,
          data: {
            'success': true,
            'message': 'Customer created',
            'data': {'id': 'cust-123'},
          },
        ),
      );

      final postRes = await apiClient.post<Map<String, dynamic>>(
        '/customers',
        data: {'name': 'John'},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(postRes.success, isTrue);
      // All cache entries should now be invalidated!
      expect(cacheManager.entryCount, equals(0));
      expect(cacheManager.hasValid('/customers'), isFalse);
      expect(cacheManager.hasValid('/dashboard'), isFalse);
      expect(cacheManager.lastWriteOperation, equals('POST /customers'));
    });

    test('After write transaction invalidation, subsequent GET hits network again', () async {
      // Step 1: Preload cache
      cacheManager.put('/customers', {
        'success': true,
        'data': {'items': ['Alice']},
      });

      // Step 2: Trigger write transaction (Record Payment)
      when(() => mockDio.post(
            '/payments',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments'),
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Payment recorded',
            'data': {'id': 'pay-1'},
          },
        ),
      );

      await apiClient.post('/payments', data: {'amount': 1500});
      expect(cacheManager.entryCount, equals(0));

      // Step 3: GET customers should now make a network call
      when(() => mockDio.get(
            '/customers',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/customers'),
          statusCode: 200,
          data: {
            'success': true,
            'message': 'OK',
            'data': {'items': ['Alice', 'Bob']},
          },
        ),
      );

      final getRes = await apiClient.get<Map<String, dynamic>>(
        '/customers',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(getRes.data?['items'], equals(['Alice', 'Bob']));
      verify(() => mockDio.get(
            '/customers',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('Concurrent simultaneous GET requests join the same in-flight request (exactly 1 Dio call)', () async {
      when(() => mockDio.get(
            '/dashboard',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return Response(
            requestOptions: RequestOptions(path: '/dashboard'),
            statusCode: 200,
            data: {
              'success': true,
              'message': 'OK',
              'data': {'totalCustomers': 99},
            },
          );
        },
      );

      // Fire 3 simultaneous GET requests
      final future1 = apiClient.get<Map<String, dynamic>>(
        '/dashboard',
        fromJson: (json) => json as Map<String, dynamic>,
      );
      final future2 = apiClient.get<Map<String, dynamic>>(
        '/dashboard',
        fromJson: (json) => json as Map<String, dynamic>,
      );
      final future3 = apiClient.get<Map<String, dynamic>>(
        '/dashboard',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final results = await Future.wait([future1, future2, future3]);

      expect(results[0].data?['totalCustomers'], equals(99));
      expect(results[1].data?['totalCustomers'], equals(99));
      expect(results[2].data?['totalCustomers'], equals(99));

      // Dio must only have been invoked EXACTLY once!
      verify(() => mockDio.get(
            '/dashboard',
            queryParameters: any(named: 'queryParameters'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });
}
