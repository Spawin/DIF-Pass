import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/audit/audit_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/custom_field.dart';
import '../../domain/custom_field_type.dart';
import '../../domain/presence_mode.dart';
import '../providers/event_providers.dart';
import '../widgets/custom_field_editor.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({this.eventId, super.key});

  final int? eventId;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _date = DateTime.now();
  PresenceMode _presenceMode = PresenceMode.simple;
  Uint8List? _logo;
  final List<NewCustomField> _customFields = [];
  final List<int> _customFieldKeys = [];
  int _nextFieldKey = 0;
  List<NewCustomField> _initialCustomFields = [];
  bool _customFieldsLocked = false;
  bool _presenceModeLocked = false;
  bool _loading = false;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingEvent(widget.eventId!);
    }
  }

  Future<void> _loadExistingEvent(int id) async {
    try {
      final repository = ref.read(eventRepositoryProvider);
      final event = await repository.getEvent(id);
      final fields = await repository.watchCustomFields(id).first;
      final customFieldsLocked = !(await repository.canEditCustomFields(id));
      final presenceModeLocked = !(await repository.canEditPresenceMode(id));

      if (!mounted) return;
      setState(() {
        _nameController.text = event.name;
        _locationController.text = event.location ?? '';
        _date = event.date;
        _presenceMode = event.presenceMode;
        _logo = event.logo;
        _customFields
          ..clear()
          ..addAll(
            fields.map(
              (f) => NewCustomField(
                label: f.label,
                type: f.type,
                sortOrder: f.sortOrder,
                showOnTicket: f.showOnTicket,
              ),
            ),
          );
        _customFieldKeys
          ..clear()
          ..addAll(List.generate(_customFields.length, (_) => _nextFieldKey++));
        _initialCustomFields = List.of(_customFields);
        _customFieldsLocked = customFieldsLocked;
        _presenceModeLocked = presenceModeLocked;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.eventFormLoadError)));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _logo = bytes);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(
        NewCustomField(
          label: '',
          type: CustomFieldType.text,
          sortOrder: _customFields.length,
        ),
      );
      _customFieldKeys.add(_nextFieldKey++);
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields.removeAt(index);
      _customFieldKeys.removeAt(index);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final repository = ref.read(eventRepositoryProvider);
    final location =
        _locationController.text.trim().isEmpty ? null : _locationController.text.trim();

    try {
      if (_isEditing) {
        await repository.updateEvent(
          widget.eventId!,
          name: _nameController.text.trim(),
          date: _date,
          location: location,
          logo: _logo,
          presenceMode: _presenceMode,
        );
        final customFieldsChanged =
            _customFields.length != _initialCustomFields.length ||
                List.generate(
                  _customFields.length,
                  (i) => _customFields[i] != _initialCustomFields[i],
                ).contains(true);
        // ponytail: skip-if-unchanged guard, not a full diff-merge. A real
        // reorder-without-content-change would still trigger a replace
        // (harmless once no beneficiaries reference the fields yet); revisit
        // if jalon 3 needs id-stable partial updates.
        if (!_customFieldsLocked && customFieldsChanged) {
          await repository.replaceCustomFields(widget.eventId!, _customFields);
        }
      } else {
        await repository.createEvent(
          name: _nameController.text.trim(),
          date: _date,
          location: location,
          logo: _logo,
          presenceMode: _presenceMode,
          customFields: _customFields,
        );
        ref.read(auditLoggerProvider).logEventCreated(
              presenceMode: _presenceMode.name,
              customFieldCount: _customFields.length,
            );
      }

      if (!mounted) return;
      HapticFeedback.lightImpact();
      // Guarded: in a widget test (or any context where this screen is the
      // only route), there is nothing to pop back to.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.eventFormSaveError)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.eventFormTitleEdit : l10n.eventFormTitleCreate),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.eventFormNameLabel),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? l10n.eventFormNameRequired : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.eventFormDateLabel),
              subtitle: Text(DateFormat.yMMMMd(locale).format(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: l10n.eventFormLocationLabel),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_logo != null) ...[
                  CircleAvatar(backgroundImage: MemoryImage(_logo!), radius: 24),
                  const SizedBox(width: 12),
                ],
                TextButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l10n.eventFormLogoAction),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.eventFormPresenceModeLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<PresenceMode>(
              segments: [
                ButtonSegment(
                  value: PresenceMode.simple,
                  label: Text(l10n.eventFormPresenceModeSimple),
                ),
                ButtonSegment(
                  value: PresenceMode.multiple,
                  label: Text(l10n.eventFormPresenceModeMultiple),
                ),
              ],
              selected: {_presenceMode},
              onSelectionChanged: _presenceModeLocked
                  ? null
                  : (selection) => setState(() => _presenceMode = selection.first),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.eventFormCustomFieldsLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            CustomFieldEditor(
              fields: _customFields,
              keys: _customFieldKeys,
              locked: _customFieldsLocked,
              onAdd: _addCustomField,
              onRemove: _removeCustomField,
              onChanged: (index, field) => setState(() => _customFields[index] = field),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: Text(l10n.eventFormSaveAction),
            ),
          ],
        ),
      ),
    );
  }
}
