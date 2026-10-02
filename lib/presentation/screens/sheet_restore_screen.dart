import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/sheet_import_service.dart';
import '../providers/sync_providers.dart';

/// Shown after a user selects an existing Google Sheet (during first-launch
/// setup or from Settings). It offers to pull all existing rows from that
/// sheet back into the local database so that a reinstalled app picks up
/// where the previous install left off.
///
/// The user can skip the restore and go straight to the dashboard; the
/// sheet remains connected either way.
class SheetRestoreScreen extends ConsumerStatefulWidget {
  const SheetRestoreScreen({super.key});

  @override
  ConsumerState<SheetRestoreScreen> createState() => _SheetRestoreScreenState();
}

class _SheetRestoreScreenState extends ConsumerState<SheetRestoreScreen> {
  _RestoreState _state = const _RestoreIdle();

  Future<void> _startRestore() async {
    setState(() => _state = const _RestoreRunning(done: 0, total: 0));

    final outcome = await ref.read(sheetImportServiceProvider).importFromSheet(
      onProgress: (done, total) {
        if (mounted) {
          setState(() => _state = _RestoreRunning(done: done, total: total));
        }
      },
    );

    if (!mounted) return;
    setState(() => _state = _RestoreDone(outcome));
  }

  void _finish() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: _state is! _RestoreRunning,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Restore from Sheet'),
          automaticallyImplyLeading: _state is! _RestoreRunning,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _body(theme, scheme),
          ),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme, ColorScheme scheme) {
    final state = _state;

    if (state is _RestoreIdle) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.cloud_download_outlined, size: 72, color: scheme.primary),
          const SizedBox(height: 24),
          Text(
            'Restore your data?',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We found your existing Google Sheet. Would you like to import '
            'all previously saved transactions into this device?',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _startRestore,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Yes, Restore My Data'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _finish,
            child: const Text('Skip — start fresh'),
          ),
        ],
      );
    }

    if (state is _RestoreRunning) {
      final hasTotal = state.total > 0;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasTotal) ...[
            LinearProgressIndicator(value: state.done / state.total),
            const SizedBox(height: 16),
            Text(
              'Importing ${state.done} / ${state.total}…',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ] else ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              'Reading your sheet…',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      );
    }

    if (state is _RestoreDone) {
      final outcome = state.outcome;

      if (outcome is SheetImportAborted) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.error_outline, size: 64, color: scheme.error),
            const SizedBox(height: 20),
            Text(
              'Could not restore',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              outcome.reason,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your sheet is still connected. You can try again from Settings.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: _finish, child: const Text('Continue to App')),
          ],
        );
      }

      if (outcome is SheetImportSuccess) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: scheme.primary),
            const SizedBox(height: 20),
            Text(
              'Restore complete!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _StatRow(label: 'Imported', value: outcome.imported, color: scheme.primary),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Already present (skipped)',
              value: outcome.skipped,
              color: scheme.secondary,
            ),
            if (outcome.failed > 0) ...[
              const SizedBox(height: 8),
              _StatRow(label: 'Failed', value: outcome.failed, color: scheme.error),
            ],
            const SizedBox(height: 32),
            FilledButton(onPressed: _finish, child: const Text('Go to Dashboard')),
          ],
        );
      }
    }

    // Fallback — should never happen.
    return const SizedBox.shrink();
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          '$value',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// State classes
// ---------------------------------------------------------------------------
sealed class _RestoreState {
  const _RestoreState();
}

class _RestoreIdle extends _RestoreState {
  const _RestoreIdle();
}

class _RestoreRunning extends _RestoreState {
  const _RestoreRunning({required this.done, required this.total});
  final int done;
  final int total;
}

class _RestoreDone extends _RestoreState {
  const _RestoreDone(this.outcome);
  final SheetImportOutcome outcome;
}
