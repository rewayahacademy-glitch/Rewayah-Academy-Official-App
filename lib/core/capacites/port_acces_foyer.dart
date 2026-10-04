import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Ce que l'ecran peut dire de l'acces d'un eleve.
enum EtatAccesAffiche {
  /// Aucune echeance : le cas ordinaire d'un compte valide.
  sansEcheance,

  /// Une echeance a venir.
  actif,

  /// L'echeance est passee. **Calcul d'affichage**, pas un statut serveur.
  expire,
}

/// L'etat affichable d'une echeance d'acces a un instant donne.
///
/// Pure. Une date passee se dit « expiree », jamais « valide » (DB-FOY-05) ;
/// l'instant d'echeance lui-meme est deja passe.
EtatAccesAffiche etatAccesAffiche({
  required DateTime? finAcces,
  required DateTime maintenantUtc,
}) {
  final DateTime? fin = finAcces?.toUtc();
  if (fin == null) {
    return EtatAccesAffiche.sansEcheance;
  }
  return maintenantUtc.toUtc().isBefore(fin)
      ? EtatAccesAffiche.actif
      : EtatAccesAffiche.expire;
}

/// L'acces d'un eleve du foyer.
///
/// **Jamais « abonnement »** : un acces date n'est pas un paiement recurrent.
@immutable
class AccesBeneficiaire {
  /// Cree l'acces.
  const AccesBeneficiaire({
    required this.eleveId,
    required this.prenom,
    required this.etatAffiche,
    this.finAcces,
    this.statutServeur,
    this.motif,
    this.seancesPayantesOuvertes,
    this.essaisUtilises,
    this.essaisMax,
  });

  /// L'eleve.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// La fin d'acces (`profiles.access_until`). `null` : sans echeance.
  final DateTime? finAcces;

  /// Ce que l'ecran dit de l'echeance.
  final EtatAccesAffiche etatAffiche;

  /// **Reserve**, toujours `null` : le statut detaille (offert, paye hors
  /// application, suspendu) attend DB-FOY-05. Jamais affiche brut.
  final String? statutServeur;

  /// **Reserve**, toujours `null` (DB-FOY-05). Jamais affiche brut.
  final String? motif;

  /// Vrai quand les seances payantes sont ouvertes (periode financee, FI2,
  /// FI-BR-08), faux sinon, `null` quand la source ne le rend pas encore.
  /// **Aucune cause ni montant** : l'enfant lit cet etat, jamais pourquoi
  /// (FI12, guide §1.7).
  final bool? seancesPayantesOuvertes;

  /// Les seances d'essai deja utilisees, `null` hors essai (FI4).
  final int? essaisUtilises;

  /// Le nombre maximal d'essais rendu par la politique, `null` hors essai.
  final int? essaisMax;
}

/// L'acces des eleves du foyer (contrat K6, consommateurs : Compte, fiche
/// eleve).
abstract interface class PortAccesFoyer {
  /// Un acces par eleve du foyer.
  Future<List<AccesBeneficiaire>> acces();
}

/// L'acces tant que son adaptateur n'est pas livre.
///
/// **Branchable sans backend** : `EleveDuFoyer.finAcces` (`profils_du_foyer_v`)
/// porte deja l'echeance. L'adaptateur reel
/// `lib/core/capacites/acces_foyer_depuis_eleves.dart` est ecrit par le **lot
/// E** ; le lot B (fiche eleve) lit le meme provider, jamais le fichier de E.
/// E remplace alors l'implementation ci-dessous.
class AccesFoyerIndisponible implements PortAccesFoyer {
  /// Cree l'implementation.
  const AccesFoyerIndisponible();

  @override
  Future<List<AccesBeneficiaire>> acces() =>
      Future<List<AccesBeneficiaire>>.error(
        const CapaciteIndisponible('LOT-E'),
      );
}

/// L'acces du foyer employe par l'application.
final Provider<PortAccesFoyer> portAccesFoyerProvider =
    Provider<PortAccesFoyer>((Ref ref) => const AccesFoyerIndisponible());
