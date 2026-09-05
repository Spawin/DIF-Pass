import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/settings/settings_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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

    CheckInFeedback? feedback;
    if (mounted) {
      try {
        final event = await ref.read(eventProvider(widget.eventId).future);
        feedback = await processCheckIn(
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
      } catch (_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.checkinUnexpectedError)),
          );
        }
        _dismissFeedback();
        return;
      }
    }

    if (feedback != null && checkInFeedbackAutoDismisses(feedback)) {
      final delayMs = ref.read(appSettingsProvider).checkinFeedbackDelayMs;
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      _dismissFeedback();
    }
    // Exceptions (already recorded / not found) wait for the overlay's OK
    // button to call _dismissFeedback instead of a timer.
  }

  void _dismissFeedback() {
    if (!mounted) return;
    setState(() {
      _feedback = null;
      _busy = false;
    });
    if (!_manualEntry) {
      _controller.start();
    }
  }

  void _toggleManualEntry() {
    setState(() => _manualEntry = !_manualEntry);
    if (_manualEntry) {
      _controller.stop();
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
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              overlayBuilder: (context, constraints) {
                final size = constraints.biggest;
                final windowSide = size.shortestSide * 0.7;
                final scanWindow = Rect.fromCenter(
                  center: size.center(Offset.zero),
                  width: windowSide,
                  height: windowSide,
                );
                return ScanWindowOverlay(
                  controller: _controller,
                  scanWindow: scanWindow,
                  borderColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  borderWidth: 3,
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.03, 1.03),
                      duration: 900.ms,
                    );
              },
            )
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
                  color: AppColors.ink.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.checkinCounterLabel(checkedIn, total),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.merge(ticketMonoStyle(Theme.of(context).colorScheme))
                      .copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                )
                    .animate(key: ValueKey(checkedIn))
                    .scale(duration: 300.ms)
                    .fadeIn(duration: 300.ms),
              ),
            ),
          ),
          if (_feedback != null)
            _CheckInFeedbackOverlay(feedback: _feedback!, locale: locale, onDismiss: _dismissFeedback),
        ],
      ),
    );
  }
}

class _CheckInFeedbackOverlay extends StatelessWidget {
  const _CheckInFeedbackOverlay({
    required this.feedback,
    required this.locale,
    required this.onDismiss,
  });

  final CheckInFeedback feedback;
  final String locale;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSuccess = feedback is CheckInFeedbackRecorded;
    final color = isSuccess ? AppColors.teal : theme.colorScheme.error;
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                if (name != null)
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                if (message != null)
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    isSuccess ? l10n.checkinSkipAction : l10n.commonOk,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
