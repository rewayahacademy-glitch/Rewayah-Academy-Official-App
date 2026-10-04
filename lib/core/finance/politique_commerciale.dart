// La politique commerciale versionnee (FI-1c, guide Finance V4 §1, §5.7 ;
// FI-BR-01).
//
// **Aucune valeur ici** (FI6) : ce fichier ne porte que la FORME d'une
// politique. Les valeurs de lancement vivent dans
// `lib/features/demo/finance_demo.dart` (demonstration) et, apres BR-1, dans
// la politique effective rendue par le serveur.
//
// Les invariants (idempotence, separation des soldes, historique en ajout
// seul, confirmation avant credit, pas de double debit, acces par periode)
// ne sont JAMAIS des champs (FI22) : ils n'ont pas de place dans ce modele.

import 'package:flutter/foundation.dart';

import 'montant.dart';

/// Un rail de paiement (guide §1.6). Seul [webStripe] est montre au
/// lancement (FI10) ; les deux autres sont prevus, jamais affiches.
enum RailPaiement {
  /// Paiement web par le prestataire (`WEB_STRIPE`), actif au lancement.
  webStripe,

  /// Achat integre iOS (`IOS_STOREKIT`), non active au lancement.
  iosStoreKit,

  /// Facturation Google Play (`ANDROID_PLAY`), non activee au lancement.
  androidPlay,
}

/// Le statut d'une version de politique (guide §5.7).
enum StatutPolitique {
  /// Brouillon, jamais applique.
  brouillon,

  /// Publiee : appliquee a partir de sa date d'effet.
  publiee,
}

/// Une remise par rang de membre payant du foyer (guide §1.3) : a partir du
/// rang [aPartirDuRang], chaque membre payant recoit [remise] (negative).
@immutable
class RemiseRang {
  /// Cree la remise.
  const RemiseRang({required this.aPartirDuRang, required this.remise});

  /// Le premier rang concerne (3 = troisieme membre payant).
  final int aPartirDuRang;

  /// La remise, en unites mineures negatives.
  final Montant remise;
}

/// Une version de la politique commerciale.
@immutable
class PolitiqueCommerciale {
  /// Cree une version.
  const PolitiqueCommerciale({
    required this.version,
    required this.statut,
    required this.dateEffet,
    required this.tarifEnfant,
    required this.tarifAdulte,
    required this.essaisMax,
    required this.remisesParRang,
    required this.baseHoraire,
    required this.plafondHoraire,
    required this.capaciteEnfant,
    required this.capaciteAdulte,
    required this.capaciteDebutant,
    required this.minimumOuverture,
    required this.groupesObjectif,
    required this.groupesMax,
    required this.joursConservationPlace,
    required this.margeReferencePourMille,
    required this.railsActifs,
    this.allocationInternet,
  });

  /// L'identifiant de la version, tel que rendu.
  final String version;

  /// Brouillon ou publiee.
  final StatutPolitique statut;

  /// La date d'effet (jamais retroactive sur une facture payee, §1.3).
  final DateTime dateEffet;

  /// Le tarif academique mensuel d'un enfant, hors taxe (§1.1, §1.8).
  final Montant tarifEnfant;

  /// Le tarif academique mensuel d'un adulte, hors taxe.
  final Montant tarifAdulte;

  /// Le nombre maximal de seances d'essai par nouveau profil (§1.2).
  final int essaisMax;

  /// Les remises par rang, dans l'ordre croissant des rangs. Un rang absent
  /// n'a aucune remise (rangs 1 et 2 au lancement).
  final List<RemiseRang> remisesParRang;

  /// La base horaire garantie de l'enseignant (§1.4).
  final Montant baseHoraire;

  /// Le plafond horaire de l'enseignant.
  final Montant plafondHoraire;

  /// La capacite d'une classe d'enfants.
  final int capaciteEnfant;

  /// La capacite d'une classe d'adultes.
  final int capaciteAdulte;

  /// La capacite d'une classe de debutants.
  final int capaciteDebutant;

  /// Le minimum d'eleves pour ouvrir une classe.
  final int minimumOuverture;

  /// L'objectif courant de classes actives par enseignant.
  final int groupesObjectif;

  /// Le maximum normal de classes actives par enseignant.
  final int groupesMax;

  /// La duree de conservation d'une place non financee, en jours (§1.7).
  final int joursConservationPlace;

  /// La marge de reference de pilotage, en pour mille (300 = 30 %) : objectif,
  /// performance forte, scenario stretch (§1.5). **Jamais une sanction ni un
  /// blocage** (FI21).
  final ({int objectif, int forte, int stretch}) margeReferencePourMille;

  /// Les rails de paiement actifs. Seul `webStripe` au lancement.
  final Set<RailPaiement> railsActifs;

  /// L'allocation Internet par enseignant eligible, ou `null` quand la
  /// politique ne la fixe pas encore (montant configurable, §1.4).
  final Montant? allocationInternet;

  /// La remise du membre payant de rang [rang] (1 = premier), ou `null`
  /// quand ce rang n'en a aucune. Lecture de la politique, jamais un calcul
  /// de prix.
  Montant? remisePourRang(int rang) {
    RemiseRang? retenue;
    for (final RemiseRang r in remisesParRang) {
      if (r.aPartirDuRang <= rang) retenue = r;
    }
    return retenue?.remise;
  }
}

/// La mensualite d'un enfant payant dans un apercu de foyer (FI-11c, guide
/// §5.7) : arretee par la source, jamais calculee dans un widget (FI6).
@immutable
class MensualiteApercu {
  /// Cree la ligne.
  const MensualiteApercu({
    required this.rang,
    required this.tarif,
    required this.mensualite,
    this.remise,
  });

  /// Le rang du membre payant (1 = premier).
  final int rang;

  /// Le tarif applique a ce rang.
  final Montant tarif;

  /// La remise de rang (negative), ou `null` quand ce rang n'en a aucune.
  final Montant? remise;

  /// La mensualite arretee de ce membre.
  final Montant mensualite;
}

/// L'apercu d'un foyer de demonstration pour une version de politique : une
/// mensualite par enfant payant, puis le total du foyer par mois.
@immutable
class ApercuFamille {
  /// Cree l'apercu.
  const ApercuFamille({required this.enfants, required this.total});

  /// Les mensualites, dans l'ordre des rangs.
  final List<MensualiteApercu> enfants;

  /// Le total du foyer par mois, arrete par la source.
  final Montant total;
}

/// L'apercu du taux horaire d'un enseignant pour une classe (guide §1.4) :
/// la base, la part d'occupation et le taux effectif, arretes par la source.
@immutable
class ApercuEnseignant {
  /// Cree l'apercu.
  const ApercuEnseignant({
    required this.capacite,
    required this.eligibles,
    required this.baseHoraire,
    required this.occupation,
    required this.tauxHoraire,
    required this.plafondHoraire,
  });

  /// La capacite de la classe.
  final int capacite;

  /// Les sieges eligibles retenus (periode financee).
  final int eligibles;

  /// La base horaire garantie.
  final Montant baseHoraire;

  /// La part d'occupation, par heure.
  final Montant occupation;

  /// Le taux horaire effectif.
  final Montant tauxHoraire;

  /// Le plafond horaire.
  final Montant plafondHoraire;
}
