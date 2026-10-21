// La politique de la Reserve strategique (spec §9 ; CPT-BR-12). **Le seul
// port lu par deux voies** : CPT-TRES lit `politique()` et `indicateurs()`,
// CPT-DIR ecrit `enregistrer(...)`. Pose complet par CPT-F et **gele**
// (`20_comptable/02_DECOUPAGE.md`) : un champ manquant = une ligne pour
// CPT-FUS, sans modifier.
//
// Aucune plage commerciale codee : 10 USD et 1 000 000 USD rendent pareil
// (R-FIN-08, 09) ; les limites reelles viendront de la validation serveur.
// L'ecriture est reservee a la Direction, versionnee, auditee ; le Comptable
// lit la politique et l'execute (§9.6).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

export '../comptable/modeles_comptable.dart'
    show IndicateursReserve, ModeObjectifReserve;

/// La regle d'alimentation automatique (§9.3).
enum RegleAlimentation {
  /// Desactivee.
  desactivee,

  /// Un montant fixe a chaque cadence.
  montantFixe,

  /// Un pourcentage (en pour mille) de l'encaissement consolide.
  pourcentage,

  /// Completer jusqu'a l'objectif.
  jusquAObjectif,

  /// Proposition automatique a confirmer par le Comptable.
  proposee,
}

/// La cadence d'alimentation (§9.4).
enum CadenceAlimentation {
  /// A chaque cycle de cloture.
  clotureCycle,

  /// Hebdomadaire.
  hebdomadaire,

  /// Mensuelle.
  mensuelle,

  /// Apres chaque encaissement consolide.
  apresEncaissementConsolide,

  /// Manuelle.
  manuelle,
}

/// La politique de la Reserve strategique, telle que la Direction l'a
/// enregistree (§9.2 a §9.6).
@immutable
class PolitiqueReserve {
  /// Cree la politique.
  const PolitiqueReserve({
    required this.version,
    required this.modeObjectif,
    required this.regleAlimentation,
    required this.cadence,
    required this.retraitSoumisValidation,
    this.montantCible,
    this.nombreMois,
    this.montantAuto,
    this.pourcentageAutoPourMille,
    this.seuilAlertePourMille,
    this.dateEffet,
    this.auteur,
  });

  /// La version (la Direction la fait evoluer, §9.6).
  final String version;

  /// Mode A (montant fixe) ou B (couverture en mois).
  final ModeObjectifReserve modeObjectif;

  /// Le montant cible, en mode A. Aucune borne codee.
  final Montant? montantCible;

  /// Le nombre de mois de charges essentielles, en mode B. Aucune borne
  /// codee.
  final int? nombreMois;

  /// La regle d'alimentation.
  final RegleAlimentation regleAlimentation;

  /// Le montant automatique, pour [RegleAlimentation.montantFixe].
  final Montant? montantAuto;

  /// Le pourcentage automatique, en pour mille, pour
  /// [RegleAlimentation.pourcentage].
  final int? pourcentageAutoPourMille;

  /// La cadence.
  final CadenceAlimentation cadence;

  /// Le seuil d'alerte « sous objectif », en pour mille de l'objectif.
  final int? seuilAlertePourMille;

  /// Vrai quand tout retrait exige une validation supplementaire (§9.5,
  /// R-FIN-10). Vrai par defaut chez la source.
  final bool retraitSoumisValidation;

  /// La date d'effet.
  final DateTime? dateEffet;

  /// Qui l'a enregistree (« la direction », jamais « admin »).
  final String? auteur;
}

/// Un brouillon de politique a enregistrer (Direction).
@immutable
class BrouillonPolitiqueReserve {
  /// Cree le brouillon.
  const BrouillonPolitiqueReserve({
    required this.modeObjectif,
    required this.regleAlimentation,
    required this.cadence,
    required this.retraitSoumisValidation,
    this.montantCible,
    this.nombreMois,
    this.montantAuto,
    this.pourcentageAutoPourMille,
    this.seuilAlertePourMille,
  });

  /// Le brouillon qui reprend [p] telle quelle.
  BrouillonPolitiqueReserve.depuis(PolitiqueReserve p)
    : this(
        modeObjectif: p.modeObjectif,
        regleAlimentation: p.regleAlimentation,
        cadence: p.cadence,
        retraitSoumisValidation: p.retraitSoumisValidation,
        montantCible: p.montantCible,
        nombreMois: p.nombreMois,
        montantAuto: p.montantAuto,
        pourcentageAutoPourMille: p.pourcentageAutoPourMille,
        seuilAlertePourMille: p.seuilAlertePourMille,
      );

  /// Voir [PolitiqueReserve.modeObjectif].
  final ModeObjectifReserve modeObjectif;

  /// Voir [PolitiqueReserve.montantCible].
  final Montant? montantCible;

  /// Voir [PolitiqueReserve.nombreMois].
  final int? nombreMois;

  /// Voir [PolitiqueReserve.regleAlimentation].
  final RegleAlimentation regleAlimentation;

  /// Voir [PolitiqueReserve.montantAuto].
  final Montant? montantAuto;

  /// Voir [PolitiqueReserve.pourcentageAutoPourMille].
  final int? pourcentageAutoPourMille;

  /// Voir [PolitiqueReserve.cadence].
  final CadenceAlimentation cadence;

  /// Voir [PolitiqueReserve.seuilAlertePourMille].
  final int? seuilAlertePourMille;

  /// Voir [PolitiqueReserve.retraitSoumisValidation].
  final bool retraitSoumisValidation;
}

/// La politique de la Reserve (CPT-BR-12).
abstract interface class PortPolitiqueReserve {
  /// La politique en vigueur (lecture : Comptable et Direction).
  Future<PolitiqueReserve> politique();

  /// Les indicateurs §9.7 (lecture : W01, W04).
  Future<IndicateursReserve> indicateurs();

  /// Enregistre une nouvelle version (Direction seulement, cle
  /// d'idempotence) et rend la politique telle que la source l'a gardee.
  Future<PolitiqueReserve> enregistrer({
    required BrouillonPolitiqueReserve brouillon,
    required String cleIdempotence,
  });

  /// Le journal des versions (CPT-BR-17).
  Future<List<EntreeJournal>> journal();
}

/// **Aucune source serveur a ce jour** (CPT-BR-12).
class PolitiqueReserveIndisponible implements PortPolitiqueReserve {
  /// Cree l'implementation.
  const PolitiqueReserveIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-12');

  @override
  Future<PolitiqueReserve> politique() =>
      Future<PolitiqueReserve>.error(_manque);

  @override
  Future<IndicateursReserve> indicateurs() =>
      Future<IndicateursReserve>.error(_manque);

  @override
  Future<PolitiqueReserve> enregistrer({
    required BrouillonPolitiqueReserve brouillon,
    required String cleIdempotence,
  }) => Future<PolitiqueReserve>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal() =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`direction_demo.dart`, lu aussi
/// par `tresorerie_demo.dart`).
final Provider<PortPolitiqueReserve> portPolitiqueReserveProvider =
    Provider<PortPolitiqueReserve>(
      (Ref _) => const PolitiqueReserveIndisponible(),
    );
