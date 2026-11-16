/// BE-LISTE-2 : ce que l'en-tete de la liste des candidatures se rappelle.
///
/// Un seul choix de lecture, garde par appareil (le navigateur sur le web ;
/// hors web, la session) : le bandeau « Lecture des deux cotes » est compris,
/// donc ferme (« J'ai compris »). Rien de sensible, rien pour le serveur.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inscription/questionnaire/memoire_appareil.dart';

/// La clef du bandeau « Lecture des deux cotes » compris.
const String cleMemoireLectureComprise = 'rewayah.be_liste.lecture_comprise';

/// Un choix vrai / faux garde sur l'appareil.
class ChoixAppareil extends Notifier<bool> {
  /// Cree le choix de la [clef], faux tant qu'il n'a pas ete fait.
  ChoixAppareil(this.clef);

  /// La clef de la memoire de l'appareil.
  final String clef;

  @override
  bool build() => lireMemoireAppareil(clef) == '1';

  /// Pose le choix.
  void choisir({required bool valeur}) {
    ecrireMemoireAppareil(clef, valeur ? '1' : '0');
    state = valeur;
  }
}

/// Le bandeau « Lecture des deux cotes » est compris (ferme).
final NotifierProvider<ChoixAppareil, bool> lectureCompriseProvider =
    NotifierProvider<ChoixAppareil, bool>(
      () => ChoixAppareil(cleMemoireLectureComprise),
    );
