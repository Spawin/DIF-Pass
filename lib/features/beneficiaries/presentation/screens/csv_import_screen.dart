import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/csv_parser.dart';
import '../../domain/new_beneficiary.dart';
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

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      final parsed = parseCsvContent(content);
      if (!mounted) return;
      setState(() {
        _headers = parsed.headers;
        _dataRows = parsed.rows;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvImportPickError)));
    }
  }

  Future<void> _handleImport(List<NewBeneficiary> beneficiaries, int skipped) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final imported =
          await repository.importBeneficiaries(widget.eventId, beneficiaries);
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
      final fieldLabels =
          customFieldsAsync.valueOrNull?.map((f) => f.label).join(', ') ?? '';
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fieldLabels.isEmpty
                    ? l10n.csvImportFieldsHintNameOnly
                    : l10n.csvImportFieldsHint(fieldLabels),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(l10n.csvImportPickFileAction),
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
