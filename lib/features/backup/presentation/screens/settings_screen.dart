import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/settings/settings_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/backup_providers.dart';
import '../widgets/import_confirm_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({this.pickFile = FilePicker.pickFile, super.key});

  // Injectable for tests: FilePicker.pickFile talks to the platform and
  // cannot be exercised in flutter test, same reason AppDatabase.forTesting
  // exists as its own constructor (jalon 7). Every other screen that calls
  // FilePicker.pickFile in this app calls it directly and stays untested at
  // that boundary; this screen is the one exception because the sequence
  // that follows the picked file (close db, import, invalidate, navigate)
  // is the most failure-sensitive code in the app, per jalon 7's review.
  final Future<PlatformFile?> Function({
    FileType type,
    List<String>? allowedExtensions,
  }) pickFile;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      final bytes = await repository.exportBackup();
      final tempDir = await getTemporaryDirectory();
      final dateLabel = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final exportFile = File(
        p.join(tempDir.path, 'dif-pass-sauvegarde-$dateLabel.sqlite'),
      );
      await exportFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(exportFile.path)]),
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsExportError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    // Captured before any await: ProviderScope.containerOf needs a mounted
    // context, and the container (unlike ref) stays safe to call
    // invalidate() on even if this widget gets disposed while the import
    // is in flight (e.g. the user navigates away mid-import).
    final container = ProviderScope.containerOf(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    PlatformFile? file;
    try {
      file = await widget.pickFile(
        type: FileType.custom,
        allowedExtensions: ['sqlite', 'db'],
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsImportError)));
      return;
    }
    if (file == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;

    final confirmed = await showImportConfirmDialog(context);
    if (!confirmed) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;

    try {
      final bytes = await file.readAsBytes();
      final repository = await ref.read(backupRepositoryProvider.future);
      await ref.read(appDatabaseProvider).close();
      await repository.importBackup(bytes);
      container.invalidate(appDatabaseProvider);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      context.go('/');
    } catch (e) {
      container.invalidate(appDatabaseProvider);
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsImportError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_outlined),
              label: Text(l10n.settingsExportAction),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.settingsImportAction),
            ),
            const SizedBox(height: 32),
            Text(l10n.settingsCheckinDelayLabel, style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: settings.checkinFeedbackDelayMs.toDouble(),
              min: 1000,
              max: 4000,
              divisions: 30,
              label: '${(settings.checkinFeedbackDelayMs / 1000).toStringAsFixed(1)}s',
              onChanged: (value) => ref
                  .read(appSettingsProvider.notifier)
                  .setCheckinFeedbackDelayMs(value.round()),
            ),
            const SizedBox(height: 16),
            Text(l10n.settingsLanguageLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String?>(
              segments: [
                ButtonSegment(value: null, label: Text(l10n.settingsLanguageAuto)),
                ButtonSegment(value: 'fr', label: Text(l10n.settingsLanguageFrench)),
                ButtonSegment(value: 'en', label: Text(l10n.settingsLanguageEnglish)),
              ],
              selected: {settings.localeOverride},
              onSelectionChanged: (selection) => ref
                  .read(appSettingsProvider.notifier)
                  .setLocaleOverride(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}
