import 'dart:math';

const _safeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

class GeneratedTicketId {
  const GeneratedTicketId({required this.readableId, required this.randomPart});

  final String readableId;
  final String randomPart;

  String payloadFor(String eventShortCode) =>
      '$eventShortCode-$readableId-$randomPart';
}

GeneratedTicketId generateTicketId({required int sequence, Random? random}) {
  final rng = random ?? Random.secure();
  final readableId = sequence.toString().padLeft(4, '0');
  final randomPart = List.generate(
    4,
    (_) => _safeAlphabet[rng.nextInt(_safeAlphabet.length)],
  ).join();
  return GeneratedTicketId(readableId: readableId, randomPart: randomPart);
}
