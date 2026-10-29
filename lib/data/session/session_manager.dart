import 'dart:async';

import '../../domain/model/models.dart';
import '../../domain/repository/repositories.dart';
import '../local/token_storage.dart';

/// Owns the tokens: keeps them in memory for every request and mirrors them to [TokenStorage].
class SessionManager implements SessionRepository {
  SessionManager(this._storage);

  final TokenStorage _storage;
  final _changes = StreamController<SessionState>.broadcast();
  StoredTokens? _tokens;

  /// Loads the tokens saved by a previous launch; call once before the first request.
  Future<void> restore() async {
    _tokens = await _storage.read();
  }

  @override
  SessionState get session => _tokens == null ? SessionState.loggedOut : SessionState.loggedIn;

  @override
  Stream<SessionState> get sessionChanges => _changes.stream;

  StoredTokens? get currentTokens => _tokens;

  Future<void> start(StoredTokens tokens) async {
    final previous = session;
    _tokens = tokens;
    _notifyIfChanged(previous);
    await _storage.save(tokens);
  }

  Future<void> end() async {
    final previous = session;
    _tokens = null;
    _notifyIfChanged(previous);
    await _storage.clear();
  }

  void _notifyIfChanged(SessionState previous) {
    if (session != previous) _changes.add(session);
  }
}
