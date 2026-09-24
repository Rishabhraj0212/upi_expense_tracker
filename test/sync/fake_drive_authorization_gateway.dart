import 'package:upi_expense_tracker/sync/drive_authorization_gateway.dart';

/// Configurable fake so authorization-flow tests never touch the real
/// native `AuthorizationClient`/Picker channel, which has no handler
/// registered under `flutter_test`.
class FakeDriveAuthorizationGateway implements DriveAuthorizationGateway {
  DriveAuthorizationOutcome nextPickerOutcome = const DriveAuthorizationCancelled();
  DriveAuthorizationOutcome nextCreateOutcome = const DriveAuthorizationCancelled();

  int pickerCalls = 0;
  int createCalls = 0;

  @override
  Future<DriveAuthorizationOutcome> authorizeForPicker() async {
    pickerCalls++;
    return nextPickerOutcome;
  }

  @override
  Future<DriveAuthorizationOutcome> authorizeForCreate() async {
    createCalls++;
    return nextCreateOutcome;
  }
}
