import 'package:shared_preferences/shared_preferences.dart';

import 'token_storage.dart';

/// A flag that is deleted together with the app, unlike Keychain items on iOS.
abstract interface class InstallMarker {
  Future<bool> isSet();
  Future<void> set();
}

class PreferencesInstallMarker implements InstallMarker {
  PreferencesInstallMarker([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'install.marker';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isSet() async => await _preferences.getBool(_key) ?? false;

  @override
  Future<void> set() => _preferences.setBool(_key, true);
}

/// iOS keeps Keychain items after the app is deleted, so a reinstalled app would open signed in with the tokens of
/// the previous install. Without [InstallMarker] this is the first launch of an install: the old tokens are dropped.
/// Updating from 1.0.1, which had no marker, signs the user out once.
abstract final class ReinstallGuard {
  static Future<void> clearTokensOfPreviousInstall(TokenStorage storage, InstallMarker marker) async {
    if (await marker.isSet()) return;
    await storage.clear();
    await marker.set();
  }
}
