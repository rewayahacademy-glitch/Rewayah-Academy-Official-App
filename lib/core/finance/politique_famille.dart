// Ce qu'une famille lit de la politique commerciale (TRANSPARENCE, directeur,
// 30/10/2026 ; migration 20261031100000, `politique_commerciale_famille`).
//
// **Aucune valeur ici** (FI6) : la forme seulement. Ni paie horaire, ni marge,
// ni budget : la politique de la direction (`PolitiqueCommerciale`) ne quitte
// pas la direction et la comptabilite. La repartition du paiement d'un eleve
// est en pour mille, jamais en montants de charges (decision du 22/10).

import 'package:flutter/foundation.dart';

import 'montant.dart';
import 'politique_commerciale.dart' show RailPaiement, RemiseRang;

/// Un poste de la repartition d'un paiement, dans l'ordre ou le serveur les
/// rend (l'enseignant d'abord, le benefice en dernier).
enum PosteRepartition {
  /// La paie de l'enseignant.
  enseignant,

  /// Les frais de paiement par carte et de change.
  fraisCarteChange,

  /// Les frais d'envoi de la paie aux enseignants.
  fraisEnvoiPaie,

  /// La visioconference.
  visioconference,

  /// L'application et son hebergement.
  applicationHebergement,

  /// L'envoi des e-mails.
  emails,

  /// Le stockage des fichiers.
  stockage,

  /// La comptabilite.
  comptabilite,

  /// Le developpement et la maintenance.
  developpement,

  /// L'administration.
  administration,

  /// L'impot sur les societes.
  impotSocietes,

  /// Le benefice de l'academie.
  benefice,
}

/// La part d'un poste, en pour mille du paiement (470 = 47 %).
typedef PartPoste = ({PosteRepartition poste, int pourMille});

/// La repartition estimee d'un paiement, pour une version des prix.
@immutable
class RepartitionPaiement {
  /// Cree la repartition.
  const RepartitionPaiement({
    required this.politiqueVersion,
    required this.dateEffet,
    required this.baseElevesEnfants,
    required this.baseElevesAdultes,
    required this.postes,
  });

  /// La version des prix qu'elle estime.
  final String politiqueVersion;

  /// La date d'effet de cette version.
  final DateTime dateEffet;

  /// La base de calcul : nombre d'enfants.
  final int baseElevesEnfants;

  /// La base de calcul : nombre d'adultes.
  final int baseElevesAdultes;

  /// Les postes, dans l'ordre du serveur ; la somme fait 1000.
  final List<PartPoste> postes;
}

/// La politique commerciale en vigueur, telle qu'une famille la lit.
@immutable
class PolitiqueFamille {
  /// Cree la politique.
  const PolitiqueFamille({
    required this.version,
    required this.dateEffet,
    required this.tarifEnfant,
    required this.tarifAdulte,
    required this.essaiActif,
    required this.essaisMax,
    required this.remisesParRang,
    required this.railsActifs,
    this.repartition,
  });

  /// Le numero de version.
  final String version;

  /// La date d'effet.
  final DateTime dateEffet;

  /// Le tarif mensuel d'un enfant.
  final Montant tarifEnfant;

  /// Le tarif mensuel d'un adulte.
  final Montant tarifAdulte;

  /// Vrai quand l'essai est ouvert.
  final bool essaiActif;

  /// Le nombre de seances d'essai.
  final int essaisMax;

  /// Les remises par rang dans le foyer.
  final List<RemiseRang> remisesParRang;

  /// Les moyens de paiement actifs.
  final Set<RailPaiement> railsActifs;

  /// La repartition du paiement, ou `null` si aucune n'est publiee.
  final RepartitionPaiement? repartition;
}
