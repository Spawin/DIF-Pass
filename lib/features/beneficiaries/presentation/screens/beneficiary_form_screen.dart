import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../events/domain/custom_field.dart';
import '../../../events/domain/custom_field_type.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';
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
  Uint8List? _photo;

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
        _photo = beneficiary.photo;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.beneficiaryFormLoadError)));
    }
  }

  TextEditingController _controllerFor(int customFieldId) {
    return _fieldControllers.putIfAbsent(customFieldId, () => TextEditingController());
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.beneficiaryFormPhotoSourceCameraAction),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.beneficiaryFormPhotoSourceGalleryAction),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _photo = bytes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save(List<CustomField> customFields, {required bool hasTicket}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_isEditing && hasTicket) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.beneficiaryFormEditConfirmTitle),
          content: Text(l10n.beneficiaryFormEditConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.eventFormSaveAction),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }
    setState(() => _loading = true);
    final repository = ref.read(beneficiaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final values = <int, String>{
      for (final field in customFields)
        if (_controllerFor(field.id).text.trim().isNotEmpty)
          field.id: _controllerFor(field.id).text.trim(),
    };
    final newBeneficiary = NewBeneficiary(
      name: _nameController.text.trim(),
      customFieldValues: values,
      photo: _photo,
    );
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
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.beneficiaryFormSaveError)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customFieldsAsync = ref.watch(customFieldsProvider(widget.eventId));
    final ticketsAsync = ref.watch(ticketsProvider(widget.eventId));

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
              Row(
                children: [
                  if (_photo != null) ...[
                    CircleAvatar(backgroundImage: MemoryImage(_photo!), radius: 24),
                    const SizedBox(width: 12),
                  ],
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.beneficiaryFormPhotoAction),
                  ),
                  if (_photo != null)
                    IconButton(
                      onPressed: () => setState(() => _photo = null),
                      icon: const Icon(Icons.close),
                      tooltip: l10n.beneficiaryFormPhotoRemoveAction,
                    ),
                ],
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
                onPressed: _loading
                    ? null
                    : () => _save(
                          customFields,
                          hasTicket: (ticketsAsync.valueOrNull ?? const [])
                              .any((t) => t.beneficiaryId == widget.beneficiaryId),
                        ),
                child: Text(l10n.eventFormSaveAction),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: l10n.beneficiariesLoadError,
          onRetry: () => ref.invalidate(customFieldsProvider(widget.eventId)),
        ),
      ),
    );
  }
}
