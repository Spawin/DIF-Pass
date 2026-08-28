import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/custom_field.dart';
import '../../domain/new_beneficiary.dart';

class CsvMappingForm extends StatefulWidget {
  const CsvMappingForm({
    required this.headers,
    required this.dataRows,
    required this.customFields,
    required this.onImport,
    super.key,
  });

  final List<String> headers;
  final List<List<String>> dataRows;
  final List<CustomField> customFields;
  final void Function(List<NewBeneficiary> beneficiaries, int skippedCount) onImport;

  @override
  State<CsvMappingForm> createState() => _CsvMappingFormState();
}

class _CsvMappingFormState extends State<CsvMappingForm> {
  int? _nameColumnIndex;
  final Map<int, int?> _customFieldColumnIndex = {};

  void _submit() {
    if (_nameColumnIndex == null) return;
    final beneficiaries = <NewBeneficiary>[];
    var skipped = 0;
    for (final row in widget.dataRows) {
      final name = _nameColumnIndex! < row.length ? row[_nameColumnIndex!].trim() : '';
      if (name.isEmpty) {
        skipped++;
        continue;
      }
      final values = <int, String>{};
      for (final field in widget.customFields) {
        final columnIndex = _customFieldColumnIndex[field.id];
        if (columnIndex != null && columnIndex < row.length) {
          final value = row[columnIndex].trim();
          if (value.isNotEmpty) values[field.id] = value;
        }
      }
      beneficiaries.add(NewBeneficiary(name: name, customFieldValues: values));
    }
    widget.onImport(beneficiaries, skipped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnOptions = <DropdownMenuItem<int?>>[
      DropdownMenuItem(value: null, child: Text(l10n.csvImportIgnoreColumn)),
      for (var i = 0; i < widget.headers.length; i++)
        DropdownMenuItem(value: i, child: Text(widget.headers[i])),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.csvImportMappingNameLabel, style: Theme.of(context).textTheme.titleSmall),
        DropdownButton<int?>(
          value: _nameColumnIndex,
          items: columnOptions,
          onChanged: (value) => setState(() => _nameColumnIndex = value),
        ),
        const SizedBox(height: 16),
        for (final field in widget.customFields) ...[
          Text(field.label, style: Theme.of(context).textTheme.titleSmall),
          DropdownButton<int?>(
            value: _customFieldColumnIndex[field.id],
            items: columnOptions,
            onChanged: (value) => setState(() => _customFieldColumnIndex[field.id] = value),
          ),
          const SizedBox(height: 16),
        ],
        FilledButton(
          onPressed: _nameColumnIndex != null ? _submit : null,
          child: Text(l10n.csvImportImportAction),
        ),
      ],
    );
  }
}
