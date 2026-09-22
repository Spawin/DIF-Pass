import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// Wraps a SegmentedButton in the white, rounded, softly-shadowed "pill
// track" from the design bundle (docs/design_handoff_ticket_redesign) --
// a container SegmentedButton's own ButtonStyle can't express, since the
// theme only reaches the individual segments, not an outer background.
class SegmentedControlFrame extends StatelessWidget {
  const SegmentedControlFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
