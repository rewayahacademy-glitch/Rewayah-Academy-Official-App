import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';

/// La surface pressable de [cible] : elle-meme ou son premier descendant
/// [Pressable], sinon [cible].
///
/// Sur bureau, un bouton epouse son libelle au debut d'une zone plus large
/// (K-36) : toucher le centre de la zone tomberait a cote du bouton.
Finder pressableDe(Finder cible) {
  final Finder pressable = find.descendant(
    of: cible,
    matching: find.byType(Pressable),
    matchRoot: true,
  );
  return pressable.evaluate().isEmpty ? cible : pressable.first;
}
