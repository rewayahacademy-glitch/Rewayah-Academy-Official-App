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

/// La page qu'ouvre une alerte (revue FI-VAGUE-R R6-04, revue 12 i :
/// « chaque ligne ouvre sa cible, une seule fois »). Une page existante du
/// routeur de la direction : le routeur n'a encore ni fiche de profil ni
/// fiche de classe cote direction, la cible est la liste qui les porte.
enum CibleAlerteFinance {
  /// Les comptes du produit (Personnes > Comptes) : le foyer du profil.
  comptes,

  /// Les classes (Operations > Classes).
  classes,
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
    required this.cible,
    this.prenom,
    this.classe,
    this.montant,
  });

  /// L'identifiant de l'alerte.
  final String id;

  /// Sa nature.
  final NatureAlerteFinance nature;

  /// La page qui permet d'agir sur l'alerte, rendue par la source.
  final CibleAlerteFinance cible;

  /// Le prenom du profil concerne, quand l'alerte en vise un.
  final String? prenom;

  /// Le nom de la classe concernee, quand l'alerte en vise une.
  final String? classe;

  /// Le montant concerne (manque, paiement en attente), quand il y en a un.
  final Montant? montant;
}

/// Un montant d'un mois, point d'une serie de la vue globale (revue
/// FI-VAGUE-R R6-01 ; revue 12 d).
@immutable
class MontantMensuel {
  /// Cree le point.
  const MontantMensuel({required this.mois, required this.montant});

  /// Le mois (premier jour).
  final DateTime mois;

  /// Le montant du mois, tel que rendu par la source.
  final Montant montant;
}

/// La marge projetee d'un mois, en pour mille (revue 12 f) ; `null` quand
/// le mois n'a aucun revenu reconnu.
@immutable
class MargeMensuelle {
  /// Cree le point.
  const MargeMensuelle({required this.mois, required this.pourMille});

  /// Le mois (premier jour).
  final DateTime mois;

  /// La marge sur la seule paie des enseignants, comme
  /// [VueGlobaleFinance.margeProjeteePourMille].
  final int? pourMille;
}

/// Le type d'eleve d'une part de revenu : les seules categories du modele
/// (ECARTS C3 : un acces mensuel a une classe, enfant ou adulte).
enum TypeEleveRevenu {
  /// Les eleves enfants.
  enfant,

  /// Les eleves adultes.
  adulte,
}

/// La part du revenu academique du mois portee par un type d'eleve (revue
/// 12 e).
@immutable
class PartRevenu {
  /// Cree la part.
  const PartRevenu({required this.type, required this.montant});

  /// Le type d'eleve.
  final TypeEleveRevenu type;

  /// Le revenu academique de ce type, tel que rendu par la source.
  final Montant montant;
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
    this.encaisseParMois = const <MontantMensuel>[],
    this.paieParMois = const <MontantMensuel>[],
    this.margeParMois = const <MargeMensuelle>[],
    this.revenuParType = const <PartRevenu>[],
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

  /// L'encaisse des derniers mois, le plus ancien d'abord, mois de la vue
  /// compris. Vide quand la source ne rend pas d'historique.
  final List<MontantMensuel> encaisseParMois;

  /// La paie des enseignants estimee des derniers mois (une charge), le
  /// plus ancien d'abord.
  final List<MontantMensuel> paieParMois;

  /// La marge projetee des derniers mois, le plus ancien d'abord.
  final List<MargeMensuelle> margeParMois;

  /// Le revenu academique du mois de la vue, par type d'eleve.
  final List<PartRevenu> revenuParType;
}

/// Les longueurs de dessin des barres d'un graphique, entre 0 et 1 : chaque
/// valeur sur la plus grande de [valeurs] (0 partout quand aucune n'est
/// positive, 0 pour une valeur negative). Une geometrie de dessin, jamais un
/// chiffre affiche : les nombres lus a cote des barres sont ceux de la
/// source (revue FI-VAGUE-R R6-01).
List<double> longueursDeBarres(List<int> valeurs) {
  int plusGrande = 0;
  for (final int v in valeurs) {
    if (v > plusGrande) plusGrande = v;
  }
  return <double>[
    for (final int v in valeurs) plusGrande <= 0 || v <= 0 ? 0 : v / plusGrande,
  ];
}

/// La Finance de la direction. Series, repartition et cibles d'alerte
/// arrivent par la meme lecture (FI-BR-12, revue FI-VAGUE-R R6-01, R6-04).
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
