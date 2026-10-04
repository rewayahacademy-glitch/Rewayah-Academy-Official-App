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

/// Ce que la source dit de la place d'un eleve apres une periode non
/// financee (FI-BR-08, guide Finance V4 §1.7, §8 F5). **Rendu par le serveur,
/// jamais deduit par l'ecran** : ni d'une date, ni d'un solde. `null` (cas
/// ordinaire, et toujours en production tant que FI-BR-08 manque) : rien a
/// dire de plus que l'ouverture des seances.
enum EtatPlace {
  /// La conservation de la place (7 jours au lancement, selon la politique)
  /// est terminee : la place est liberee et l'acces aux seances payantes est
  /// suspendu. **Le compte reste ouvert** (guide §1.7) : historique, contenus
  /// acquis et paiements restent lisibles.
  liberee,

  /// Une periode est de nouveau financee apres une suspension : l'acces aux
  /// seances payantes est reactive.
  reactivee,
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
    this.place,
    this.datePlace,
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
  /// application) attend DB-FOY-05. Jamais affiche brut. La suspension et la
  /// reactivation passent par [place] (FI-BR-08).
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

  /// Place liberee (acces suspendu) ou acces reactive, rendu par la source
  /// (FI-BR-08) ; `null` sinon. Le tuteur et l'adulte autonome le lisent ;
  /// l'enfant n'en lit que l'ouverture des seances, sa copie reste neutre.
  final EtatPlace? place;

  /// Le jour ou la place a ete liberee ou l'acces reactive, quand la source
  /// le rend.
  final DateTime? datePlace;
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

/// L'acces de la personne connectee, eleve (enfant ou adulte autonome) :
/// contrat FI-BR-08, revue FI-VAGUE-R (R4-02).
///
/// Pourquoi un port a part plutot qu'un filtre a l'ecran : [PortAccesFoyer]
/// rend le foyer entier, pour le titulaire. Filtrer a l'ecran chargerait
/// quand meme les prenoms et l'ouverture des freres et soeurs sur l'appareil
/// de l'enfant. Ici, le perimetre est celui de la session, comme
/// `PortMesFinances` : le serveur ne rend que la ligne de la personne
/// connectee, et l'ecran n'a aucun identifiant a fournir (donc aucun a
/// falsifier). **Sans montant ni cause** : la meme ligne que
/// [AccesBeneficiaire].
abstract interface class PortMonAcces {
  /// L'acces de la seule personne connectee, `null` quand elle n'a pas de
  /// ligne d'acces (tuteur, enseignant, eleve pas encore inscrit).
  Future<AccesBeneficiaire?> monAcces();
}

/// **Aucune source serveur a ce jour** (FI-BR-08).
class MonAccesIndisponible implements PortMonAcces {
  /// Cree l'implementation.
  const MonAccesIndisponible();

  @override
  Future<AccesBeneficiaire?> monAcces() =>
      Future<AccesBeneficiaire?>.error(const CapaciteIndisponible('FI-BR-08'));
}

/// L'acces de la personne connectee employe par l'application ; la
/// demonstration et les tests le surchargent.
final Provider<PortMonAcces> portMonAccesProvider = Provider<PortMonAcces>(
  (Ref ref) => const MonAccesIndisponible(),
);
