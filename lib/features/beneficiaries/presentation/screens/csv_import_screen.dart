import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audit/audit_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/csv_parser.dart';
import '../../domain/new_beneficiary.dart';
import '../../../events/domain/custom_field.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/beneficiary_providers.dart';
import '../widgets/csv_mapping_form.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  List<String>? _headers;
  List<List<String>>? _dataRows;
  int? _importedCount;
  int? _skippedCount;
  bool _picking = false;

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (file == null) return;
      setState(() => _picking = true);
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      final parsed = parseCsvContent(content);
      if (!mounted) return;
      setState(() {
        _headers = parsed.headers;
        _dataRows = parsed.rows;
        _picking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _picking = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvImportPickError)));
    }
  }

  Future<void> _handleImport(List<NewBeneficiary> beneficiaries, int skipped) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    // Read before the await: see tickets_screen.dart's _confirmGenerate for
    // why.
    final auditLogger = ref.read(auditLoggerProvider);
    try {
      final stopwatch = Stopwatch()..start();
      final imported =
          await repository.importBeneficiaries(widget.eventId, beneficiaries);
      stopwatch.stop();
      auditLogger.logBeneficiariesImported(
        rowCount: imported,
        errorCount: skipped,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _importedCount = imported;
        _skippedCount = skipped;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvImportSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customFieldsAsync = ref.watch(customFieldsProvider(widget.eventId));

    Widget body;
    if (_importedCount != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.secondary,
              ).animate().scale(duration: 300.ms).fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              Text(
                l10n.csvImportResult(_importedCount!, _skippedCount!),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    } else if (_headers != null && _dataRows != null) {
      body = customFieldsAsync.when(
        data: (customFields) => CsvMappingForm(
          headers: _headers!,
          dataRows: _dataRows!,
          customFields: customFields,
          onImport: _handleImport,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: l10n.beneficiariesLoadError,
          onRetry: () => ref.invalidate(customFieldsProvider(widget.eventId)),
        ),
      );
    } else {
      final customFields = customFieldsAsync.valueOrNull ?? const <CustomField>[];
      final fieldLabels = customFields.map((f) => f.label).join(', ');
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.csvImportSchemaPreviewTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: AppColors.indigo),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final column in [
                        l10n.csvImportSchemaNameColumn,
                        for (final field in customFields) field.label,
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            column,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fieldLabels.isEmpty
                    ? l10n.csvImportFieldsHintNameOnly
                    : l10n.csvImportFieldsHint(fieldLabels),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _picking ? null : _pickFile,
                icon: _picking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                label: Text(
                  _picking
                      ? l10n.csvImportLoadingLabel
                      : l10n.csvImportPickFileAction,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.csvImportTitle)),
      body: body,
    );
  }
}
