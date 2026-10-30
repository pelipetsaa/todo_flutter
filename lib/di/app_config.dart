import 'dart:io';

import 'package:flutter/foundation.dart';

/// Build settings, passed with `--dart-define` (see README):
/// - `API_BASE_URL`: the server; by default the local one in debug and the deployed one in release.
/// - `GOOGLE_SERVER_CLIENT_ID`: the web OAuth client, the ID token audience on Android; defaults to ToDoList's.
/// - `GOOGLE_IOS_CLIENT_ID`: the iOS OAuth client; required for Google sign-in on iOS.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.googleServerClientId, this.googleIosClientId});

  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: defaultGoogleWebClientId);
    const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    final config = AppConfig(
      apiBaseUrl: apiBaseUrl.isNotEmpty ? apiBaseUrl : _defaultApiBaseUrl(),
      googleServerClientId: serverClientId.isEmpty ? null : serverClientId,
      googleIosClientId: iosClientId.isEmpty ? null : iosClientId,
    );
    if (kReleaseMode && !config.apiBaseUrl.startsWith('https://')) {
      throw StateError('Release builds must use an https:// API_BASE_URL, got ${config.apiBaseUrl}');
    }
    return config;
  }

  static const deployedApiBaseUrl = 'https://todolist-server-zyck.onrender.com';

  /// The web OAuth client of the ToDoList Google Cloud project (`todolist.googleWebClientId` there), which the
  /// server accepts as the ID token audience. Not a secret: it only names the client. Sign-in on Android also needs
  /// an Android OAuth client for this package and signing certificate in the same project (see README).
  static const defaultGoogleWebClientId = '942997837259-p5avn0h84otleksfs47cnbrr7gs52t2c.apps.googleusercontent.com';

  final String apiBaseUrl;
  final String? googleServerClientId;
  final String? googleIosClientId;

  /// Google sign-in needs the client of the current platform; without it the button reports an error.
  bool get isGoogleSignInConfigured => Platform.isIOS ? googleIosClientId != null : googleServerClientId != null;

  /// The Android emulator reaches the host machine as 10.0.2.2, the iOS simulator as localhost.
  static String _defaultApiBaseUrl() {
    if (kReleaseMode) return deployedApiBaseUrl;
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }
}
