import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter/di/app_config.dart';

void main() {
  test('builds without dart-defines get the web client used as the Google ID token audience', () {
    // Release builds in CI pass no GOOGLE_SERVER_CLIENT_ID; without this default Google sign-in is switched off.
    expect(AppConfig.fromEnvironment().googleServerClientId, AppConfig.defaultGoogleWebClientId);
    expect(AppConfig.defaultGoogleWebClientId, endsWith('.apps.googleusercontent.com'));
  });
}
