import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../events/domain/custom_field.dart';
import '../../../events/domain/custom_field_type.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/new_beneficiary.dart';
import '../providers/beneficiary_providers.dart';

class BeneficiaryFormScreen extends ConsumerStatefulWidget {
  const BeneficiaryFormScreen({required this.eventId, this.beneficiaryId, super.key});

  final int eventId;
  final int? beneficiaryId;

  @override
  ConsumerState<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends ConsumerState<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Map<int, TextEditingController> _fieldControllers = {};
  bool _loading = false;

  bool get _isEditing => widget.beneficiaryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingBeneficiary(widget.beneficiaryId!);
    }
  }

  Future<void> _loadExistingBeneficiary(int id) async {
    try {
      final repository = ref.read(beneficiaryRepositoryProvider);
      final beneficiary = await repository.getBeneficiary(id);
      if (!mounted) return;
      setState(() {
        _nameController.text = beneficiary.name;
        for (final entry in beneficiary.customFieldValues.entries) {
          _controllerFor(entry.key).text = entry.value;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  TextEditingController _controllerFor(int customFieldId) {
    return _fieldControllers.putIfAbsent(customFieldId, () => TextEditingController());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save(List<CustomField> customFields) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final values = <int, String>{
      for (final field in customFields)
        if (_controllerFor(field.id).text.trim().isNotEmpty)
          field.id: _controllerFor(field.id).text.trim(),
    };
    final newBeneficiary =
        NewBeneficiary(name: _nameController.text.trim(), customFieldValues: values);
    try {
      if (_isEditing) {
        await repository.updateBeneficiary(widget.beneficiaryId!, newBeneficiary);
      } else {
        await repository.createBeneficiary(widget.eventId, newBeneficiary);
      }
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customFieldsAsync = ref.watch(customFieldsProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.beneficiaryFormTitleEdit : l10n.beneficiaryFormTitleCreate),
      ),
      body: customFieldsAsync.when(
        data: (customFields) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.eventFormNameLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.eventFormNameRequired
                    : null,
              ),
              const SizedBox(height: 16),
              for (final field in customFields) ...[
                TextFormField(
                  controller: _controllerFor(field.id),
                  keyboardType: field.type == CustomFieldType.number
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: field.label),
                  validator: field.type == CustomFieldType.number
                      ? (value) => (value == null ||
                              value.trim().isEmpty ||
                              num.tryParse(value.trim()) != null)
                          ? null
                          : l10n.beneficiaryFormFieldNumberInvalid
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _loading ? null : () => _save(customFields),
                child: Text(l10n.eventFormSaveAction),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.beneficiariesLoadError)),
      ),
    );
  }
}
