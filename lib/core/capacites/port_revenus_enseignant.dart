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

/// Le type d'une classe, qui fixe sa capacite de politique (guide §1.4 :
/// enfant 5, debutant 4, adulte 6). L'ecran le nomme, il n'en deduit rien.
enum TypeClasseRevenus {
  /// Classe d'enfants, capacite standard.
  enfants,

  /// Classe d'enfants debutants.
  debutants,

  /// Classe d'adultes.
  adultes,
}

/// Les revenus estimes d'une classe sur la periode.
@immutable
class RevenusClasse {
  /// Cree la ligne.
  const RevenusClasse({
    required this.classeId,
    required this.classe,
    required this.type,
    required this.minutesAssurees,
    required this.capacite,
    required this.siegesEligibles,
    required this.tauxHoraireEffectif,
    required this.montantEstime,
    this.enRemplacement = false,
  });

  /// L'identifiant de la classe.
  final String classeId;

  /// Le nom propre de la classe (« An-Nour ») ; l'ecran ecrit « Classe »
  /// devant, jamais « groupe ».
  final String classe;

  /// Le type de la classe (FI-BR-11).
  final TypeClasseRevenus type;

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

  /// Vrai quand l'enseignant n'est pas le titulaire de la classe et y a
  /// assure des seances en remplacement. Choix de contrat (revue FI-VAGUE-R,
  /// R5-01) : la seance est remuneree a celui qui l'assure, au taux de la
  /// classe ; la ligne ne porte que les minutes assurees par cet enseignant,
  /// et le titulaire ne les retrouve pas dans ses propres revenus.
  final bool enRemplacement;
}

/// La ligne de total du detail par classe, telle que la source la rend
/// (FI-BR-11) : l'ecran n'additionne ni ne divise rien.
@immutable
class TotalRevenus {
  /// Cree le total.
  const TotalRevenus({
    required this.minutesAssurees,
    required this.capacite,
    required this.siegesEligibles,
    required this.tauxHoraireMoyen,
  });

  /// La duree assuree sur la periode, toutes classes, en minutes.
  final int minutesAssurees;

  /// La somme des capacites des classes.
  final int capacite;

  /// La somme des sieges eligibles des classes.
  final int siegesEligibles;

  /// Le taux horaire moyen de la periode : le total estime rapporte aux
  /// heures assurees, calcule par la source. Jamais au-dessus du plafond.
  final Montant tauxHoraireMoyen;
}

/// Un mois du releve arrete par l'academie (guide §4, FI-BR-11). Aucun statut
/// « paye » : la paie reelle et son versement sont hors lot (ADR-007), le
/// releve dit seulement ce que l'academie a arrete.
@immutable
class LigneReleve {
  /// Cree la ligne.
  const LigneReleve({
    required this.mois,
    required this.minutesAssurees,
    required this.montant,
  });

  /// Le premier jour du mois arrete.
  final DateTime mois;

  /// La duree assuree sur ce mois, en minutes.
  final int minutesAssurees;

  /// Le montant arrete pour ce mois, hors aide Internet.
  final Montant montant;
}

/// Les revenus estimes de l'enseignant sur une periode.
@immutable
class RevenusEnseignant {
  /// Cree la vue.
  const RevenusEnseignant({
    required this.debut,
    required this.fin,
    required this.classes,
    required this.total,
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

  /// La ligne de total du detail, rendue par la source.
  final TotalRevenus total;

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

  /// Le releve des mois arretes par l'academie, du plus recent au plus
  /// ancien (FI-BR-11). Une capacite absente se dit indisponible : l'ecran
  /// n'invente jamais un mois « paye ».
  Future<List<LigneReleve>> releve();
}

/// **Aucune source serveur a ce jour** (FI-BR-11).
class RevenusEnseignantIndisponibles implements PortRevenusEnseignant {
  /// Cree l'implementation.
  const RevenusEnseignantIndisponibles();

  @override
  Future<RevenusEnseignant> moisEnCours() =>
      Future<RevenusEnseignant>.error(const CapaciteIndisponible('FI-BR-11'));

  @override
  Future<List<LigneReleve>> releve() =>
      Future<List<LigneReleve>>.error(const CapaciteIndisponible('FI-BR-11'));
}

/// Le port des revenus ; la demonstration le surcharge.
final Provider<PortRevenusEnseignant> portRevenusEnseignantProvider =
    Provider<PortRevenusEnseignant>(
      (Ref _) => const RevenusEnseignantIndisponibles(),
    );
