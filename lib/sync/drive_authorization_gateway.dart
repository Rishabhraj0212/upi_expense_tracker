/// Result of a `drive.file` authorization attempt. Distinct from
/// [GoogleSignInOutcome] in `google_auth_gateway.dart`: this is about
/// *authorizing access to Drive/Sheets data*, not signing in.
sealed class DriveAuthorizationOutcome {
  const DriveAuthorizationOutcome();
}

/// Authorization succeeded. [accessToken] is a short-lived OAuth token for
/// the `drive.file` scope — callers must keep it in memory only and never
/// persist or log it. [pickedFileId] is non-null only when the picker was
/// shown and the user selected an existing file.
class DriveAuthorizationSuccess extends DriveAuthorizationOutcome {
  const DriveAuthorizationSuccess({required this.accessToken, this.pickedFileId});
  final String accessToken;
  final String? pickedFileId;
}

class DriveAuthorizationCancelled extends DriveAuthorizationOutcome {
  const DriveAuthorizationCancelled();
}

class DriveAuthorizationFailure extends DriveAuthorizationOutcome {
  const DriveAuthorizationFailure(this.message);
  final String message;
}

/// Authorizes `drive.file` access to Google Drive, kept architecturally
/// separate from [GoogleAuthGateway] (account sign-in/identity). Backed by
/// the official native Android `AuthorizationClient`/Picker flow — never a
/// WebView, Custom Tab, or hosted web page of this app's own making.
abstract class DriveAuthorizationGateway {
  /// Shows Google's native file picker so the user can choose an EXISTING
  /// spreadsheet. On success, [DriveAuthorizationSuccess.pickedFileId] holds
  /// that file's id.
  Future<DriveAuthorizationOutcome> authorizeForPicker();

  /// Authorizes `drive.file` access without showing the picker, for use
  /// right before creating a brand-new spreadsheet.
  Future<DriveAuthorizationOutcome> authorizeForCreate();
}
