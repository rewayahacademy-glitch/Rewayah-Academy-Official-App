// Les revenus estimes de l'enseignant (FI-1c, guide Finance V4 §1.4, §5.5 ;
// FI-BR-11).
//
// **Une estimation, marquee comme telle** (FI20) : base garantie +
// occupation, plafonnee ; aide Internet a part ; jamais un solde de famille
// ni un montant paye par un eleve ; aucun bonus « classe pleine ». Le calcul
// vit dans la source (ou dans le double de demonstration du port), jamais
// dans un widget.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Les revenus estimes d'une classe sur la periode.
@immutable
class RevenusClasse {
  /// Cree la ligne.
  const RevenusClasse({
    required this.classeId,
    required this.classe,
    required this.minutesAssurees,
    required this.capacite,
    required this.siegesEligibles,
    required this.tauxHoraireEffectif,
    required this.montantEstime,
  });

  /// L'identifiant de la classe.
  final String classeId;

  /// Le nom propre de la classe (« An-Nour ») ; l'ecran ecrit « Classe »
  /// devant, jamais « groupe ».
  final String classe;

  /// La duree assuree sur la periode, en minutes.
  final int minutesAssurees;

  /// La capacite effective de la classe.
  final int capacite;

  /// Les sieges eligibles (finance present ou absent, essai present ; jamais
  /// au-dela de la capacite).
  final int siegesEligibles;

  /// Le taux horaire effectif, jamais au-dessus du plafond de la politique.
  final Montant tauxHoraireEffectif;

  /// Le montant estime pour cette classe.
  final Montant montantEstime;
}

/// Les revenus estimes de l'enseignant sur une periode.
@immutable
class RevenusEnseignant {
  /// Cree la vue.
  const RevenusEnseignant({
    required this.debut,
    required this.fin,
    required this.classes,
    required this.totalEstime,
    required this.baseHoraire,
    required this.plafondHoraire,
    this.allocationInternet,
  });

  /// Le debut de la periode.
  final DateTime debut;

  /// La fin de la periode.
  final DateTime fin;

  /// Le detail par classe, dans l'ordre rendu.
  final List<RevenusClasse> classes;

  /// Le total estime de la remuneration pedagogique, hors aide Internet.
  final Montant totalEstime;

  /// La base horaire garantie de la politique appliquee (guide §1.4) :
  /// l'ecran l'explique, il ne s'en sert pour aucun calcul.
  final Montant baseHoraire;

  /// Le plafond horaire de la politique appliquee : aucun taux effectif ne
  /// le depasse (guide §1.4, §8 F6).
  final Montant plafondHoraire;

  /// L'aide Internet, a part ; `null` quand l'enseignant n'y est pas
  /// eligible.
  final Montant? allocationInternet;
}

/// Les revenus de l'enseignant connecte.
abstract interface class PortRevenusEnseignant {
  /// Les revenus estimes du mois en cours (FI-BR-11).
  Future<RevenusEnseignant> moisEnCours();
}

/// **Aucune source serveur a ce jour** (FI-BR-11).
class RevenusEnseignantIndisponibles implements PortRevenusEnseignant {
  /// Cree l'implementation.
  const RevenusEnseignantIndisponibles();

  @override
  Future<RevenusEnseignant> moisEnCours() =>
      Future<RevenusEnseignant>.error(const CapaciteIndisponible('FI-BR-11'));
}

/// Le port des revenus ; la demonstration le surcharge.
final Provider<PortRevenusEnseignant> portRevenusEnseignantProvider =
    Provider<PortRevenusEnseignant>(
      (Ref _) => const RevenusEnseignantIndisponibles(),
    );
