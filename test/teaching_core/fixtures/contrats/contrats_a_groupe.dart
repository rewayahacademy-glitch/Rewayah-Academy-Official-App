// TC-DOUBLE-CONTRAT: canonique = lib/core/tc_groupe/group_summary_vm.dart
// (Agent A). Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 1.
//
// Agent Q n'ecrit aucune ligne de production : ce fichier est un DOUBLE de
// test. Agent Z le supprime a l'integration.

import 'package:flutter/foundation.dart';

import 'contrats_a_horloge.dart';

/// Le titre de l'enseignant dans le contexte cours (decision D-02).
///
/// **Sayyid / Sayyida, jamais Ustaz.** Les deux formes arabes sont fournies
/// ici comme valeurs litterales : D-02 en fait la seule exception a la regle
/// « aucun agent ne produit de traduction arabe ».
enum TitreEnseignant {
  /// Enseignant.
  sayyid('sayyid', 'Sayyid', 'سيد'),

  /// Enseignante.
  sayyida('sayyida', 'Sayyida', 'سيدة');

  const TitreEnseignant(this.valeurSql, this.libelleFr, this.libelleAr);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Le libelle francais affiche devant le nom.
  final String libelleFr;

  /// Le libelle arabe.
  final String libelleAr;

  /// Lit un titre depuis sa valeur SQL. `null` sur valeur inconnue.
  static TitreEnseignant? depuisSql(String? valeur) {
    for (final TitreEnseignant t in TitreEnseignant.values) {
      if (t.valeurSql == valeur) return t;
    }
    return null;
  }
}

/// L'enseignant, tel qu'une carte de Groupe l'affiche.
@immutable
class EnseignantVM {
  /// Cree la vue d'un enseignant.
  const EnseignantVM({
    required this.enseignantId,
    required this.titre,
    required this.nomAffichage,
    this.photoUrlOuCle,
  });

  /// L'uuid de l'enseignant.
  final String enseignantId;

  /// Son titre.
  final TitreEnseignant titre;

  /// Son nom d'affichage autorise.
  final String nomAffichage;

  /// La **cle** de sa photo. `null` = photo manquante, donc etat d'erreur ou
  /// de migration EXPLICITE, jamais un avatar generique (decision D-01).
  final String? photoUrlOuCle;
}

/// Le jeton de couleur d'un groupe, pris dans une palette **administree**.
///
/// Jamais un hex libre (decision D-18), et jamais le seul identifiant du
/// groupe : toute interface qui l'affiche affiche aussi le libelle.
@immutable
class JetonCouleurGroupe {
  /// Cree un jeton.
  const JetonCouleurGroupe({required this.index, required this.codeStable});

  /// L'index dans la palette administree.
  final int index;

  /// Le code stable, ex. `g17`. Stable, administre, jamais un hex.
  final String codeStable;
}

/// Le public d'un groupe.
enum TypePublicGroupeVM {
  /// Enfants.
  enfant('enfant'),

  /// Adultes.
  adulte('adulte');

  const TypePublicGroupeVM(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;
}

/// Une occurrence de seance, materialisee ou non.
@immutable
class OccurrenceSeance {
  /// Cree une occurrence.
  OccurrenceSeance({
    required this.debutUtc,
    required this.duree,
    required this.fuseauReferenceGroupe,
    this.sessionId,
  }) : assert(debutUtc.isUtc, 'tout DateTime de contrat est en UTC');

  /// L'identifiant de seance. `null` tant que l'occurrence n'est pas
  /// materialisee en base.
  final String? sessionId;

  /// Le debut, en UTC.
  final DateTime debutUtc;

  /// La duree prevue.
  final Duration duree;

  /// Le fuseau de reference du groupe, au format IANA.
  ///
  /// **Jamais un offset numerique** : `Europe/Paris`, pas `UTC+1`.
  final String fuseauReferenceGroupe;
}

/// La carte d'un Groupe (CONTRACTS section 1).
@immutable
class GroupSummaryVM {
  /// Cree une carte de groupe.
  const GroupSummaryVM({
    required this.groupeId,
    required this.libelle,
    required this.couleurJeton,
    required this.enseignant,
    required this.nombreMembres,
    required this.seuilMax,
    required this.typePublic,
    required this.actif,
    this.nomCours,
    this.niveauHumain,
    this.prochaineSeance,
    this.horloge,
  }) : assert(seuilMax > 0, 'la capacite vient de la donnee, jamais de 5 en dur'),
       assert(nombreMembres >= 0, 'un effectif ne peut pas etre negatif');

  /// L'uuid du groupe.
  final String groupeId;

  /// Le nom familier, jamais un code backend.
  final String libelle;

  /// La couleur d'identification.
  final JetonCouleurGroupe couleurJeton;

  /// L'enseignant assigne.
  final EnseignantVM enseignant;

  /// Le nom humain du cours. `null` si non assigne.
  final String? nomCours;

  /// Le nom humain du niveau. **Jamais `code_technique`.**
  final String? niveauHumain;

  /// L'effectif, lu du serveur.
  final int nombreMembres;

  /// La capacite, lue du serveur. **Jamais la valeur 5 en dur.**
  final int seuilMax;

  /// Le public.
  final TypePublicGroupeVM typePublic;

  /// La prochaine occurrence connue. `null` si aucune.
  final OccurrenceSeance? prochaineSeance;

  /// L'horloge de cette occurrence. `null` s'il n'y en a pas.
  final SessionClockVM? horloge;

  /// Faux quand `groupes.ended_at` est renseigne.
  final bool actif;
}
