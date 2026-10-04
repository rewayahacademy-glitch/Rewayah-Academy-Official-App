// La tresorerie et les coffres (spec §8, §10, §11, §32 ; CPT-BR-04, 05).
// Pose par CPT-F avec son interface complete ; **propriete de la voie
// CPT-TRES ensuite** (`20_comptable/02_DECOUPAGE.md`, liste B).
//
// Tresorerie detenue, fonds proteges, en transit, **tresorerie libre**
// (centrale), les sept coffres (montant, part en pour mille, regle), les
// mouvements permis par la politique et le transfert interne : vers une
// protection = delegable, sortie d'un coffre protege = sensible ; les quatre
// interdits §10.4 sont refuses par le serveur, jamais contournes ici. La
// prevision est une liste datee, pas une serie graphique (DR-09).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Une ligne de prevision datee (§32).
@immutable
class LignePrevision {
  /// Cree la ligne.
  const LignePrevision({
    required this.date,
    required this.libelle,
    required this.montant,
    this.entree = false,
  });

  /// La date.
  final DateTime date;

  /// Ce qui est attendu (« Paie d'octobre », « Encaissements consolides »).
  final String libelle;

  /// Le montant.
  final Montant montant;

  /// Vrai pour une entree, faux pour une sortie.
  final bool entree;
}

/// Un couple de coffres permis par la politique (§10), avec sa sensibilite.
@immutable
class MouvementPermis {
  /// Cree le couple.
  const MouvementPermis({
    required this.origine,
    required this.destination,
    required this.sensible,
    this.montantPropose,
  });

  /// Le coffre d'origine.
  final Coffre origine;

  /// Le coffre de destination.
  final Coffre destination;

  /// Vrai quand le mouvement exige une validation supplementaire (§10.3).
  final bool sensible;

  /// Le montant propose par la politique (manque a completer, allocation
  /// automatique), modifiable (K-57, DR-15).
  final Montant? montantPropose;
}

/// Le filtre de l'historique des allocations.
@immutable
class FiltreHistoriqueTresorerie {
  /// Cree le filtre.
  const FiltreHistoriqueTresorerie({this.coffre, this.depuis});

  /// Tout l'historique.
  static const FiltreHistoriqueTresorerie tout = FiltreHistoriqueTresorerie();

  /// Un seul coffre.
  final Coffre? coffre;

  /// Depuis une date.
  final DateTime? depuis;
}

/// Le resultat d'un mouvement : l'etat rendu, jamais un succes local.
@immutable
class ResultatMouvement {
  /// Cree le resultat.
  const ResultatMouvement({
    required this.mouvementId,
    required this.execute,
    this.validation,
    this.journal,
  });

  /// L'identifiant du mouvement.
  final String mouvementId;

  /// Vrai si execute ; faux si une validation est requise ou s'il est refuse.
  final bool execute;

  /// La demande de validation ouverte, pour un mouvement sensible.
  final EtatDemandeValidation? validation;

  /// L'entree de journal rendue (§48).
  final EntreeJournal? journal;
}

/// La tresorerie (CPT-BR-04, 05).
abstract interface class PortTresorerie {
  /// La synthese : detenue, libre, protegee, transit.
  Future<SyntheseTresorerie> resume();

  /// Les sept coffres, dans l'ordre de `Coffre.values`.
  Future<List<SoldeCoffre>> coffres();

  /// L'historique des allocations (§48).
  Future<List<EntreeJournal>> historique(FiltreHistoriqueTresorerie filtre);

  /// La prevision datee.
  Future<List<LignePrevision>> prevision();

  /// Les mouvements que la politique permet au Comptable.
  Future<List<MouvementPermis>> mouvementsPermis();

  /// Un transfert entre deux coffres, une fois (cle d'idempotence).
  Future<ResultatMouvement> transferer({
    required Coffre origine,
    required Coffre destination,
    required Montant montant,
    required String cleIdempotence,
  });

  /// Le journal d'un mouvement (CPT-BR-17).
  Future<List<EntreeJournal>> journal(String mouvementId);
}

/// **Aucune source serveur a ce jour** (CPT-BR-04).
class TresorerieIndisponible implements PortTresorerie {
  /// Cree l'implementation.
  const TresorerieIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-04');
  static const CapaciteIndisponible _manqueMouvement = CapaciteIndisponible(
    'CPT-BR-05',
  );

  @override
  Future<SyntheseTresorerie> resume() =>
      Future<SyntheseTresorerie>.error(_manque);

  @override
  Future<List<SoldeCoffre>> coffres() =>
      Future<List<SoldeCoffre>>.error(_manque);

  @override
  Future<List<EntreeJournal>> historique(FiltreHistoriqueTresorerie filtre) =>
      Future<List<EntreeJournal>>.error(_manque);

  @override
  Future<List<LignePrevision>> prevision() =>
      Future<List<LignePrevision>>.error(_manque);

  @override
  Future<List<MouvementPermis>> mouvementsPermis() =>
      Future<List<MouvementPermis>>.error(_manqueMouvement);

  @override
  Future<ResultatMouvement> transferer({
    required Coffre origine,
    required Coffre destination,
    required Montant montant,
    required String cleIdempotence,
  }) => Future<ResultatMouvement>.error(_manqueMouvement);

  @override
  Future<List<EntreeJournal>> journal(String mouvementId) =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`tresorerie_demo.dart`).
final Provider<PortTresorerie> portTresorerieProvider =
    Provider<PortTresorerie>((Ref _) => const TresorerieIndisponible());
