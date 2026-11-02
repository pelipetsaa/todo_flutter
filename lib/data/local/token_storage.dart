import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredTokens extends Equatable {
  const StoredTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

abstract interface class TokenStorage {
  Future<StoredTokens?> read();
  Future<void> save(StoredTokens tokens);
  Future<void> clear();
}

/// Keychain on iOS, encrypted shared preferences on Android.
/// The pair is one value, so that it is never stored half-updated.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  static const _key = 'auth.tokens';

  // Up to 1.0.1 the tokens were two separate values; [read] moves them to [_key].
  static const _legacyAccessKey = 'auth.access_token';
  static const _legacyRefreshKey = 'auth.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredTokens?> read() async {
    final value = await _storage.read(key: _key);
    if (value != null) return _decode(value);
    final access = await _storage.read(key: _legacyAccessKey);
    final refresh = await _storage.read(key: _legacyRefreshKey);
    if (access == null || refresh == null) return null;
    final tokens = StoredTokens(accessToken: access, refreshToken: refresh);
    await save(tokens);
    return tokens;
  }

  @override
  Future<void> save(StoredTokens tokens) async {
    await _storage.write(
      key: _key,
      value: jsonEncode({'accessToken': tokens.accessToken, 'refreshToken': tokens.refreshToken}),
    );
    await _deleteLegacy();
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _deleteLegacy();
  }

  Future<void> _deleteLegacy() async {
    await _storage.delete(key: _legacyAccessKey);
    await _storage.delete(key: _legacyRefreshKey);
  }

  static StoredTokens? _decode(String value) {
    try {
      final json = jsonDecode(value);
      if (json case {'accessToken': final String access, 'refreshToken': final String refresh}) {
        return StoredTokens(accessToken: access, refreshToken: refresh);
      }
    } on FormatException {
      // Treated like a missing session below.
    }
    return null;
  }
}
