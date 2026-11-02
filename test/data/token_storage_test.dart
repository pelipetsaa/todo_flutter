import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/data/local/reinstall_guard.dart';
import 'package:todo_flutter/data/local/token_storage.dart';

import '../support/fakes.dart';

class FakeInstallMarker implements InstallMarker {
  FakeInstallMarker({this.marked = false});

  bool marked;

  @override
  Future<bool> isSet() async => marked;

  @override
  Future<void> set() async => marked = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tokens = StoredTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
  const secure = FlutterSecureStorage();

  group('SecureTokenStorage', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('saves, reads and clears the pair as one value', () async {
      final storage = SecureTokenStorage();
      expect(await storage.read(), isNull);

      await storage.save(tokens);
      expect(await storage.read(), tokens);
      expect((await secure.readAll()).keys, ['auth.tokens']);

      await storage.clear();
      expect(await storage.read(), isNull);
      expect(await secure.readAll(), isEmpty);
    });

    test('moves the two values of 1.0.1 to the single one', () async {
      FlutterSecureStorage.setMockInitialValues({'auth.access_token': 'access-1', 'auth.refresh_token': 'refresh-1'});

      expect(await SecureTokenStorage().read(), tokens);
      expect((await secure.readAll()).keys, ['auth.tokens']);
    });

    test('a half-written legacy pair is no session', () async {
      FlutterSecureStorage.setMockInitialValues({'auth.access_token': 'access-1'});
      expect(await SecureTokenStorage().read(), isNull);
    });

    test('a corrupted value is no session', () async {
      FlutterSecureStorage.setMockInitialValues({'auth.tokens': 'not json'});
      expect(await SecureTokenStorage().read(), isNull);
      FlutterSecureStorage.setMockInitialValues({'auth.tokens': '{"accessToken": 1}'});
      expect(await SecureTokenStorage().read(), isNull);
    });
  });

  group('ReinstallGuard', () {
    test('drops the tokens left by a previous install', () async {
      final storage = InMemoryTokenStorage(tokens);
      final marker = FakeInstallMarker();

      await ReinstallGuard.clearTokensOfPreviousInstall(storage, marker);

      expect(storage.tokens, isNull);
      expect(marker.marked, isTrue);
    });

    test('keeps the tokens of this install', () async {
      final storage = InMemoryTokenStorage(tokens);

      await ReinstallGuard.clearTokensOfPreviousInstall(storage, FakeInstallMarker(marked: true));

      expect(storage.tokens, tokens);
    });
  });
}
