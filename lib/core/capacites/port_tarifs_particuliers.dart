// Lot (A), 02/11/2026 : les remises particulieres accordees par la direction,
// eleve par eleve (« Accès offert », « Prix spécial »), avec une raison et un
// mois de fin. Demande du directeur : aucune valeur en dur, la direction les
// saisit dans l'application.
//
// La source rend la liste des remises actives (`bourses_lister`) ; accorder
// (`accorder_tarif_particulier`) et retirer (`retirer_bourse`) passent par le
// serveur, qui verifie les droits et les valeurs. L'ecran ne calcule rien :
// la facture du mois applique la remise (ligne « bourse » existante).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// La nature d'une remise active.
enum NatureTarif {
  /// Bourse de la politique commerciale (taux, duree et quota de la
  /// politique).
  bourse,

  /// Acces offert : 100 %, jusqu'au mois choisi.
  accesOffert,

  /// Prix special : la reduction ou le prix mensuel choisis, jusqu'au mois
  /// choisi.
  prixSpecial,
}

/// Une remise active d'un eleve.
@immutable
class TarifParticulier {
  /// Cree la remise.
  const TarifParticulier({
    required this.profilId,
    required this.prenom,
    required this.nature,
    required this.moisFin,
    required this.motif,
    this.pourMille,
    this.montantMensuel,
    this.nom,
    this.matricule,
  });

  /// L'eleve.
  final String profilId;

  /// Son prenom.
  final String prenom;

  /// Son nom, s'il est rendu.
  final String? nom;

  /// Son matricule, s'il est rendu.
  final String? matricule;

  /// La nature de la remise.
  final NatureTarif nature;

  /// La reduction, en pour mille du tarif (1000 pour un acces offert) ;
  /// nulle pour un prix special en montant.
  final int? pourMille;

  /// Le prix du mois hors taxes d'un prix special en montant ; nul sinon.
  final Montant? montantMensuel;

  /// Le dernier mois couvert (premier jour du mois).
  final DateTime moisFin;

  /// La raison saisie par la direction.
  final String motif;
}

/// Pourquoi le serveur a refuse : rien n'a ete enregistre.
enum MotifRefusTarif {
  /// Pas la direction.
  droits,

  /// Une valeur refusee (reduction, mois de fin, raison).
  invalide,

  /// L'eleve a deja une remise active : la retirer d'abord.
  dejaActive,

  /// Le prix mensuel n'est pas inferieur au prix normal de l'eleve.
  montantTropHaut,
}

/// Le refus du serveur.
class RefusTarif implements Exception {
  /// Cree le refus.
  const RefusTarif(this.motif);

  /// Le motif.
  final MotifRefusTarif motif;

  @override
  String toString() => 'RefusTarif(${motif.name})';
}

/// La source des remises particulieres.
abstract interface class PortTarifsParticuliers {
  /// Les remises actives.
  Future<List<TarifParticulier>> liste();

  /// Accorde a [profilId] un acces offert ([pourMille] et [montant]
  /// ignores) ou un prix special (exactement un de [pourMille], de 1 a 999,
  /// et [montant], le prix du mois hors taxes) jusqu'a [moisFin], pour
  /// [motif].
  Future<void> accorder({
    required String profilId,
    required NatureTarif nature,
    required DateTime moisFin,
    required String motif,
    int? pourMille,
    Montant? montant,
  });

  /// Retire la remise active de [profilId], pour [motif].
  Future<void> retirer({required String profilId, required String motif});
}

/// Sans source : rien n'est invente.
class TarifsParticuliersIndisponibles implements PortTarifsParticuliers {
  /// Cree la source neutre.
  const TarifsParticuliersIndisponibles();

  @override
  Future<List<TarifParticulier>> liste() =>
      Future<List<TarifParticulier>>.error(
        const CapaciteIndisponible('FAC-E-01'),
      );

  @override
  Future<void> accorder({
    required String profilId,
    required NatureTarif nature,
    required DateTime moisFin,
    required String motif,
    int? pourMille,
    Montant? montant,
  }) => Future<void>.error(const CapaciteIndisponible('FAC-E-01'));

  @override
  Future<void> retirer({required String profilId, required String motif}) =>
      Future<void>.error(const CapaciteIndisponible('FAC-E-01'));
}

/// La source des remises particulieres ; neutre sauf surcharge.
final Provider<PortTarifsParticuliers> portTarifsParticuliersProvider =
    Provider<PortTarifsParticuliers>(
      (Ref ref) => const TarifsParticuliersIndisponibles(),
    );
