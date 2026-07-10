import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/data/services/token_manager.dart';

import '../helpers/fake_token_storage.dart';

void main() {
  late FakeTokenStorage storage;
  late TokenManager tokenManager;

  setUp(() {
    storage = FakeTokenStorage();
    tokenManager = TokenManager(storage);
  });

  test('hasValidSession is false with no tokens stored', () async {
    expect(await tokenManager.hasValidSession, isFalse);
  });

  test('saveTokens persists access + refresh token + expiry', () async {
    await tokenManager.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );

    expect(await tokenManager.readAccessToken(), 'access-1');
    expect(await tokenManager.readRefreshToken(), 'refresh-1');
    expect(await tokenManager.hasValidSession, isTrue);
    expect(await tokenManager.isAccessTokenExpired(), isFalse);
  });

  test('isAccessTokenExpired is true once past the expiry timestamp', () async {
    await tokenManager.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    expect(await tokenManager.isAccessTokenExpired(), isTrue);
  });

  test('isAccessTokenExpired defaults to true when no expiry was recorded', () async {
    expect(await tokenManager.isAccessTokenExpired(), isTrue);
  });

  test('clear removes all stored tokens', () async {
    await tokenManager.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    await tokenManager.clear();

    expect(await tokenManager.readAccessToken(), isNull);
    expect(await tokenManager.readRefreshToken(), isNull);
    expect(await tokenManager.hasValidSession, isFalse);
  });
}
