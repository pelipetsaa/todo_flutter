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
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  static const _keyAccess = 'auth.access_token';
  static const _keyRefresh = 'auth.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredTokens?> read() async {
    final access = await _storage.read(key: _keyAccess);
    final refresh = await _storage.read(key: _keyRefresh);
    if (access == null || refresh == null) return null;
    return StoredTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> save(StoredTokens tokens) async {
    await _storage.write(key: _keyAccess, value: tokens.accessToken);
    await _storage.write(key: _keyRefresh, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
  }
}
