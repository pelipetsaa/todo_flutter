import 'dart:async';

import 'package:flutter/foundation.dart';

/// Unidirectional data flow: the UI sends intents, the view model runs use cases and feeds
/// their results into a pure reducer, and the UI renders [state]. One-off events go through [effects].
abstract class MviViewModel<S, I, E> extends ChangeNotifier {
  MviViewModel(this._state);

  S _state;
  // Single-subscription: effects sent before the screen subscribes are buffered, not lost.
  final _effects = StreamController<E>();
  bool _disposed = false;

  S get state => _state;

  Stream<E> get effects => _effects.stream;

  void onIntent(I intent);

  /// Results of async work may arrive after the screen is gone; they are dropped then.
  @protected
  void updateState(S Function(S state) transform) {
    if (_disposed) return;
    final next = transform(_state);
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }

  @protected
  void sendEffect(E effect) {
    if (!_disposed) _effects.add(effect);
  }

  @override
  void dispose() {
    _disposed = true;
    _effects.close();
    super.dispose();
  }
}
