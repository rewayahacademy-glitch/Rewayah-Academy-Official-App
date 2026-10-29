import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le rang du dernier signal de la veille sur les classes ou les seances
/// (29/10/2026). Une lecture « a portee » (qui declare ses `dependencies`) ne
/// s'invalide pas depuis la racine : elle regarde ce rang et se relit quand il
/// avance. C'est le cas de l'accueil de l'eleve en Interface guidee.
class GenerationVeille extends Notifier<int> {
  @override
  int build() => 0;

  /// Un signal de plus.
  void avancer() => state++;
}

/// Le rang, avance par `veille_fraicheur.dart`.
final NotifierProvider<GenerationVeille, int> generationVeilleProvider =
    NotifierProvider<GenerationVeille, int>(GenerationVeille.new);
