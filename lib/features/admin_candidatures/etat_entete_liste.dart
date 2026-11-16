/// BE-LISTE : ce que l'en-tete de la liste des candidatures se rappelle.
///
/// Deux petits choix de lecture, gardes par appareil (le navigateur sur le
/// web ; hors web, la session) : « Qui attend quoi » repliee ou non, et le
/// bandeau « Lecture des deux cotes » deplie ou non. Rien de sensible, rien
/// pour le serveur.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inscription/questionnaire/memoire_appareil.dart';

/// La clef de « Qui attend quoi » repliee.
const String cleMemoireAttentesRepliees = 'rewayah.be_liste.attentes_repliee';

/// La clef du bandeau « Lecture des deux cotes » deplie.
const String cleMemoireLectureDepliee = 'rewayah.be_liste.lecture_depliee';

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

/// « Qui attend quoi » est repliee.
final NotifierProvider<ChoixAppareil, bool> attentesRepliesProvider =
    NotifierProvider<ChoixAppareil, bool>(
      () => ChoixAppareil(cleMemoireAttentesRepliees),
    );

/// Le bandeau « Lecture des deux cotes » est deplie.
final NotifierProvider<ChoixAppareil, bool> lectureDeplieeProvider =
    NotifierProvider<ChoixAppareil, bool>(
      () => ChoixAppareil(cleMemoireLectureDepliee),
    );
