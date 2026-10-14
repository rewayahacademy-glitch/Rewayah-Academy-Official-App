/// R18, BR-CT-02, BR-CT-03, BR-CT-15, BR-CT-18 (`DECISION-CLASSES-SIMULTANEES-
/// 2026-10-10.md`) : les regles du tirage des missions de controle et
/// l'historique audite des tirages, lisibles par la direction seule.
///
/// **Le controleur ne choisit jamais sa classe**, pour empecher toute
/// connivence ou corruption. Le serveur tire au sort une mission parmi les
/// seances en direct, selon les regles de la direction (ponderation, classes
/// ou enseignants a cibler, frequence). Avec N seances simultanees et
/// plusieurs controleurs, le tirage est atomique (`FOR UPDATE SKIP LOCKED`) :
/// un seul controle par classe (BR-CT-18), jamais la classe du controleur
/// quand il enseigne aussi (BR-CT-02), aucun motif previsible. Une mission
/// non controlee est signalee a l'administration (BR-CT-15). Le tirage est
/// audite ; la direction voit l'historique, le controleur ne voit que sa
/// mission.
///
/// **Ce que le serveur porte, et que Flutter ne decide jamais** : le tirage
/// lui-meme, l'exclusion de la classe du controleur, l'atomicite, l'audit, le
/// signalement des missions non controlees, et la capacite de lire ou de
/// modifier ([AccesTirage]). L'ecran lit ces capacites, jamais un role.
/// **Le contrat attendu** (ligne Contrats a demander) : `regles_tirage` et
/// `enregistrer_regles_tirage` (idempotente par cle d'envoi, journalisee),
/// `candidats_cible_tirage` et `historique_tirages` (pagine, filtre par
/// statut et texte), plus les capacites `peut_lire_tirages` et
/// `peut_modifier_regles_tirage`.
///
/// Sans port ([portTirageControleProvider] vaut `null`), l'ecran le dit
/// (« disponible au branchement serveur ») : aucun tirage n'est invente.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/capacite_indisponible.dart';

/// Le poids d'un critere dans le tirage.
enum NiveauPonderation {
  /// Le critere ne compte pas.
  aucun,

  /// Le critere compte comme les autres.
  normal,

  /// Les seances qui le portent ont plus de chances d'etre tirees.
  fort,
}

/// Ce que la direction peut ponderer.
enum CriterePonderation {
  /// Les enseignants arrives recemment.
  enseignantsRecents,

  /// Les classes signalees a l'administration.
  classesSignalees,

  /// Les heures de pointe, quand beaucoup de seances ont lieu ensemble.
  heuresDePointe,
}

/// Une cible du tirage : une classe ou un enseignant.
enum TypeCible {
  /// Une classe.
  classe,

  /// Un enseignant.
  enseignant,
}

/// Une classe ou un enseignant tire en priorite quand sa seance est en
/// direct. Jamais annoncee au controleur ni a l'enseignant.
@immutable
class CibleTirage {
  /// Cree une cible.
  const CibleTirage({
    required this.id,
    required this.type,
    required this.libelle,
  });

  /// Son identifiant.
  final String id;

  /// Classe ou enseignant.
  final TypeCible type;

  /// Son nom, sans ambiguite (R16 pour une classe).
  final String libelle;

  @override
  bool operator ==(Object other) =>
      other is CibleTirage && other.id == id && other.type == type;

  @override
  int get hashCode => Object.hash(id, type);
}

/// Les bornes du nombre de missions par semaine. Le serveur les applique
/// (0 a 50) ; l'ecran ne les rappelle que par courtoisie.
const int missionsMin = 0;

/// Voir [missionsMin].
const int missionsMax = 50;

/// Les regles du tirage, fixees par la direction.
@immutable
class ReglesTirage {
  /// Cree les regles.
  const ReglesTirage({
    required this.missionsParSemaine,
    required this.ponderations,
    required this.cibles,
    this.version = 0,
  });

