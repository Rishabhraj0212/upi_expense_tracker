/// Google Sign-In configuration.
///
/// This is **not a secret** — OAuth client IDs are public identifiers (only
/// OAuth client *secrets* need protecting, and Android apps never use one
/// for this flow). It does, however, need to be a real value from your own
/// Google Cloud project before sign-in will work.
///
/// Why a *web* client ID is needed for an Android-only app: this app
/// deliberately avoids Firebase (`google-services.json`), and without that,
/// Android's Credential Manager-based Google Sign-In still verifies its ID
/// tokens against a web-type OAuth client — see the `google_sign_in_android`
/// package's own integration docs. The separate Android-type OAuth client
/// (registered with this app's package name + signing SHA-1) still has to
/// exist too, but its ID is never referenced directly in this code — Google
/// Play Services discovers it automatically from the package name/SHA-1.
///
/// One-time setup in Google Cloud Console (console.cloud.google.com):
///  1. Create or pick a project. Enable the Google Sheets API, Google Drive
///     API, and Google Picker API (needed by later Phase 2 steps too).
///  2. Configure the OAuth consent screen (Testing mode is fine for a
///     personal, sideloaded app — add your own account as a test user).
///  3. Create an OAuth client ID of type **Android**: package name
///     `com.rishabh.upi_expense_tracker`, plus your debug keystore's SHA-1
///     (`keytool -list -v -keystore ~/.android/debug.keystore` — password is
///     usually `android`), and later your release keystore's SHA-1 if you
///     ever produce a signed build.
///  4. Create a *second* OAuth client ID of type **Web application** (no
///     redirect URIs needed). Copy its client ID into [googleSignInServerClientId]
///     below.
///
/// Until a real value is set, sign-in will fail cleanly with
/// [GoogleSignInFailure] (typically `clientConfigurationError`) rather than
/// silently doing nothing or falsely appearing to succeed.
const String googleSignInServerClientId = '397836718319-bkt32m2bpoosieftpta3ov0e1a6hmh90.apps.googleusercontent.com';
