import 'dart:typed_data';

/// Hors navigateur (mobile, bureau, tests) : aucune conversion sur
/// l'appareil. La phrase de refus dit quoi faire.
Future<Uint8List?> convertirHeic(
  Uint8List heic, {
  required int coteMax,
}) async => null;
