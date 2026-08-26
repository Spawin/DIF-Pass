import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/custom_field.dart';
import '../../domain/custom_field_type.dart';

class CustomFieldEditor extends StatelessWidget {
  const CustomFieldEditor({
    required this.fields,
    required this.keys,
    required this.locked,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final List<NewCustomField> fields;
  final List<int> keys;
  final bool locked;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, NewCustomField field) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locked)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.eventFormCustomFieldsLocked,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        for (var i = 0; i < fields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey(keys[i]),
                    initialValue: fields[i].label,
                    enabled: !locked,
                    decoration:
                        InputDecoration(labelText: l10n.eventFormFieldLabelHint),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? l10n.eventFormFieldLabelRequired
                        : null,
                    onChanged: (value) => onChanged(
                      i,
                      NewCustomField(
                        label: value,
                        type: fields[i].type,
                        sortOrder: fields[i].sortOrder,
                        showOnTicket: fields[i].showOnTicket,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<CustomFieldType>(
                  value: fields[i].type,
                  onChanged: locked
                      ? null
                      : (type) {
                          if (type == null) return;
                          onChanged(
                            i,
                            NewCustomField(
                              label: fields[i].label,
                              type: type,
                              sortOrder: fields[i].sortOrder,
                              showOnTicket: fields[i].showOnTicket,
                            ),
                          );
                        },
                  items: CustomFieldType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        ),
                      )
                      .toList(),
                ),
                Checkbox(
                  value: fields[i].showOnTicket,
                  onChanged: locked
                      ? null
                      : (value) => onChanged(
                            i,
                            NewCustomField(
                              label: fields[i].label,
                              type: fields[i].type,
                              sortOrder: fields[i].sortOrder,
                              showOnTicket: value ?? false,
                            ),
                          ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: locked ? null : () => onRemove(i),
                ),
              ],
            ),
          ),
        if (!locked)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(l10n.eventFormAddFieldAction),
          ),
      ],
    );
  }
}
