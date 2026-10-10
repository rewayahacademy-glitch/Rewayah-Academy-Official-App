/// OFFRES-FAM-1 : le suivi, cote famille, de chaque demande de creneau.
///
/// Decision du directeur du 09/10/2026 (`DECISION-OFFRES-GROUPES-2026-10-09`,
/// §2 et §4) : la famille est tenue au courant a chaque etape, par une
/// notification **et** un suivi visible dans son espace :
///
/// | Etape | Ce que la famille voit | Prochaine etape annoncee |
/// | :--- | :--- | :--- |
/// | Demande envoyee | « Votre demande est arrivee a l'administration » | Constitution de la classe |
/// | Classe validee | « Votre classe a ete validee » | Affectation de l'enseignant |
/// | Enseignant affecte | « Classe validee · enseignant affecte » | Debut des cours |
/// | Refus ou retrait | Le motif, en clair | Ce qu'elle peut faire ensuite |
///
/// Ce que le serveur porte, et que Flutter ne decide jamais :
///
/// - **l'etape** de chaque demande ([EtapeDemande]) et son motif de cloture
///   ([MotifCloture]) ;
/// - **les heures dans le fuseau de la famille** : jours, heure de chaque jour
///   ([CreneauDemande.occurrences], contrat C-10 bis) et debut des cours sont
///   rendus en heure murale du fuseau du foyer ([SuiviDemande.fuseauIana]).
///   L'appareil ne convertit rien : son propre fuseau peut differer de celui
///   du foyer (voyage, appareil partage) ;
/// - **la confidentialite des autres demandeurs** : le contrat ne porte AUCUN
///   nombre de demandeurs, aucune identite, aucun taux de remplissage. La
///   famille ne voit jamais qui d'autre a demande le meme creneau ni combien
///   de personnes l'ont demande (§4) ;
/// - **le nom de l'enseignant n'existe qu'a l'etape 3** : le constructeur
///   l'efface a toute autre etape, meme si une source le fournissait ;
/// - **la capacite de rechoisir** ([SuiviDemande.peutChoisirAutreCreneau]) :
///   l'ecran lit cette capacite, jamais un role.
///
/// Aucun branchement serveur ici : en production le port est absent
/// ([portSuiviDemandesProvider] vaut `null`), la liste est vide et aucune
/// carte n'est inventee (meme convention que `portRemplacementsProvider`).
/// La demonstration le surcharge.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'occurrence_creneau.dart';

export 'occurrence_creneau.dart' show OccurrenceCreneau;

/// Ou en est une demande de creneau (rendu par le serveur).
enum EtapeDemande {
  /// Etape 1 : la demande est arrivee a l'administration.
  envoyee,

  /// Etape 2 : l'administration a valide la classe.
  classeValidee,

  /// Etape 3 : un enseignant est affecte a la classe.
  enseignantAffecte,

  /// Etape 4 : refus ou retrait ; le motif dit lequel.
  close,
}

/// Pourquoi une demande est close. Le texte vient de l'application, jamais
/// d'un texte libre du serveur : aucun detail sur d'autres familles ne peut
/// s'y glisser.
enum MotifCloture {
  /// La famille a retire sa demande.
  retraitFamille,

  /// L'administration a retire ce creneau de ses offres.
  offreRetiree,

  /// La classe de ce creneau n'a pas pu etre constituee.
  classeNonConstituee,

  /// La direction n'a pas retenu la demande.
  refusDirection,

  /// L'élève suit déjà une classe.
  dejaEnClasse,

  /// Motif absent ou non reconnu : repli neutre du client (« Cette demande
  /// est close. »). Jamais un motif choisi a la place du serveur : un refus
  /// suppose serait faux pour un retrait de la famille, et l'inverse.
  inconnu,
}

/// Le debut des cours tel que le contrat le porte : une heure murale du
/// fuseau du foyer, donc **jamais** un instant UTC. Un `DateTime` UTC serait
/// affiche comme s'il etait l'heure du foyer (18:00 UTC lu « 18:00, heure de
/// Paris ») : il est refuse, et aucune heure n'est affichee plutot qu'une
/// heure fausse.
DateTime? heureMuraleDuFoyer(DateTime? debut) =>
    debut == null || debut.isUtc ? null : debut;

