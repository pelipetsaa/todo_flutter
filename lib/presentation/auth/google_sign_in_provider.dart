import 'package:google_sign_in/google_sign_in.dart';

sealed class GoogleSignInResult {
  const GoogleSignInResult();
}

final class GoogleSignInSuccess extends GoogleSignInResult {
  const GoogleSignInSuccess(this.idToken);

  final String idToken;
}

final class GoogleSignInCancelled extends GoogleSignInResult {
  const GoogleSignInCancelled();
}

final class GoogleSignInFailure extends GoogleSignInResult {
  const GoogleSignInFailure(this.message);

  final String? message;
}

/// Native Google account picker that returns an ID token for the backend to verify.
abstract interface class GoogleSignInProvider {
  Future<GoogleSignInResult> signIn();
}

class UnavailableGoogleSignInProvider implements GoogleSignInProvider {
  const UnavailableGoogleSignInProvider();

  @override
  Future<GoogleSignInResult> signIn() async =>
      const GoogleSignInFailure('Google Sign-In is not configured for this build');
}

/// Credential Manager on Android, the GoogleSignIn SDK on iOS. On Android the ID token is issued
/// for [serverClientId] (the web client); on iOS for [clientId] (the iOS client).
class PluginGoogleSignInProvider implements GoogleSignInProvider {
  PluginGoogleSignInProvider({this.clientId, this.serverClientId});

  final String? clientId;
  final String? serverClientId;
  Future<void>? _initialization;

  @override
  Future<GoogleSignInResult> signIn() async {
    final signIn = GoogleSignIn.instance;
    try {
      try {
        await (_initialization ??= signIn.initialize(clientId: clientId, serverClientId: serverClientId));
      } catch (_) {
        _initialization = null; // A failed initialization is retried on the next tap.
        rethrow;
      }
      if (!signIn.supportsAuthenticate()) return const GoogleSignInFailure('Not supported on this platform');
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      return idToken == null ? const GoogleSignInFailure('No ID token') : GoogleSignInSuccess(idToken);
    } on GoogleSignInException catch (e) {
      // clientConfigurationError usually means no OAuth client matches this package and signing certificate.
      return e.code == GoogleSignInExceptionCode.canceled
          ? const GoogleSignInCancelled()
          : GoogleSignInFailure('${e.code.name}: ${e.description}');
    } on Exception catch (e) {
      // Platform errors outside the plugin's own exceptions must not leave the button spinning.
      return GoogleSignInFailure(e.toString());
    }
  }
}
