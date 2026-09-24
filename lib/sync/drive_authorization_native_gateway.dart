import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'drive_authorization_gateway.dart';

/// Real implementation, backed by the native Android side
/// (`MainActivity.kt`), which uses Play Services'
/// `com.google.android.gms.auth.api.identity.AuthorizationClient` with the
/// `PICKER_OAUTH_TRIGGER` resource parameter for the picker case. No token
/// or picked-file data is ever cached on the Dart side beyond the returned
/// [DriveAuthorizationOutcome] value.
class DriveAuthorizationNativeGateway implements DriveAuthorizationGateway {
  DriveAuthorizationNativeGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('upi_tracker/drive_authorization');

  final MethodChannel _channel;

  @override
  Future<DriveAuthorizationOutcome> authorizeForPicker() => _authorize(showPicker: true);

  @override
  Future<DriveAuthorizationOutcome> authorizeForCreate() => _authorize(showPicker: false);

  Future<DriveAuthorizationOutcome> _authorize({required bool showPicker}) async {
    debugPrint('[SheetSync] DriveAuthorizationNativeGateway._authorize: entry, showPicker=$showPicker');
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('authorizeDriveFile', {
        'showPicker': showPicker,
      });
      final accessToken = result?['accessToken'] as String?;
      final hasPickedFileId = result?['pickedFileId'] != null;
      debugPrint(
        '[SheetSync] DriveAuthorizationNativeGateway._authorize: native call returned, '
        'hasAccessToken=${accessToken != null}, hasPickedFileId=$hasPickedFileId',
      );
      if (accessToken == null) {
        return const DriveAuthorizationFailure('No access token was returned.');
      }
      return DriveAuthorizationSuccess(accessToken: accessToken, pickedFileId: result?['pickedFileId'] as String?);
    } on PlatformException catch (e) {
      debugPrint('[SheetSync] DriveAuthorizationNativeGateway._authorize: PlatformException code=${e.code}');
      if (e.code == 'cancelled') return const DriveAuthorizationCancelled();
      return DriveAuthorizationFailure(e.message ?? e.code);
    } on MissingPluginException catch (e) {
      // Distinct from PlatformException: this means the native side never
      // received the call at all (channel/method not registered, or the
      // running APK predates this channel being added — e.g. a stale
      // install after a hot reload instead of a full rebuild).
      debugPrint('[SheetSync] DriveAuthorizationNativeGateway._authorize: MissingPluginException: $e');
      return DriveAuthorizationFailure('The native authorization channel is not available: $e');
    } catch (e) {
      debugPrint('[SheetSync] DriveAuthorizationNativeGateway._authorize: unexpected ${e.runtimeType}: $e');
      return DriveAuthorizationFailure('Unexpected error during authorization: $e');
    }
  }
}
