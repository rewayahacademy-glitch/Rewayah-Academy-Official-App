// Versements de paie notes par la direction (lot FINANCE-ENSEIGNANT,
// 06/11/2026, socle commun aux deux options posees au directeur ; migration
// 20261110710000).
//
// La direction ou la comptabilite **note** un versement fait hors de
// l'application (virement, mobile money) ; l'enseignant le voit. Aucun
// prestataire, aucun calcul : le montant est celui que la direction a verse,
// la tresorerie est ecrite par le serveur. La reference est celle de
// l'operation, jamais un numero de compte (le serveur refuse les espaces).
//
// Ou l'afficher n'est pas tranche ici : l'ecran des revenus de l'enseignant
// appartient au lot REVENUS-VERITE, l'ecran Finance de la direction a
// `features/admin_finance`. Ce port est le point d'entree des deux.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Le moyen par lequel la direction a verse.
enum MoyenVersement {
  /// Virement bancaire.
  virementBancaire,

  /// Mobile money (Orange Money, Wave...).
  mobileMoney,

  /// Autre moyen.
  autre,
}

/// Un versement de paie, tel que le serveur le rend.
@immutable
class VersementPaie {
  /// Cree le versement.
  const VersementPaie({
    required this.id,
    required this.montant,
    required this.verseLe,
    required this.mois,
    required this.moyen,
    required this.annule,
    this.reference,
    this.enseignantId,
    this.enseignantNom,
    this.note,
    this.annuleMotif,
  });

  /// L'identifiant.
  final String id;

  /// Le montant verse.
  final Montant montant;

  /// La date du versement.
  final DateTime verseLe;

  /// Le mois de paie concerne (premier jour du mois).
  final DateTime mois;

  /// Le moyen.
  final MoyenVersement moyen;

  /// Vrai si la direction l'a annule (la ligne reste).
  final bool annule;

  /// La reference de l'operation, si notee.
  final String? reference;

  /// L'enseignant (lecture de la direction seulement).
  final String? enseignantId;

  /// Son prenom et son nom (lecture de la direction seulement).
  final String? enseignantNom;

  /// La note interne (lecture de la direction seulement).
  final String? note;

  /// Le motif d'annulation (lecture de la direction seulement).
  final String? annuleMotif;
}

/// Ce que la direction note.
@immutable
class VersementANoter {
  /// Cree la saisie.
  const VersementANoter({
    required this.enseignantId,
    required this.montant,
    required this.verseLe,
    required this.mois,
    required this.moyen,
    required this.cle,
    this.reference,
    this.note,
  });

  /// L'enseignant paye.
  final String enseignantId;

  /// Le montant verse.
  final Montant montant;

  /// La date du versement.
  final DateTime verseLe;

  /// Le mois de paie.
  final DateTime mois;

  /// Le moyen.
  final MoyenVersement moyen;

  /// La cle d'idempotence (un double appui ne note qu'un versement).
  final String cle;

  /// La reference de l'operation.
  final String? reference;

  /// Une note interne.
  final String? note;
}

/// Les versements de paie notes.
abstract interface class PortVersementsPaie {
  /// Mes versements (l'enseignant connecte).
  Future<List<VersementPaie>> mesVersements();

  /// Les versements notes, pour la direction ([mois] nul : tous).
  Future<List<VersementPaie>> versementsDirection({DateTime? mois});

  /// Note un versement (direction, comptabilite).
  Future<VersementPaie> noter(VersementANoter versement);

  /// Annule un versement note par erreur, avec un motif.
  Future<VersementPaie> annuler({
    required String versementId,
    required String motif,
  });
}

/// Aucune source : la migration n'est pas installee.
class VersementsPaieIndisponibles implements PortVersementsPaie {
  /// Cree l'implementation.
  const VersementsPaieIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible(
    'VERSEMENTS-PAIE',
  );

  @override
  Future<List<VersementPaie>> mesVersements() =>
      Future<List<VersementPaie>>.error(_manque);

  @override
  Future<List<VersementPaie>> versementsDirection({DateTime? mois}) =>
      Future<List<VersementPaie>>.error(_manque);

  @override
  Future<VersementPaie> noter(VersementANoter versement) =>
      Future<VersementPaie>.error(_manque);

  @override
  Future<VersementPaie> annuler({
    required String versementId,
    required String motif,
  }) => Future<VersementPaie>.error(_manque);
}

/// Le port ; la production le surcharge dans `main.dart`.
final Provider<PortVersementsPaie> portVersementsPaieProvider =
    Provider<PortVersementsPaie>(
      (Ref _) => const VersementsPaieIndisponibles(),
    );