  /// La version de ces regles, rendue par le serveur : chaque enregistrement
  /// en cree une nouvelle (ajout seul, les anciennes ne changent jamais).
  /// 0 : aucune regle n'a encore ete enregistree.
  final int version;

  /// Le nombre de missions qu'un controleur recoit par semaine, au plus
  /// (de [missionsMin] a [missionsMax], que le serveur applique).
  final int missionsParSemaine;

  /// Le poids de chaque critere.
  final Map<CriterePonderation, NiveauPonderation> ponderations;

  /// Les classes et enseignants a tirer en priorite.
  final List<CibleTirage> cibles;

  /// Les memes regles, un champ change.
  ReglesTirage avec({
    int? missionsParSemaine,
    Map<CriterePonderation, NiveauPonderation>? ponderations,
    List<CibleTirage>? cibles,
  }) => ReglesTirage(
    version: version,
    missionsParSemaine: missionsParSemaine ?? this.missionsParSemaine,
    ponderations: ponderations ?? this.ponderations,
    cibles: cibles ?? this.cibles,
  );

  /// Le poids du critere [c] ([NiveauPonderation.normal] s'il n'est pas dit).
  NiveauPonderation poids(CriterePonderation c) =>
      ponderations[c] ?? NiveauPonderation.normal;
}

/// Ce que la personne connectee peut faire des tirages, rendu par le serveur.
@immutable
class AccesTirage {
  /// Cree l'acces.
  const AccesTirage({required this.peutLire, required this.peutModifier});

  /// Peut lire les regles et l'historique (la direction seule).
  final bool peutLire;

  /// Peut modifier les regles.
  final bool peutModifier;
}

/// Ce qui est advenu d'une mission tiree.
enum StatutTirage {
  /// La mission est attribuee, la seance n'a pas commence ou le controleur
  /// n'est pas entre.
  attribuee,

  /// Le controle est en cours.
  enCours,

  /// Le controle a eu lieu.
  controlee,

  /// Aucune entree du controleur avant la fin de la seance : le serveur a
  /// envoye le rapport a l'administration (BR-CT-15).
  nonControlee,

  /// Un autre controle etait deja ouvert sur cette classe : un seul controle
  /// a la fois par classe (BR-CT-18).
  dejaControlee,
}

/// Pourquoi cette seance a ete tiree.
enum CritereTirage {
  /// Au hasard, tous poids egaux.
  aleatoire,

  /// Le tirage a suivi la ponderation.
  ponderation,

  /// La seance est celle d'une cible.
  cible,
}

/// Une ligne de l'historique audite.
@immutable
class TirageAudite {
  /// Cree la ligne.
  const TirageAudite({
    required this.id,
    required this.quand,
    required this.classe,
    required this.enseignant,
    required this.controleur,
    required this.statut,
    required this.critere,
    this.rapportEnvoye = false,
  });

  /// L'identifiant du tirage.
  final String id;

  /// Quand le serveur a tire, en heure murale de l'appareil.
  final DateTime quand;

  /// La classe, nommee sans ambiguite (R16).
  final String classe;

  /// L'enseignant, avec son titre.
  final String enseignant;

  /// Le controleur, tel que le serveur le nomme a la direction.
  final String controleur;

  /// Ce qui est advenu de la mission.
  final StatutTirage statut;

  /// Pourquoi cette seance.
  final CritereTirage critere;

  /// Vrai quand le rapport « non controlee » est parti a l'administration.
  final bool rapportEnvoye;
}

/// Ce que l'ecran demande de l'historique. `null` : tous.
@immutable
class FiltreTirages {
  /// Cree un filtre.
  const FiltreTirages({this.statut, this.texte = ''});

  /// Le statut.
  final StatutTirage? statut;

  /// Le texte cherche (classe, enseignant, controleur).
  final String texte;

  /// Le meme filtre, un axe change.
  FiltreTirages avec({StatutTirage? Function()? statut, String? texte}) =>
      FiltreTirages(
        statut: statut == null ? this.statut : statut(),
        texte: texte ?? this.texte,
      );

