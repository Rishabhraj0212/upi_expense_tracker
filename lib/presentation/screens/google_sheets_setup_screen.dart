import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/sync_settings.dart';
import '../../domain/models/sync_status.dart';
import '../../sync/google_auth_gateway.dart';
import '../../sync/spreadsheet_connection_service.dart';
import '../providers/sync_providers.dart';
import 'sheet_restore_screen.dart';


/// The "Yes, Sync with Google Sheets" destination — both from first launch
/// and from Settings' "Connect Google Sheets" action later. Shows the
/// intended flow (Connect Account -> Create/Select Sheet -> Verify ->
/// Initial Sync) as a step list.
///
/// Steps 1 and 2 are real as of Step 7: account sign-in (identity) and
/// spreadsheet authorization/creation/verification (Drive/Sheets access) are
/// two separate operations, using two separate gateways. Only once a
/// spreadsheet is created or selected AND verified does
/// [SyncSettings.connectionState] become connected — never merely from
/// signing in. Step 4 (initial sync of existing transactions) remains an
/// inert placeholder for a later step.
class GoogleSheetsSetupScreen extends ConsumerStatefulWidget {
  const GoogleSheetsSetupScreen({super.key});

  @override
  ConsumerState<GoogleSheetsSetupScreen> createState() => _GoogleSheetsSetupScreenState();
}

class _GoogleSheetsSetupScreenState extends ConsumerState<GoogleSheetsSetupScreen> {
  bool _checkedForExistingSession = false;
  bool _busy = false;
  bool _connectingSheet = false;