/// Les jours choisis et l'heure de chacun, en heure murale du fuseau du
/// foyer (contrat C-10 bis).
///
/// Le serveur rend `jours[]` et `heures_locales[]` en tableaux paralleles :
/// l'heure peut differer d'un jour a l'autre (semaine de changement d'heure,
/// creneau personnalise). Le creneau porte donc une [OccurrenceCreneau] par
/// jour, triee par jour, et chaque jour garde son heure : aucune heure n'est
/// remplacee par celle du premier jour. Il n'existe volontairement aucun
/// getter « l'heure du creneau » : un appelant qui a besoin d'une heure
/// unique lit [heuresToutesEgales] d'abord.
@immutable
class CreneauDemande {
  /// Cree le creneau. Les [occurrences] sont triees par jour ; une liste
  /// vide ou un jour en double est une erreur de l'adaptateur (assertion en
  /// mise au point). Les bornes de chaque valeur sont gardees par
  /// [OccurrenceCreneau].
  CreneauDemande({required Iterable<OccurrenceCreneau> occurrences})
    : assert(occurrences.isNotEmpty, 'un creneau a au moins un jour'),
      assert(
        joursDistincts(occurrences),
        'un jour ne figure qu une fois dans un creneau',
      ),
      occurrences = occurrencesTrieesParJour(occurrences);

  /// Les occurrences, du lundi au dimanche, chacune avec son heure.
  final List<OccurrenceCreneau> occurrences;

  /// Les jours ISO, du lundi (1) au dimanche (7).
  List<int> get joursIso => <int>[
    for (final OccurrenceCreneau o in occurrences) o.jourIso,
  ];

  /// Vrai quand tous les jours commencent a la meme heure.
  bool get heuresToutesEgales => heuresToutesEgalesDe(occurrences);
}

/// Une demande de creneau d'un eleve du foyer, et ou elle en est.
@immutable
class SuiviDemande {
  /// Cree le suivi. [enseignant] n'est garde qu'a l'etape
  /// [EtapeDemande.enseignantAffecte], [motif] qu'a l'etape
  /// [EtapeDemande.close], [debutCours] qu'a l'etape 3.
  ///
  /// [debutCours] est une heure murale du fuseau du foyer : un `DateTime`
  /// UTC est une erreur de l'adaptateur (assertion en mise au point) ; en
  /// production il est ecarte ([heureMuraleDuFoyer]) et l'ecran dit que la
  /// date reste a fixer, plutot qu'une heure fausse. Une demande close sans
  /// motif rendu prend [MotifCloture.inconnu], jamais un refus suppose.
  SuiviDemande({
    required this.demandeId,
    required this.eleveId,
    required this.prenom,
    required this.etape,
    required this.creneau,
    required this.fuseauIana,
    this.personnalise = false,
    String? enseignant,
    DateTime? debutCours,
    MotifCloture? motif,
    this.peutChoisirAutreCreneau = false,
  }) : assert(
         debutCours == null || !debutCours.isUtc,
         'debutCours est une heure murale du fuseau du foyer, jamais UTC',
       ),
       enseignant = etape == EtapeDemande.enseignantAffecte ? enseignant : null,
       debutCours = etape == EtapeDemande.enseignantAffecte
           ? heureMuraleDuFoyer(debutCours)
           : null,
       motif = etape == EtapeDemande.close
           ? motif ?? MotifCloture.inconnu
           : null;

  /// L'identifiant de la demande.
  final String demandeId;

  /// L'eleve concerne.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// L'etape atteinte.
  final EtapeDemande etape;

  /// Les jours choisis et l'heure de chacun, dans le fuseau du foyer.
  final CreneauDemande creneau;

  /// Le fuseau IANA du foyer, dans lequel toutes les heures sont rendues.
  final String fuseauIana;

  /// Vrai pour un creneau personnalise (hors vitrine) : il ne s'ouvre que si
  /// d'autres eleves le choisissent et remplissent la classe.
  final bool personnalise;

  /// Le nom de l'enseignant, tel qu'il se dit (« Sayyida Maryam »). Nul
  /// avant l'etape 3.
  final String? enseignant;

  /// Le debut des cours, en heure murale du fuseau du foyer. Nul avant
  /// l'etape 3, et tant que la date n'est pas fixee.
  final DateTime? debutCours;

  /// Le motif d'une demande close, nul sinon.
  final MotifCloture? motif;

  /// Capacite rendue par le serveur : la famille peut choisir un autre
  /// creneau pour cet eleve.
  final bool peutChoisirAutreCreneau;
}

/// Le port du suivi des demandes de creneau du foyer connecte.
abstract interface class PortSuiviDemandes {
  /// Les demandes des eleves du foyer, une par eleve concerne, mises a jour a
  /// chaque transition.
  Stream<List<SuiviDemande>> suivre();
}

/// Le port : absent avant le branchement serveur.
final Provider<PortSuiviDemandes?> portSuiviDemandesProvider =
    Provider<PortSuiviDemandes?>((Ref _) => null);

/// Les demandes du foyer. Sans port, aucune demande.
final StreamProvider<List<SuiviDemande>> suiviDemandesProvider =
    StreamProvider<List<SuiviDemande>>((Ref ref) {
      final PortSuiviDemandes? port = ref.watch(portSuiviDemandesProvider);
      if (port == null) {
        return Stream<List<SuiviDemande>>.value(const <SuiviDemande>[]);
      }
      return port.suivre();
    });
