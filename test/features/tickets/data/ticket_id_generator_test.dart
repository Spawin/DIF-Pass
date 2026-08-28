import 'dart:math';

import 'package:dif_pass/features/tickets/data/ticket_id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

const _safeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

void main() {
  test('generateTicketId pads the sequence to 4 digits', () {
    final result = generateTicketId(sequence: 42, random: Random(1));
    expect(result.readableId, '0042');
  });

  test('generateTicketId produces a 4-character random part from the safe alphabet', () {
    final result = generateTicketId(sequence: 1, random: Random(1));
    expect(result.randomPart, hasLength(4));
    expect(
      result.randomPart.split('').every((c) => _safeAlphabet.contains(c)),
      isTrue,
    );
  });

  test('payloadFor assembles the full ticket identifier', () {
    final result = generateTicketId(sequence: 42, random: Random(1));
    expect(result.payloadFor('EVT3'), 'EVT3-0042-${result.randomPart}');
  });

  test('generateTicketId defaults to Random.secure and still produces a valid format', () {
    final result = generateTicketId(sequence: 7);
    expect(result.readableId, '0007');
    expect(result.randomPart, hasLength(4));
  });
}