  @override
  void initState() {
    super.initState();
    // Support re-authentication: if Google already remembers this device
    // (e.g. the app was reinstalled, or this screen is revisited) but we
    // haven't recorded an account locally, adopt it silently rather than
    // forcing the user through the picker again.
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreExistingSessionIfAny());
  }

  Future<void> _restoreExistingSessionIfAny() async {
    if (_checkedForExistingSession || !mounted) return;
    _checkedForExistingSession = true;

    final settingsRepo = ref.read(syncSettingsRepositoryProvider);
    final alreadyRecorded = (await settingsRepo.getSettings()).googleAccountEmail;
    if (alreadyRecorded != null) return;

    final liveEmail = await ref.read(googleAuthGatewayProvider).currentAccountEmail();
    if (liveEmail != null && mounted) {
      await settingsRepo.setGoogleAccount(liveEmail);
    }
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    GoogleSignInOutcome outcome;
    try {
      outcome = await ref.read(googleAuthGatewayProvider).signIn();
      if (outcome case GoogleSignInSuccess(:final email)) {
        await ref.read(syncSettingsRepositoryProvider).setGoogleAccount(email);
      }
    } finally {
      // Clear the busy spinner *before* possibly showing a dialog below —
      // an indeterminate spinner left showing underneath/behind a dialog
      // never settles, which both looks wrong and (in widget tests) hangs
      // pumpAndSettle() for as long as the dialog is up.
      if (mounted) setState(() => _busy = false);
    }
    if (outcome case GoogleSignInFailure(:final message) when mounted) {
      await _showError(message, title: 'Couldn\'t sign in');
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await ref.read(googleAuthGatewayProvider).signOut();
      await ref.read(syncSettingsRepositoryProvider).setGoogleAccount(null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createNewSheet() =>
      _connectSheet(() => ref.read(spreadsheetConnectionServiceProvider).createNewSheet(), isExisting: false);

  Future<void> _selectExistingSheet() =>
      _connectSheet(() => ref.read(spreadsheetConnectionServiceProvider).selectExistingSheet(), isExisting: true);

  Future<void> _connectSheet(
    Future<SpreadsheetConnectionOutcome> Function() run, {
    required bool isExisting,
  }) async {

    // Diagnostic only (temporary): confirms which account google_sign_in
    // currently reports as signed in at the exact moment authorization is
    // triggered, so it can be compared against the Cloud project's
    // configured test user.
    final recordedEmail = (await ref.read(syncSettingsRepositoryProvider).getSettings()).googleAccountEmail;
    final liveEmail = await ref.read(googleAuthGatewayProvider).currentAccountEmail();
    debugPrint(
      '[SheetSync] GoogleSheetsSetupScreen._connectSheet: recordedAccount=$recordedEmail, liveAccount=$liveEmail',
    );
    debugPrint('[SheetSync] GoogleSheetsSetupScreen._connectSheet: loading=true');
    setState(() => _connectingSheet = true);
    SpreadsheetConnectionOutcome outcome;
    try {
      outcome = await run();
    } catch (e, st) {
      // Belt-and-braces: every gateway/service call below this is expected
      // to convert its own failures into SpreadsheetConnectionFailure, but
      // if something unexpected still throws, it must surface as an error
      // dialog rather than silently clearing the loader with no feedback.
      debugPrint('[SheetSync] GoogleSheetsSetupScreen._connectSheet: uncaught ${e.runtimeType}: $e\n$st');
      outcome = SpreadsheetConnectionFailure('Unexpected error: $e');
    } finally {
      // As with sign-in, clear the spinner before any dialog is shown so an
      // indeterminate CircularProgressIndicator never lingers behind it.
      debugPrint('[SheetSync] GoogleSheetsSetupScreen._connectSheet: loading=false');
      if (mounted) setState(() => _connectingSheet = false);
    }
    if (!mounted) return;
    debugPrint('[SheetSync] GoogleSheetsSetupScreen._connectSheet: outcome=${outcome.runtimeType}');
    switch (outcome) {
      case SpreadsheetConnectionSuccess():
        if (isExisting && mounted) {
          // Navigate to the restore screen so the user can import their old data.
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SheetRestoreScreen()),
          );
        } else {
          // New sheet — nothing to restore; let AppStartupGate take over.
          Navigator.of(context).maybePop();
        }
      case SpreadsheetConnectionCancelled():
        break;
      case SpreadsheetConnectionFailure(:final message):
        await _showError(message, title: 'Couldn\'t connect the sheet');
    }
  }

  Future<void> _showError(String message, {required String title}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('$message\n\nYour expenses are safe locally in the meantime.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _skipForNow() async {
    await ref.read(syncSettingsRepositoryProvider).setSyncPreference(SyncPreference.localOnly);
    // No manual navigation: AppStartupGate (or the Settings screen this was
    // pushed from) reacts to the write on its own.
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(syncSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Google Sheets Setup')),
      body: settingsAsync.when(
        data: (settings) => _body(settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Could not load settings: $e')),
      ),
    );
  }

  Widget _body(SyncSettings settings) {
    final signedIn = settings.googleAccountEmail != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Connect your Google account to start syncing your expenses to a spreadsheet.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _SetupStep(
          stepNumber: 1,
          title: 'Connect Google Account',
          subtitle: signedIn ? 'Connected as ${settings.googleAccountEmail}' : 'Choose which Google account to use.',
          active: true,
          actionLabel: signedIn ? 'Sign out' : 'Connect Google Account',
          onAction: _busy ? null : (signedIn ? _signOut : _signIn),
          busy: _busy,
        ),
        _SetupStep(
          stepNumber: 2,
          title: 'Create or Select Sheet',
          subtitle: signedIn
              ? 'Create a new "UPI Expense Tracker" sheet, or choose an existing one.'
              : 'Sign in first to create or choose a sheet.',
          active: signedIn,
          actionLabel: 'Create New Sheet',
          onAction: _connectingSheet ? null : _createNewSheet,
          secondaryActionLabel: 'Select Existing Sheet',
          onSecondaryAction: _connectingSheet ? null : _selectExistingSheet,
          busy: _connectingSheet,
        ),
        const _SetupStep(
          stepNumber: 3,
          title: 'Verify',
          subtitle: 'Access is verified automatically when a sheet is created or selected.',
          active: false,
        ),
        const _SetupStep(
          stepNumber: 4,
          title: 'Initial Sync',
          subtitle: 'Write your existing transactions to the sheet.',
          active: false,
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: _skipForNow,
            child: const Text('Skip for now — keep my data local'),
          ),
        ),
      ],
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.active,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.busy = false,
  });

  final int stepNumber;
  final String title;
  final String subtitle;
  final bool active;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Opacity(
        opacity: active ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: active ? scheme.primary : scheme.surfaceContainerHighest,
                    child: Text(
                      '$stepNumber',
                      style: TextStyle(color: active ? scheme.onPrimary : scheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              if (active && (actionLabel != null || secondaryActionLabel != null)) ...[
                const SizedBox(height: 12),
                if (busy)
                  const Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (secondaryActionLabel != null)
                        OutlinedButton(onPressed: onSecondaryAction, child: Text(secondaryActionLabel!)),
                      if (actionLabel != null) FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
