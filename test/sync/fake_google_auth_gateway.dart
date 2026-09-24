import 'package:upi_expense_tracker/sync/google_auth_gateway.dart';

/// Configurable fake so auth-flow tests never touch the real `google_sign_in`
/// plugin (which has no platform implementation under `flutter test`) or
/// trigger a real account picker.
class FakeGoogleAuthGateway implements GoogleAuthGateway {
  /// Set before calling signIn() to control what it returns.
  GoogleSignInOutcome nextSignInOutcome = const GoogleSignInCancelled();

  /// Simulates a pre-existing session (e.g. from a previous app run) that
  /// [currentAccountEmail] can silently restore, supporting re-authentication.
  String? existingSessionEmail;

  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  Future<String?> currentAccountEmail() async => existingSessionEmail;

  @override
  Future<GoogleSignInOutcome> signIn() async {
    signInCalls++;
    if (nextSignInOutcome case GoogleSignInSuccess(:final email)) {
      existingSessionEmail = email;
    }
    return nextSignInOutcome;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    existingSessionEmail = null;
  }
}
