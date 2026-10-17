// Les paiements recus hors application, saisis par la direction (passation
// du 17/10/2026, point 3 ; FAC-C-01, migration 20261017172000 ; FI-BR-14).
//
// La source rend la liste des eleves avec leur reste a payer, arrete par le
// serveur ; l'ecran n'additionne rien (FI6). Enregistrer un paiement le
// credite a l'eleve, emet sa facture du mois et la finance si le paiement la
// couvre : l'ecran affiche l'etat financier RENDU, jamais un etat deduit.
// Une cle d'idempotence, tiree une fois par saisie, rend un second envoi
// sans effet.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/finances_profil.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Un eleve que la saisie peut viser.
@immutable
class ElevePourPaiement {
  /// Cree la ligne.
  const ElevePourPaiement({
    required this.profilId,
    required this.prenom,
    required this.resteAPayer,
    this.nom,
    this.matricule,
  });

  /// Le profil eleve.
  final String profilId;

  /// Le prenom.
  final String prenom;

  /// Le nom de famille, s'il est connu.
  final String? nom;

  /// Le matricule (`RA-26-4817`), s'il est connu.
  final String? matricule;

  /// Ce qui reste a payer, arrete par le serveur (zero : a jour).
  final Montant resteAPayer;
}

/// Un paiement enregistre, tel que la source le rend.
@immutable
class PaiementEnregistre {
  /// Cree le resultat.
  const PaiementEnregistre({
    required this.paiementId,
    required this.nouveau,
    this.finance,
  });

  /// L'identifiant de l'ecriture.
  final String paiementId;

  /// Faux quand la meme saisie avait deja ete enregistree.
  final bool nouveau;

  /// L'etat financier de l'eleve apres le paiement, ou `null`.
  final FinancesProfil? finance;
}

/// Les factures d'un mois, emises par la source (FAC-B-01).
@immutable
class FacturesEmises {
  /// Cree le resultat.
  const FacturesEmises({required this.emises, required this.financees});

  /// Les factures creees par cet envoi (zero si tout etait deja emis).
  final int emises;

  /// Les mois reglees aussitot par les credits deja recus.
  final int financees;
}

/// Pourquoi la source refuse une saisie.
enum MotifRefusPaiement {
  /// La personne connectee n'a pas le droit de saisir.
  droits,

  /// Montant, devise, eleve ou mois refuses.
  invalide,

  /// Aucun prix publie pour le mois demande.
  sansPolitique,
}

/// La source a refuse la saisie : rien n'a ete enregistre.
class RefusPaiement implements Exception {
  /// Cree le refus.
  const RefusPaiement(this.motif);

  /// La raison.
  final MotifRefusPaiement motif;

  @override
  String toString() => 'RefusPaiement(${motif.name})';
}

/// La saisie des paiements recus.
abstract interface class PortPaiementsSaisis {
  /// Les eleves, le plus a regulariser d'abord.
  Future<List<ElevePourPaiement>> eleves();

  /// Enregistre [montant] recu pour [profilId], avec une [reference]
  /// facultative. [cle] est tiree une fois par saisie et rejouee telle
  /// quelle. Leve [RefusPaiement] quand la source refuse.
  Future<PaiementEnregistre> enregistrer({
    required String profilId,
    required Montant montant,
    required String cle,
    String? reference,
  });

  /// Emet les factures de [mois] (le premier jour du mois) pour tous les
  /// eleves ; une facture deja emise ne l'est jamais deux fois. Leve
  /// [RefusPaiement] quand la source refuse.
  Future<FacturesEmises> emettreFactures(DateTime mois);
}

/// Aucune source : l'ecran dit « Pas encore disponible ».
class PaiementsSaisisIndisponibles implements PortPaiementsSaisis {
  /// Cree l'implementation.
  const PaiementsSaisisIndisponibles();

  @override
  Future<List<ElevePourPaiement>> eleves() =>
      Future<List<ElevePourPaiement>>.error(
        const CapaciteIndisponible('FI-BR-14'),
      );

  @override
  Future<PaiementEnregistre> enregistrer({
    required String profilId,
    required Montant montant,
    required String cle,
    String? reference,
  }) =>
      Future<PaiementEnregistre>.error(const CapaciteIndisponible('FI-BR-14'));

  @override
  Future<FacturesEmises> emettreFactures(DateTime mois) =>
      Future<FacturesEmises>.error(const CapaciteIndisponible('FI-BR-14'));
}

/// La saisie des paiements ; indisponible tant que rien ne la surcharge.
final Provider<PortPaiementsSaisis> portPaiementsSaisisProvider =
    Provider<PortPaiementsSaisis>(
      (Ref _) => const PaiementsSaisisIndisponibles(),
    );
