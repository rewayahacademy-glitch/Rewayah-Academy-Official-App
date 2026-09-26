import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

/// La preparation pedagogique de la prochaine seance d'un groupe (CL-4.4).
///
/// Trois elements au plus, ceux de la spec : le support prevu, la position de
/// reprise et l'objectif. Aucune note de cours, aucun « point a renforcer »
/// (rectification 15).
@immutable
class PreparationSeance {
  /// Cree la preparation.
  const PreparationSeance({
    this.supportPrevu,
    this.positionReprise,
    this.objectif,
  });

  /// Le support prevu, en texte lisible.
  final String? supportPrevu;

  /// La position de reprise dans le support.
  final String? positionReprise;

  /// L'objectif de la seance.
  final String? objectif;

  /// Vrai quand rien n'est renseigne.
  bool get estVide =>
      _vide(supportPrevu) && _vide(positionReprise) && _vide(objectif);

  static bool _vide(String? v) => v == null || v.trim().isEmpty;
}

/// Ce que l'enseignant sait d'un eleve, pedagogiquement (R15).
///
/// **Aucun champ prive** : ni telephone, ni courriel, ni adresse, ni foyer,
/// ni paiement, ni tuteur, ni geolocalisation, ni appareil. Il n'y a donc rien
/// a oublier de masquer.
@immutable
class ProjectionEleve {
  /// Cree la projection.
  const ProjectionEleve({
    this.pageReprise,
    this.dernierPoint,
    this.cleAvatar,
    this.indicateur,
    this.objectif,
    this.presenceRecente,
  });

  /// L'objectif en cours de l'eleve, en texte neutre (fiche ENS-11, EN-4).
  final String? objectif;

  /// La presence recente, en texte neutre, sans jugement (fiche ENS-11).
  final String? presenceRecente;

  /// La page de reprise, en texte lisible (« Page 24 »).
  final String? pageReprise;

  /// Le dernier point utile, en texte neutre.
  final String? dernierPoint;

  /// La cle de la photo de l'eleve, ou nul : les initiales en repli (E5,
  /// K-44). La photo est visible de son enseignant.
  final String? cleAvatar;

  /// L'indicateur de l'eleve, decide par le serveur (E6), jamais calcule ici.
  /// Nul : aucun indicateur n'est montre.
  final IndicateurEleve? indicateur;
}

/// L'indicateur d'un eleve dans sa Classe : un point **et** un mot, jamais la
/// couleur seule (UX_REVIEW_04 n° 9). Aucun jugement : « A renforcer » est le
/// lexique du role (E17), jamais « Eleve problematique ».
enum IndicateurEleve {
  /// Presence reguliere, rien a signaler.
  regulier,

  /// Un point pedagogique a reprendre.
  aRenforcer,

  /// Absent a une seance recente.
  absence,
}

/// La preparation de la prochaine seance d'un groupe. **`null` = non
/// branche** : aucune source serveur a ce jour (backend reporte a BR-1). La
/// demonstration la surcharge.
final ProviderFamily<PreparationSeance?, String> preparationSeanceProvider =
    Provider.family<PreparationSeance?, String>((Ref ref, String _) => null);

/// Les projections pedagogiques des eleves d'un groupe, par `studentId`.
/// Vide tant que la source n'est pas branchee (BR-1) ; la demonstration la
/// surcharge.
final ProviderFamily<Map<String, ProjectionEleve>, String>
projectionElevesProvider =
    Provider.family<Map<String, ProjectionEleve>, String>(
      (Ref ref, String _) => const <String, ProjectionEleve>{},
    );