  @override
  bool operator ==(Object other) =>
      other is FiltreTirages && other.statut == statut && other.texte == texte;

  @override
  int get hashCode => Object.hash(statut, texte);
}

/// Une page de l'historique.
@immutable
class PageTirages {
  /// Cree une page.
  const PageTirages({
    required this.lignes,
    required this.total,
    required this.page,
    required this.taille,
    required this.compteurs,
    required this.totalSansFiltre,
  });

  /// Les tirages de la page.
  final List<TirageAudite> lignes;

  /// Le nombre de tirages qui passent le filtre.
  final int total;

  /// La page, a partir de 1.
  final int page;

  /// Le nombre de tirages par page.
  final int taille;

  /// Le nombre de tirages par statut, le texte applique.
  final Map<StatutTirage, int> compteurs;

  /// Le nombre de tirages sans aucun filtre : 0 veut dire « aucun tirage ».
  final int totalSansFiltre;

  /// Le nombre de pages (1 au moins).
  int get pages => math.max(1, (total + taille - 1) ~/ taille);

  /// Le rang de la premiere ligne de la page, a partir de 1.
  int get debut => total == 0 ? 0 : (page - 1) * taille + 1;

  /// Le rang de la derniere ligne de la page.
  int get fin => (page - 1) * taille + lignes.length;

  /// Le nombre de tirages, tous statuts confondus.
  int get tousStatuts =>
      compteurs.values.fold<int>(0, (int somme, int n) => somme + n);
}

/// La page demandee.
@immutable
class RequeteTirages {
  /// Cree une requete.
  const RequeteTirages({
    this.filtre = const FiltreTirages(),
    this.page = 1,
    this.taille = taillePageTirages,
  });

  /// Le filtre.
  final FiltreTirages filtre;

  /// La page.
  final int page;

  /// La taille de page.
  final int taille;

  @override
  bool operator ==(Object other) =>
      other is RequeteTirages &&
      other.filtre == filtre &&
      other.page == page &&
      other.taille == taille;

  @override
  int get hashCode => Object.hash(filtre, page, taille);
}

/// La taille de page de l'historique.
const int taillePageTirages = 25;

/// La reponse du serveur a l'enregistrement des regles.
@immutable
sealed class ResultatRegles {
  const ResultatRegles();
}

/// Les regles sont enregistrees et journalisees.
final class ReglesEnregistrees extends ResultatRegles {
  /// Cree le resultat.
  const ReglesEnregistrees({this.version = 0});

  /// La version creee par le serveur (0 : non rendue).
  final int version;
}

/// Le serveur a refuse les regles, avec son motif en clair.
final class ReglesRefusees extends ResultatRegles {
  /// Cree le resultat.
  const ReglesRefusees(this.motif);

  /// Le motif.
  final String motif;
}

/// Le port des regles et de l'historique des tirages.
abstract interface class PortTirageControle {
  /// Ce que la personne connectee peut faire.
  Future<AccesTirage> acces();

  /// Les regles en vigueur.
  Future<ReglesTirage> regles();

  /// Enregistre [regles]. [cleEnvoi] est la meme pour toutes les pressions
  /// d'une meme feuille : le serveur n'enregistre jamais deux fois. Leve une
  /// exception quand la reponse n'arrive pas : l'ecran ne suppose alors aucun
  /// etat.
  Future<ResultatRegles> enregistrer(
    ReglesTirage regles, {
    required String cleEnvoi,
  });

  /// Les classes et enseignants que la direction peut cibler.
  Future<List<CibleTirage>> candidatsCible();

  /// La page [page] (a partir de 1) de [taille] tirages qui passent
  /// [filtre], le plus recent d'abord.
  Future<PageTirages> tirages(
    FiltreTirages filtre, {
    required int page,
    required int taille,
  });
}

/// L'identifiant de la dependance serveur, pour la trace et les tests
/// (jamais affiche).
const String dependanceTirage = 'DB-ECHELLE-CTRL-DIRECT';

