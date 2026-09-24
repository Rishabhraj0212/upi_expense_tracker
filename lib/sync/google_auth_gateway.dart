/// Outcome of a sign-in attempt. Cancellation is deliberately distinct from
/// failure: a user closing the account picker isn't an error worth showing
/// as one, but a real failure (misconfiguration, no network, etc.) is.
sealed class GoogleSignInOutcome {
  const GoogleSignInOutcome();
}

class GoogleSignInSuccess extends GoogleSignInOutcome {
  const GoogleSignInSuccess(this.email);
  final String email;
}

class GoogleSignInCancelled extends GoogleSignInOutcome {
  const GoogleSignInCancelled();
}

class GoogleSignInFailure extends GoogleSignInOutcome {
  const GoogleSignInFailure(this.message);
  final String message;
}

/// Google account authentication only — establishing *who* the user is.
/// Deliberately excludes anything about spreadsheet access: requesting the
/// `spreadsheets`/`drive.file` scopes, and verifying access to a specific
/// sheet, belong to the sheet-selection/authorization layer (Step 7+), which
/// consumes the account this produces. A successful [signIn] must never, by
/// itself, imply a connected sync state — that requires a spreadsheet to
/// also be selected and verified.
abstract class GoogleAuthGateway {
  /// Checks for a previously authenticated account without prompting any
  /// UI — used so a returning user isn't asked to sign in again every time
  /// (re-authentication). Returns null if there is no existing session or it
  /// could not be silently restored.
  Future<String?> currentAccountEmail();

  /// Shows the account picker / consent UI.
  Future<GoogleSignInOutcome> signIn();

  /// Signs out the current account and revokes prior authorization granted
  /// to this app.
  Future<void> signOut();
}
