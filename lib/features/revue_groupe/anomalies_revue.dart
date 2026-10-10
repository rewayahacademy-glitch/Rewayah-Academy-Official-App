import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/enseignant/modeles_enseignant.dart';

/// Les quatre anomalies que la revue de groupe (`ENS-08`) sait montrer.
///
/// **Quatre, et pas une cinquieme.** Ce sont celles du contrat : un palier qui
/// approche, un eleve sorti du corridor de progression, une proposition de
/// transfert, une proposition de reorientation. L'ordre de l'enum est l'ordre
/// d'affichage : ce qui a une echeance passe avant ce qui attend une decision
/// de l'academie.
///
/// Aucune de ces quatre notions n'existe sous ce nom en base : `0024` calcule
/// `rapport_manquant`, `blocage_sans_suivi` et `evaluation_en_retard`, et
/// `anomalies_qualite()` est reservee a l'administration. La correspondance est
/// une decision de socle, pas une invention d'ecran
/// (`docs/archive/2026-09-pre-remise-a-plat/parallel-reports/CONTRACT_REQUEST_C.md`).
enum TypeAnomalieRevue {
  /// Un palier de programme approche pour un eleve.
  gateAVenir,

  /// Un eleve sort de la marge de progression attendue.
  horsCorridor,

  /// Le systeme propose de deplacer un eleve de groupe.
  transfertPropose,

  /// Le systeme propose de revoir le niveau ou le parcours d'un eleve.
  reorientationProposee,
}

/// Une anomalie produite par le systeme, telle que la revue la lit.
///
/// Elle ne porte **aucun nom de famille** : [eleve] est le libelle deja masque
/// par la base, prenom ou identifiant immuable (ADR-008). Elle ne porte pas non
/// plus de verdict : l'enseignant lit, l'academie tranche.
@immutable
class AnomalieRevue {
  /// Cree une anomalie.
  const AnomalieRevue({
    required this.type,
    required this.studentId,
    required this.eleve,
    this.detail,
  });

  /// Ce que le systeme a detecte.
  final TypeAnomalieRevue type;

  /// L'eleve concerne.
  final String studentId;

  /// Comment le nommer a l'ecran.
  final String eleve;

  /// Le detail court, quand la source en fournit un.
  final String? detail;
}

/// Les anomalies d'un groupe, bornees a ses membres et triees pour l'ecran.
///
/// **Le filtre n'est pas cosmetique.** Une anomalie qui viserait un eleve sorti
/// du groupe demanderait a l'enseignant de regarder quelqu'un qui n'est plus a
/// lui, et le catalogue interdit de faire promettre a une ligne ce qu'elle ne
/// peut pas tenir. Le roster est la source de verite de l'appartenance :
/// `groupe_membres.left_at is null` la porte en base, et `mon_groupe_detail`
/// ne rend que les membres actifs.
List<AnomalieRevue> anomaliesDuGroupe({
  required List<AnomalieRevue> anomalies,
  required List<MembreSeance> membres,
}) {
  final Set<String> actifs = <String>{
    for (final MembreSeance m in membres) m.studentId,
  };

  final List<AnomalieRevue> retenues = anomalies
      .where((AnomalieRevue a) => actifs.contains(a.studentId))
      .toList();
  retenues.sort((AnomalieRevue a, AnomalieRevue b) {
    final int parType = a.type.index.compareTo(b.type.index);
    return parType != 0
        ? parType
        : a.eleve.toLowerCase().compareTo(b.eleve.toLowerCase());
  });
  return retenues;
}

/// Les anomalies pedagogiques d'un groupe, vues par son enseignant.
///
/// **Il ne rend rien aujourd'hui, et c'est la verite du depot, pas un talon
/// d'attente.** Les sources de ces quatre anomalies vivent dans les migrations
/// `0020` a `0024` (programme, progression, evaluations, qualite), et leurs
/// policies de lecture sont toutes `app_role() = 'admin'` : **aucune RPC
/// d'anomalies bornee a l'enseignant n'existe**. Tant qu'elle n'existe pas, la
/// revue est vide -- ce qui est son etat normal -- et l'ecran le dit au lieu de
/// poser une colonne de tirets.
///
/// Le jour ou le socle livre la lecture, c'est ce provider qui la consomme, et
/// l'ecran n'a pas une ligne a changer : c'est pourquoi il existe des
/// maintenant plutot qu'une liste vide ecrite en dur dans l'ecran.
final FutureProviderFamily<List<AnomalieRevue>, String>
anomaliesGroupeProvider = FutureProvider.family<List<AnomalieRevue>, String>(
  (Ref ref, String groupeId) async => const <AnomalieRevue>[],
);
