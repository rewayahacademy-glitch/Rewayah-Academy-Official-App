// Mes moyens de paiement, geres par le beneficiaire lui-meme (spec §17, §19,
// §20, §38 ; CPT-BR-16). Pose par CPT-F avec son interface complete ;
// **propriete de la voie CPT-BEN ensuite** (`20_comptable/02_DECOUPAGE.md`,
// liste B).
//
// Le beneficiaire seul ajoute, remplace, supprime, choisit sa methode
// preferee (R-FIN-13). Un changement est sensible (§19) : la source rend les
// etats, l'app n'en invente aucun. **La saisie des coordonnees se fait chez
// le prestataire ou dans un champ chiffre jamais conserve par l'app** : le
// brouillon ci-dessous ne porte que le jeton rendu par ce parcours, jamais
// un numero.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import 'capacite_indisponible.dart';

/// Une methode de paiement personnelle, masquee par la source.
@immutable
class MoyenPaiementPersonnel {
  /// Cree la methode.
  const MoyenPaiementPersonnel({
    required this.id,
    required this.destination,
    required this.preferee,
    this.active = true,
  });

  /// L'identifiant de la methode.
  final String id;

  /// La destination masquee.
  final DestinationMasquee destination;

  /// Vrai pour la methode preferee.
  final bool preferee;

  /// Faux quand l'ancienne methode est conservee inactive (§19).
  final bool active;
}

/// L'etat de « Recevoir mes paiements ».
@immutable
class EtatMesMoyensPaiement {
  /// Cree l'etat.
  const EtatMesMoyensPaiement({
    required this.etat,
    this.moyens = const <MoyenPaiementPersonnel>[],
    this.payoutSuspenduTemporairement = false,
    this.peutAjouter = true,
    this.corridorsProposes = const <String>[],
  });

  /// L'etat global (§38).
  final EtatProfilPaiement etat;

  /// Les methodes.
  final List<MoyenPaiementPersonnel> moyens;

  /// Vrai pendant la verification d'une nouvelle methode (§19).
  final bool payoutSuspenduTemporairement;

  /// Vrai si la source accepte un ajout maintenant.
  final bool peutAjouter;

  /// Les types de methode proposes au choix (K-57), rendus par la source.
  final List<String> corridorsProposes;
}

/// Le brouillon d'une methode : le **jeton** rendu par le parcours de saisie
/// chez le prestataire ou par le champ chiffre, jamais la coordonnee.
@immutable
class BrouillonMoyenPaiement {
  /// Cree le brouillon.
  const BrouillonMoyenPaiement({
    required this.type,
    required this.pays,
    required this.devise,
    required this.jetonSaisie,
    this.operateur,
    this.preferee = false,
  });

  /// Le type (« Mobile money », « Compte bancaire »).
  final String type;

  /// L'operateur, s'il compte.
  final String? operateur;

  /// Le pays.
  final String pays;

  /// La devise.
  final String devise;

  /// Le jeton opaque de la saisie securisee.
  final String jetonSaisie;

  /// Vrai pour en faire la methode preferee.
  final bool preferee;
}

/// Ce que rend le parcours de saisie securisee (CPT-BEN-2) : un **jeton
/// opaque** et ce que la personne a choisi chez le prestataire (pays,
/// devise, operateur). Jamais un numero, un IBAN ou un nom de titulaire :
/// l'app ne les voit pas.
@immutable
class SaisieSecurisee {
  /// Cree le retour.
  const SaisieSecurisee({
    required this.jeton,
    required this.pays,
    required this.devise,
    this.operateur,
  });

  /// Le jeton opaque, a passer tel quel dans [BrouillonMoyenPaiement].
  final String jeton;

  /// Le pays choisi pendant la saisie.
  final String pays;

  /// La devise de la methode.
  final String devise;

  /// L'operateur, s'il compte.
  final String? operateur;
}

/// Mes moyens de paiement (CPT-BR-16).
abstract interface class PortMesMoyensPaiement {
  /// L'etat courant.
  Future<EtatMesMoyensPaiement> etat();

  /// Ouvre la saisie securisee d'une methode de type [type] (chez le
  /// prestataire, ou champ chiffre jamais conserve) et rend son jeton.
  /// Ajoute par CPT-BEN-2 : sans lui, le brouillon n'a aucune source de
  /// jeton (ligne pour CPT-BR-16).
  Future<SaisieSecurisee> ouvrirSaisieSecurisee(String type);

  /// Ajoute une methode (verification a suivre, §19).
  Future<EtatMesMoyensPaiement> ajouter(BrouillonMoyenPaiement brouillon);

  /// Remplace une methode par une nouvelle.
  Future<EtatMesMoyensPaiement> remplacer({
    required String moyenId,
    required BrouillonMoyenPaiement brouillon,
  });

  /// Supprime une methode.
  Future<EtatMesMoyensPaiement> supprimer(String moyenId);

  /// Choisit la methode preferee.
  Future<EtatMesMoyensPaiement> choisirPreferee(String moyenId);

  /// Le journal de mes changements (CPT-BR-17).
  Future<List<EntreeJournal>> journal();
}

/// **Aucune source serveur a ce jour** (CPT-BR-16).
class MesMoyensPaiementIndisponibles implements PortMesMoyensPaiement {
  /// Cree l'implementation.
  const MesMoyensPaiementIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('CPT-BR-16');

  @override
  Future<EtatMesMoyensPaiement> etat() =>
      Future<EtatMesMoyensPaiement>.error(_manque);

  @override
  Future<SaisieSecurisee> ouvrirSaisieSecurisee(String type) =>
      Future<SaisieSecurisee>.error(_manque);

  @override
  Future<EtatMesMoyensPaiement> ajouter(BrouillonMoyenPaiement brouillon) =>
      Future<EtatMesMoyensPaiement>.error(_manque);

  @override
  Future<EtatMesMoyensPaiement> remplacer({
    required String moyenId,
    required BrouillonMoyenPaiement brouillon,
  }) => Future<EtatMesMoyensPaiement>.error(_manque);

  @override
  Future<EtatMesMoyensPaiement> supprimer(String moyenId) =>
      Future<EtatMesMoyensPaiement>.error(_manque);

  @override
  Future<EtatMesMoyensPaiement> choisirPreferee(String moyenId) =>
      Future<EtatMesMoyensPaiement>.error(_manque);

  @override
  Future<List<EntreeJournal>> journal() =>
      Future<List<EntreeJournal>>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`beneficiaires_demo.dart`).
final Provider<PortMesMoyensPaiement> portMesMoyensPaiementProvider =
    Provider<PortMesMoyensPaiement>(
      (Ref _) => const MesMoyensPaiementIndisponibles(),
    );
