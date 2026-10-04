// La vue globale de la Finance pour la direction (FI-1c, guide Finance V4
// §1.5, §5.6 ; FI-BR-12).
//
// Encaissement, revenu, solde client, charge et marge toujours SEPARES
// (FI21) ; la marge de reference n'est jamais une sanction ni un blocage.
// Un essai ne compte jamais comme payant (FI4).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// La nature d'une alerte de la vue globale.
enum NatureAlerteFinance {
  /// Une periode a regulariser.
  aRegulariser,

  /// Un paiement qui attend sa confirmation depuis longtemps.
  confirmationEnAttente,

  /// Une classe sous le minimum d'ouverture.
  classeSousMinimum,
}

/// Une alerte de la vue globale. **Aucun texte rendu** : l'ecran redige
/// l'alerte depuis sa nature et ses donnees (K-41), jamais une phrase en
/// morceaux.
@immutable
class AlerteFinance {
  /// Cree l'alerte.
  const AlerteFinance({
    required this.id,
    required this.nature,
    this.prenom,
    this.classe,
    this.montant,
  });

  /// L'identifiant de l'alerte.
  final String id;

  /// Sa nature.
  final NatureAlerteFinance nature;

  /// Le prenom du profil concerne, quand l'alerte en vise un.
  final String? prenom;

  /// Le nom de la classe concernee, quand l'alerte en vise une.
  final String? classe;

  /// Le montant concerne (manque, paiement en attente), quand il y en a un.
  final Montant? montant;
}

/// Les sept indicateurs de la vue globale (revue FI-1a ligne 12).
@immutable
class VueGlobaleFinance {
  /// Cree la vue.
  const VueGlobaleFinance({
    required this.mois,
    required this.encaisse,
    required this.revenuAcademique,
    required this.paieEnseignants,
    required this.margeProjeteePourMille,
    required this.impayes,
    required this.essaisEnCours,
    required this.soldesCrediteurs,
    this.alertes = const <AlerteFinance>[],
  });

  /// Le mois de la vue (premier jour).
  final DateTime mois;

  /// L'encaisse du mois.
  final Montant encaisse;

  /// Le revenu academique reconnu (hors taxes collectees, FI13).
  final Montant revenuAcademique;

  /// La paie des enseignants estimee.
  final Montant paieEnseignants;

  /// La marge projetee, en pour mille, `null` sans activite.
  ///
  /// **Marge sur la seule paie des enseignants** : (revenu academique - paie
  /// des enseignants) / revenu academique. Aucune autre charge n'y entre
  /// (plateforme, paiement, Internet, direction). Elle ne se compare donc
  /// JAMAIS aux references nettes de la politique (environ 30 % net, guide
  /// §1.5, `margeReferencePourMille`), qui supposent toutes les charges : une
  /// marge sur paie de 79 % n'est pas une marge nette au-dessus de l'objectif.
  /// La demonstration (`DonneesFinanceDemo.vueGlobale`) suit ce contrat.
  final int? margeProjeteePourMille;

  /// Le montant des impayes.
  final Montant impayes;

  /// Le nombre d'essais en cours (un nombre, jamais un montant).
  final int essaisEnCours;

  /// La somme des soldes crediteurs des profils.
  final Montant soldesCrediteurs;

  /// Les alertes, dans l'ordre rendu.
  final List<AlerteFinance> alertes;
}

/// La Finance de la direction.
abstract interface class PortFinanceDirection {
  /// La vue globale du mois en cours (FI-BR-12).
  Future<VueGlobaleFinance> vueGlobale();
}

/// **Aucune source serveur a ce jour** (FI-BR-12).
class FinanceDirectionIndisponible implements PortFinanceDirection {
  /// Cree l'implementation.
  const FinanceDirectionIndisponible();

  @override
  Future<VueGlobaleFinance> vueGlobale() =>
      Future<VueGlobaleFinance>.error(const CapaciteIndisponible('FI-BR-12'));
}

/// Le port de la vue globale ; la demonstration le surcharge.
final Provider<PortFinanceDirection> portFinanceDirectionProvider =
    Provider<PortFinanceDirection>(
      (Ref _) => const FinanceDirectionIndisponible(),
    );
