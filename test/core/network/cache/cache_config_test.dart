import 'package:flutter_base/src/core/network/cache/cache_config.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(CacheConfig.init);

  setUp(CacheConfig.clearAll);

  test('global cache policy is off and never masks auth failures', () {
    final options = CacheConfig.defaultOptions;

    expect(options.policy, CachePolicy.noCache);
    expect(
      options.hitCacheOnErrorCodes,
      isNot(anyOf(contains(401), contains(403))),
    );
    expect(options.allowPostMethod, isFalse);
  });

  test('opt-in keys isolate users and localized responses', () {
    final userOne = CacheConfig.requestOptions(scope: 'user:1');
    final userTwo = CacheConfig.requestOptions(scope: 'user:2');

    String key(CacheOptions options, String locale) => options.keyBuilder(
      url: Uri.parse('https://api.example.com/profile'),
      headers: <String, String>{'Accept-Language': locale},
    );

    final userOneArabic = key(userOne, 'ar');

    expect(userOneArabic, key(userOne, 'ar'));
    expect(userOneArabic, isNot(key(userOne, 'en')));
    expect(userOneArabic, isNot(key(userTwo, 'ar')));
  });

  test('empty cache scope is rejected', () {
    expect(() => CacheConfig.requestOptions(scope: '   '), throwsArgumentError);
  });

  test('clearAll removes responses at a session boundary', () async {
    final now = DateTime.now();
    const key = 'session-response';

    await CacheConfig.store.set(
      CacheResponse(
        cacheControl: CacheControl(),
        content: const <int>[],
        date: now,
        eTag: null,
        expires: null,
        headers: null,
        key: key,
        lastModified: null,
        maxStale: now.add(const Duration(minutes: 15)),
        priority: CachePriority.normal,
        requestDate: now,
        responseDate: now,
        url: 'https://api.example.com/profile',
        statusCode: 200,
      ),
    );

    expect(await CacheConfig.store.exists(key), isTrue);

    await CacheConfig.clearAll();

    expect(await CacheConfig.store.exists(key), isFalse);
  });
}
