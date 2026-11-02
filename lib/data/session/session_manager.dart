import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/model/models.dart';
import '../../domain/repository/repositories.dart';
import '../local/token_storage.dart';

/// Owns the tokens: keeps them in memory for every request and mirrors them to [TokenStorage].
/// The memory copy is authoritative: a failing Keychain / Keystore only costs the session after a restart.
class SessionManager implements SessionRepository {
  SessionManager(this._storage);

  final TokenStorage _storage;
  final _changes = StreamController<SessionState>.broadcast();
  StoredTokens? _tokens;

  /// Loads the tokens saved by a previous launch; call once before the first request.
  /// Unreadable storage starts the app signed out instead of failing before the first frame.
  Future<void> restore() async {
    try {
      _tokens = await _storage.read();
    } catch (e) {
      debugPrint('Could not read the stored session: $e');
      _tokens = null;
      await _persist(_storage.clear);
    }
  }

  @override
  SessionState get session => _tokens == null ? SessionState.loggedOut : SessionState.loggedIn;

  @override
  Stream<SessionState> get sessionChanges => _changes.stream;

  StoredTokens? get currentTokens => _tokens;

  Future<void> start(StoredTokens tokens) async {
    final previous = session;
    _tokens = tokens;
    await _persist(() => _storage.save(tokens));
    _notifyIfChanged(previous);
  }

  Future<void> end() async {
    final previous = session;
    _tokens = null;
    await _persist(_storage.clear);
    _notifyIfChanged(previous);
  }

  void _notifyIfChanged(SessionState previous) {
    if (session != previous) _changes.add(session);
  }

  static Future<void> _persist(Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      debugPrint('Could not update the stored session: $e');
    }
  }
}
