import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class CheckInManualEntryField extends StatefulWidget {
  const CheckInManualEntryField({
    required this.onSubmit,
    this.enabled = true,
    super.key,
  });

  final Future<void> Function(String rawInput) onSubmit;
  final bool enabled;

  @override
  State<CheckInManualEntryField> createState() =>
      _CheckInManualEntryFieldState();
}

class _CheckInManualEntryFieldState extends State<CheckInManualEntryField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onSubmit(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.checkinManualEntryLabel),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.enabled ? _submit : null,
            child: Text(l10n.checkinManualEntryAction),
          ),
        ],
      ),
    );
  }
}
