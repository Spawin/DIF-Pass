import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../beneficiaries/presentation/providers/beneficiary_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';
import '../check_in_feedback.dart';
import '../check_in_processor.dart';
import '../providers/check_in_providers.dart';
import '../widgets/check_in_manual_entry_field.dart';

class CheckInScanScreen extends ConsumerStatefulWidget {
  const CheckInScanScreen({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<CheckInScanScreen> createState() => _CheckInScanScreenState();
}

class _CheckInScanScreenState extends ConsumerState<CheckInScanScreen> {
  final _controller = MobileScannerController();
  bool _manualEntry = false;
  bool _busy = false;
  CheckInFeedback? _feedback;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final rawValue =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (rawValue == null) return;
    await _process(rawValue);
  }

  Future<void> _process(String rawInput) async {
    setState(() => _busy = true);
    await _controller.stop();

    if (mounted) {
      try {
        final event = await ref.read(eventProvider(widget.eventId).future);
        final feedback = await processCheckIn(
          ticketRepository: ref.read(ticketRepositoryProvider),
          checkInRepository: ref.read(checkInRepositoryProvider),
          beneficiaryRepository: ref.read(beneficiaryRepositoryProvider),
          eventId: widget.eventId,
          presenceMode: event.presenceMode,
          rawInput: rawInput,
        );
        if (mounted) {
          setState(() => _feedback = feedback);
          if (feedback is CheckInFeedbackRecorded) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.heavyImpact();
          }
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.checkinUnexpectedError)),
          );
        }
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() {
      _feedback = null;
      _busy = false;
    });
    if (!_manualEntry) {
      await _controller.start();
    }
  }

  void _toggleManualEntry() {
    setState(() => _manualEntry = !_manualEntry);
    if (_manualEntry) {
      _controller.stop();
    } else {
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final (checkedIn, total) = ref.watch(checkInCounterProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: eventAsync.when(
          data: (event) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.checkinScreenTitle),
              Text(event.name, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          loading: () => Text(l10n.checkinScreenTitle),
          error: (_, _) => Text(l10n.checkinScreenTitle),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _manualEntry ? Icons.qr_code_scanner : Icons.keyboard_outlined,
            ),
            tooltip: _manualEntry
                ? l10n.checkinBackToScanAction
                : l10n.checkinManualEntryToggleAction,
            onPressed: _busy ? null : _toggleManualEntry,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_manualEntry)
            MobileScanner(controller: _controller, onDetect: _onDetect)
          else
            Center(
              child: CheckInManualEntryField(
                enabled: !_busy,
                onSubmit: _process,
              ),
            ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.checkinCounterLabel(checkedIn, total),
                  key: ValueKey(checkedIn),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().scale(duration: 300.ms).fadeIn(duration: 300.ms),
              ),
            ),
          ),
          if (_feedback != null)
            _CheckInFeedbackOverlay(feedback: _feedback!, locale: locale),
        ],
      ),
    );
  }
}

class _CheckInFeedbackOverlay extends StatelessWidget {
  const _CheckInFeedbackOverlay({required this.feedback, required this.locale});

  final CheckInFeedback feedback;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSuccess = feedback is CheckInFeedbackRecorded;
    final color = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.error;

    String? name;
    String? message;
    switch (feedback) {
      case CheckInFeedbackRecorded(:final beneficiaryName):
        name = beneficiaryName;
      case CheckInFeedbackAlreadyRecorded(:final beneficiaryName, :final scannedAt):
        name = beneficiaryName;
        message = l10n.checkinAlreadyRecordedMessage(
          DateFormat.Hm(locale).format(scannedAt),
        );
      case CheckInFeedbackNotFound():
        message = l10n.checkinNotFoundMessage;
    }

    return Positioned.fill(
      child: ColoredBox(
        color: color.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              if (name != null)
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (message != null)
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
