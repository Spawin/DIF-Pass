import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
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
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null || file.path == null) return;
    final content = await File(file.path!).readAsString();
    final parsed = parseCsvContent(content);
    if (!mounted) return;
    setState(() {
      _headers = parsed.headers;
      _dataRows = parsed.rows;
    });
  }

  Future<void> _handleImport(List<NewBeneficiary> beneficiaries, int skipped) async {
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final imported =
          await repository.importBeneficiaries(widget.eventId, beneficiaries);
      if (!mounted) return;
      setState(() {
        _importedCount = imported;
        _skippedCount = skipped;
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget body;
    if (_importedCount != null) {
      body = Center(
        child: Text(l10n.csvImportResult(_importedCount!, _skippedCount!)),
      );
    } else if (_headers != null && _dataRows != null) {
      final customFieldsAsync = ref.watch(customFieldsProvider(widget.eventId));
      body = customFieldsAsync.when(
        data: (customFields) => CsvMappingForm(
          headers: _headers!,
          dataRows: _dataRows!,
          customFields: customFields,
          onImport: _handleImport,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.beneficiariesLoadError)),
      );
    } else {
      body = Center(
        child: FilledButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(l10n.csvImportPickFileAction),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.csvImportTitle)),
      body: body,
    );
  }
}