/// Le port : absent avant le contrat serveur.
final Provider<PortTirageControle?> portTirageControleProvider =
    Provider<PortTirageControle?>((Ref _) => null);

Future<T> _sansPort<T>() =>
    Future<T>.error(const CapaciteIndisponible(dependanceTirage));

/// Ce que la personne connectee peut faire des tirages. Sans port :
/// [CapaciteIndisponible].
final FutureProvider<AccesTirage> accesTirageProvider =
    FutureProvider<AccesTirage>((Ref ref) {
      final PortTirageControle? port = ref.watch(portTirageControleProvider);
      return port == null ? _sansPort<AccesTirage>() : port.acces();
    }, retry: (int _, Object _) => null);

/// Les regles en vigueur. Aucune retentative automatique : un echec se relit
/// par « Reessayer ».
final FutureProvider<ReglesTirage> reglesTirageProvider =
    FutureProvider<ReglesTirage>((Ref ref) {
      final PortTirageControle? port = ref.watch(portTirageControleProvider);
      return port == null ? _sansPort<ReglesTirage>() : port.regles();
    }, retry: (int _, Object _) => null);

/// Les cibles possibles.
final FutureProvider<List<CibleTirage>> candidatsCibleProvider =
    FutureProvider<List<CibleTirage>>((Ref ref) {
      final PortTirageControle? port = ref.watch(portTirageControleProvider);
      return port == null
          ? _sansPort<List<CibleTirage>>()
          : port.candidatsCible();
    }, retry: (int _, Object _) => null);

/// Une page de l'historique.
final FutureProviderFamily<PageTirages, RequeteTirages> pageTiragesProvider =
    FutureProvider.family<PageTirages, RequeteTirages>((
      Ref ref,
      RequeteTirages requete,
    ) {
      final PortTirageControle? port = ref.watch(portTirageControleProvider);
      if (port == null) return _sansPort<PageTirages>();
      return port.tirages(
        requete.filtre,
        page: requete.page,
        taille: requete.taille,
      );
    }, retry: (int _, Object _) => null);

/// Pagine [tous] en memoire : filtre (statut, texte), tri (le plus recent
/// d'abord, puis l'identifiant), decoupe. Sert a la demonstration et aux
/// tests ; le serveur fera le meme travail en SQL (R17).
PageTirages paginerTirages(
  List<TirageAudite> tous,
  FiltreTirages filtre, {
  required int page,
  required int taille,
  String Function(String)? normaliser,
}) {
  assert(taille > 0, 'une page porte au moins un tirage');
  String n(String s) => (normaliser ?? (String x) => x.toLowerCase())(s);
  final String cherche = n(filtre.texte.trim());
  final List<TirageAudite> autresAxes = tous
      .where(
        (TirageAudite t) =>
            cherche.isEmpty ||
            n('${t.classe} ${t.enseignant} ${t.controleur}').contains(cherche),
      )
      .toList(growable: false);
  final List<TirageAudite> retenus =
      autresAxes
          .where(
            (TirageAudite t) =>
                filtre.statut == null || t.statut == filtre.statut,
          )
          .toList()
        ..sort((TirageAudite a, TirageAudite b) {
          final int quand = b.quand.compareTo(a.quand);
          return quand != 0 ? quand : a.id.compareTo(b.id);
        });
  final int pages = math.max(1, (retenus.length + taille - 1) ~/ taille);
  final int courante = page.clamp(1, pages);
  final int debut = (courante - 1) * taille;
  return PageTirages(
    lignes: retenus.sublist(
      math.min(debut, retenus.length),
      math.min(debut + taille, retenus.length),
    ),
    total: retenus.length,
    page: courante,
    taille: taille,
    compteurs: <StatutTirage, int>{
      for (final StatutTirage s in StatutTirage.values)
        s: autresAxes.where((TirageAudite t) => t.statut == s).length,
    },
    totalSansFiltre: tous.length,
  );
}
