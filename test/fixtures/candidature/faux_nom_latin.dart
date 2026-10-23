// Le double du port du nom latin (`PortNomLatin`), oracle des tests de widget
// de la confirmation du nom en lettres latines. Importe par aucune ligne de
// production.
//
// Il rejoue ce que font `lire_nom_latin()` et `confirmer_nom_latin()`
// (`20261024000000_cand_nom_latin.sql`) : un nom d'origine, un nom latin
// confirme ou non, le refus d'un texte qui n'est pas latin, et le « a
// confirmer » qui se deduit (rien n'est ecrit sans la confirmation de la
// personne). Un test qui veut une panne la programme.

import 'package:rewayah_academy/core/candidature/nom_latin.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
import 'package:rewayah_academy/core/candidature/port_nom_latin.dart';

/// Le nom du titulaire, en memoire.
class FauxNomLatin implements PortNomLatin {
  /// Cree le double sur le nom d'origine [nomComplet].
  FauxNomLatin({required this.nomComplet, this.nomLatin});

  /// Le nom d'origine.
  final String nomComplet;

  /// Le nom latin confirme, ou `null`.
  String? nomLatin;

  /// Les textes recus par `confirmer`, dans l'ordre.
  final List<String> confirmations = <String>[];

  /// Le nombre de lectures.
  int lectures = 0;

  /// Une panne a lever a la prochaine confirmation, ou `null`.
  Object? panneConfirmation;

  /// Une panne a lever a la prochaine lecture, ou `null`.
  Object? panneLecture;

  @override
  Future<EtatNomLatin> lire() async {
    lectures++;
    final Object? panne = panneLecture;
    if (panne != null) {
      Error.throwWithStackTrace(panne, StackTrace.current);
    }
    final bool dejaLatin = nomEstLatin(nomComplet);
    return EtatNomLatin(
      nomComplet: nomComplet,
      nomLatin: nomLatin,
      dejaLatin: dejaLatin,
      aConfirmer: nomLatin == null && !dejaLatin,
    );
  }

  @override
  Future<String> confirmer(String nomLatin) async {
    confirmations.add(nomLatin);
    final Object? panne = panneConfirmation;
    if (panne != null) {
      panneConfirmation = null;
      Error.throwWithStackTrace(panne, StackTrace.current);
    }
    if (!nomEstLatin(nomLatin)) {
      throw const NomNonLatin();
    }
    this.nomLatin = nomLatinNettoye(nomLatin);
    return this.nomLatin!;
  }
}

/// Une panne de reseau, comme le port la leve.
const HorsLigneCandidature panneReseauNomLatin = HorsLigneCandidature();
