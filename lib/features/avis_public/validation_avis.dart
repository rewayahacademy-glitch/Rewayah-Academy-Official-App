// Les regles du formulaire d'avis (DECISION-AVIS-2026-10-19, choix 2). Le
// serveur re-verifie tout ; cette fonction ne sert qu'a dire tout de suite, et
// au bon endroit, ce qui manque. Pure, testee.

import '../../core/capacites/port_avis.dart';

/// Les bornes du formulaire.
abstract final class BornesAvis {
  /// Nom affiche : 2 a 60 caracteres.
  static const int nomMin = 2;

  /// Nom affiche : 2 a 60 caracteres.
  static const int nomMax = 60;

  /// Titre : 80 caracteres au plus.
  static const int titreMax = 80;

  /// Avis : 20 a 1500 caracteres.
  static const int texteMin = 20;

  /// Avis : 20 a 1500 caracteres.
  static const int texteMax = 1500;

  /// Premiere annee d'arrivee acceptee.
  static const int anneeMin = 2015;
}

/// Ce que la personne a rempli.
class SaisieAvis {
  /// Cree la saisie.
  const SaisieAvis({
    this.nom = '',
    this.qualite,
    this.pays,
    this.mois,
    this.annee,
    this.note = 0,
    this.titre = '',
    this.texte = '',
    this.accord = false,
  });

  /// Le nom affiche.
  final String nom;

  /// Qui parle.
  final QualiteAvis? qualite;

  /// Le code du pays.
  final String? pays;

  /// Le mois d'arrivee (1 a 12).
  final int? mois;

  /// L'annee d'arrivee.
  final int? annee;

  /// La note (0 : aucune).
  final int note;

  /// Le titre.
  final String titre;

  /// Le texte.
  final String texte;

  /// L'accord de publication.
  final bool accord;
}

/// Le mois d'arrivee de [s] au premier du mois, ou `null` s'il manque.
DateTime? moisDepuis(SaisieAvis s) {
  final int? m = s.mois;
  final int? a = s.annee;
  return m == null || a == null ? null : DateTime(a, m);
}

/// Les champs a corriger dans [s], dans l'ordre du formulaire. [maintenant] est
/// l'instant courant : un mois futur est refuse.
List<ChampAvis> champsACorriger(SaisieAvis s, DateTime maintenant) {
  final int nom = s.nom.trim().length;
  final DateTime? depuis = moisDepuis(s);
  final int texte = s.texte.trim().length;
  return <ChampAvis>[
    if (nom < BornesAvis.nomMin || nom > BornesAvis.nomMax) ChampAvis.nom,
    if (s.qualite == null) ChampAvis.qualite,
    if (s.pays == null) ChampAvis.pays,
    if (depuis == null ||
        depuis.year < BornesAvis.anneeMin ||
        depuis.isAfter(DateTime(maintenant.year, maintenant.month)))
      ChampAvis.depuis,
    if (s.note < 1 || s.note > 5) ChampAvis.note,
    if (s.titre.trim().length > BornesAvis.titreMax) ChampAvis.titre,
    if (texte < BornesAvis.texteMin || texte > BornesAvis.texteMax)
      ChampAvis.texte,
    if (!s.accord) ChampAvis.accord,
  ];
}

/// Les annees proposees : de l'annee courante a 2015, la plus recente d'abord.
List<int> anneesProposees(DateTime maintenant) => <int>[
  for (int a = maintenant.year; a >= BornesAvis.anneeMin; a--) a,
];
