import 'package:google_sign_in/google_sign_in.dart';

import 'google_auth_gateway.dart';
import 'google_sign_in_config.dart';

/// Real implementation, wrapping the `google_sign_in` v7 API. That package
/// made this split explicit at the SDK level: `authenticate`/
/// `attemptLightweightAuthentication` establish identity only, while scope
/// authorization is a separate, later call this gateway deliberately does
/// not make (see [GoogleAuthGateway]'s doc comment).
///
/// Not unit-tested directly — like [AndroidSetupGateway] elsewhere in this
/// app, it wraps a real platform SDK with no meaningful behavior to assert
/// without a device. Everything that consumes [GoogleAuthGateway] is tested
/// against the interface via a fake (see test/sync/fake_google_auth_gateway.dart).
class GoogleSignInAuthGateway implements GoogleAuthGateway {
  Future<void>? _initFuture;

  /// `GoogleSignIn.instance.initialize()` must complete exactly once before
  /// any other call — this makes that safe to call from every method here
  /// without the caller needing to know about it.
  Future<void> _ensureInitialized() {
    return _initFuture ??= GoogleSignIn.instance.initialize(serverClientId: googleSignInServerClientId);
  }

  @override
  Future<String?> currentAccountEmail() async {
    await _ensureInitialized();
    try {
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      final account = future == null ? null : await future;
      return account?.email;
    } on GoogleSignInException {
      // No restorable session — that's a normal, silent outcome here, not
      // something to surface as an error.
      return null;
    }
  }

  @override
  Future<GoogleSignInOutcome> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return GoogleSignInSuccess(account.email);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleSignInCancelled();
      }
      return GoogleSignInFailure(e.description ?? e.code.name);
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    // disconnect() revokes prior authorization in addition to signing out —
    // the stronger of the two, appropriate for an explicit user disconnect.
    await GoogleSignIn.instance.disconnect();
  }
}
