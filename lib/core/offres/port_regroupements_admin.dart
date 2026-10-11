/// OFFRES-ADM-1 : les demandes semblables, reunies cote administration, et la
/// creation d'une classe depuis l'une d'elles.
///
/// Decision du directeur du 09/10/2026 (`DECISION-OFFRES-GROUPES-2026-10-09.md`
/// §3) : le systeme regroupe les demandes qui se ressemblent (memes jours,
/// meme heure locale pour chacun, meme fuseau, meme public, meme langue ;
/// jours tries et dedoublonnes ; l'heure peut differer d'un jour a l'autre,
/// contrat C-11 bis) ; a la creation, les eleves du regroupement sont integres a
/// la classe ; un enseignant est aussitot propose, que l'administration
/// confirme.
///
/// Ce que le serveur porte, et que Flutter ne decide jamais :
///
/// - **le regroupement lui-meme** : [PortRegroupementsAdmin.regroupements]
///   rend des regroupements deja formes. L'ecran ne compare aucune demande ;
/// - **le quota** ([RegroupementDemandes.quota]) : lu dans `app_config` par le
///   serveur (5 enfants, 6 adultes au 09/10), jamais ecrit dans le client ;
/// - **les heures dans les autres fuseaux**
///   ([RegroupementDemandes.autresFuseaux]) : calculees par le serveur, qui a
///   la base des fuseaux ; le client n'en convertit aucune ;
/// - **la creation atomique** : [PortRegroupementsAdmin.creerClasse] cree la
///   classe et y integre les eleves en une seule transaction, et rend
///   [CreationDejaFaite] a tout appel qui arrive apres la premiere creation
///   (deux membres de la direction sur le meme regroupement). La meme
///   `cleEnvoi` rejouee rend le meme resultat (idempotence) ;
/// - **les capacites** : [RegroupementDemandes.peutCreerClasse] et
///   [ClasseSansEnseignant.peutAffecterEnseignant] disent ce que la personne
///   connectee peut faire. L'ecran lit ces capacites, jamais un role ;
/// - **les notifications aux familles**, a chaque transition (§4).
///
/// Aucun branchement serveur ici : en production le port est absent
/// ([portRegroupementsAdminProvider] vaut `null`) et l'ecran le dit
/// (« disponible au branchement serveur »), sans rien inventer. La
/// demonstration le surcharge.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import 'decoupage_classes.dart';
import 'occurrence_creneau.dart';
import 'offre_horaire.dart' show PublicOffre;

export 'decoupage_classes.dart' show DecoupageClasses, decouperDemandes;
export 'occurrence_creneau.dart' show OccurrenceCreneau;

/// Une heure de la semaine lue dans un autre fuseau que celui du
/// regroupement.
@immutable
class HeureDansFuseau {
  /// Cree une heure.
  const HeureDansFuseau({
    required this.fuseau,
    required this.heure,
    this.minute = 0,
    this.decalageJour = 0,
    this.jourIso,
  });

  /// Le fuseau IANA (`Europe/Paris`).
  final String fuseau;

  /// Le jour ISO de l'occurrence du regroupement que cette heure traduit
  /// (C-11 bis). Nul : elle vaut pour toutes les occurrences, ce qui n'a de
  /// sens que si elles ont toutes la meme heure ; sinon le serveur rend une
  /// heure par jour, parce qu'un changement d'heure decale certains jours et
  /// pas d'autres.
  final int? jourIso;

  /// L'heure pleine, de 0 a 23.
  final int heure;

  /// Les minutes, de 0 a 59.
  final int minute;

  /// Le jour par rapport a l'heure de reference : -1 la veille, +1 le
  /// lendemain, 0 le meme jour.
  final int decalageJour;
}

/// Une classe deja creee depuis un regroupement, a qui il manque encore son
/// enseignant (l'administration a ferme la feuille avant de le confirmer).
@immutable
class ClasseSansEnseignant {
  /// Cree la classe.
  const ClasseSansEnseignant({
    required this.classeId,
    required this.libelle,
    this.genre,
    this.peutAffecterEnseignant = false,
    this.numeroDansFamille,
    this.codeCourt,
  });

  /// L'identifiant de la classe.
  final String classeId;

  /// Son nom.
  final String libelle;

  /// Son genre, tel qu'enregistre a la creation. Nul : non rendu, et la
  /// proposition d'enseignant ne filtre alors pas par genre.
  final GenreClasse? genre;

  /// Capacite rendue par le serveur : la personne connectee peut confirmer
  /// l'enseignant de cette classe.
  final bool peutAffecterEnseignant;

  /// R16 : le numero de cette classe parmi les classes paralleles de meme
  /// cle (meme categorie, memes jours, meme heure), attribue par le serveur.
  /// Nul tant que le serveur ne le rend pas (ligne Contrats a demander).
  final int? numeroDansFamille;

  /// R16 : un code court lisible attribue par le serveur, a defaut de
  /// numero. Nul tant que le serveur ne le rend pas.
  final String? codeCourt;
}

/// Un regroupement de demandes semblables.
@immutable
class RegroupementDemandes {
  /// Cree un regroupement. Les [occurrences] (un jour et son heure, dans le
  /// [fuseau] du regroupement) sont triees par jour ; une liste vide, un jour
  /// en double, ou une heure d'un autre fuseau sans jour quand les jours
  /// n'ont pas tous la meme heure sont des erreurs de l'adaptateur
  /// (assertions en mise au point, contrat C-11 bis).
  RegroupementDemandes({
    required this.id,
    required this.public,
    required this.langueCode,
    required this.langueNom,
    required this.fuseau,
    required Iterable<OccurrenceCreneau> occurrences,
    required this.nombreEleves,
    required this.quota,
    this.autresFuseaux = const <HeureDansFuseau>[],
    this.peutCreerClasse = false,
    this.classe,
    this.classesPossibles,
    this.numeroProchaineClasse,
    this.minimum,
    this.classesExistantes,
  }) : assert(occurrences.isNotEmpty, 'un regroupement a au moins un jour'),
       assert(
         joursDistincts(occurrences),
         'un jour ne figure qu une fois dans un regroupement',
       ),
       assert(
         heuresToutesEgalesDe(occurrences.toList()) ||
             autresFuseaux.every((HeureDansFuseau h) => h.jourIso != null),
         'heures differentes selon le jour : chaque heure d un autre fuseau '
         'dit son jour',
       ),
       occurrences = occurrencesTrieesParJour(occurrences);

  /// L'identifiant du regroupement (cle de ressemblance cote serveur).
  final String id;

  /// Enfants ou adultes.
  final PublicOffre public;

  /// Le code de la langue d'enseignement.
  final String langueCode;

  /// Le nom affichable de la langue d'enseignement.
  final String langueNom;

  /// Le fuseau IANA des demandes : celui des heures de reference.
  final String fuseau;

  /// Les jours demandes et l'heure de chacun, dans [fuseau] : les heures de
  /// reference, du lundi au dimanche. Chaque jour garde son heure (C-11 bis) :
  /// aucune n'est remplacee par celle du premier jour.
  final List<OccurrenceCreneau> occurrences;

  /// Les memes heures dans les autres fuseaux utiles (ceux des familles et
  /// des enseignants concernes), calculees par le serveur. Vide : non
  /// rendues.
  final List<HeureDansFuseau> autresFuseaux;

  /// Les jours ISO (1 = lundi), du lundi au dimanche.
  List<int> get jours => <int>[
    for (final OccurrenceCreneau o in occurrences) o.jourIso,
  ];

  /// Vrai quand tous les jours commencent a la meme heure de reference.
  bool get heuresToutesEgales => heuresToutesEgalesDe(occurrences);

  /// Le nombre d'eleves du regroupement. **Jamais leurs noms** : l'ecran
  /// n'en a pas besoin pour decider.
  final int nombreEleves;

  /// Le quota de la classe pour ce public, lu dans `app_config` par le
  /// serveur.
  final int quota;

  /// Capacite rendue par le serveur : la personne connectee peut creer la
  /// classe de ce regroupement.
  final bool peutCreerClasse;

  /// La classe deja creee depuis ce regroupement, qui attend son
  /// enseignant. Nul : aucune classe encore.
  final ClasseSansEnseignant? classe;

  /// R3 : le nombre de classes que ces demandes permettent d'ouvrir (minimum
  /// et maximum d'`app_config`), calcule par le serveur. Nul tant que le
  /// serveur ne le rend pas : [classesPossiblesLues] retombe alors sur le
  /// seul quota connu, sans inventer de minimum.
  final int? classesPossibles;

  /// R16 : le numero que portera la prochaine classe creee sur cette cle,
  /// attribue par le serveur. Nul tant que le serveur ne le rend pas.
  final int? numeroProchaineClasse;

  /// R3 : le minimum d'eleves d'une classe pour ce public, lu dans
  /// `app_config` par le serveur. Nul tant qu'il ne le rend pas : le reste
  /// d'un decoupage attend alors, aucun minimum n'est invente.
  final int? minimum;

  /// R1, R16 : le nombre de classes deja ouvertes sur la meme cle (meme
  /// horaire, meme categorie). Nul : non rendu. La classe creee s'y ajoute,
  /// elle n'en ecrase aucune.
  final int? classesExistantes;

  /// R3 : le decoupage de ces demandes en classes, tel que le serveur le
  /// fera (maximum = [quota], minimum = [minimum]).
  DecoupageClasses get decoupage => decouperDemandes(
    demandes: nombreEleves,
    maximum: quota,
    minimum: minimum,
  );

  /// Le nombre de classes possibles : celui du serveur, sinon celui du
  /// decoupage (jamais une classe sous le minimum connu).
  int get classesPossiblesLues => classesPossibles ?? decoupage.classes;

  /// Vrai quand le quota est atteint : la classe peut ouvrir complete.
  bool get pret => nombreEleves >= quota;

  /// Le nombre d'eleves qui manquent pour atteindre le quota (0 si pret).
  int get manquants => pret ? 0 : quota - nombreEleves;
}

/// La reponse du serveur a une creation de classe.
@immutable
sealed class ResultatCreationClasse {
  const ResultatCreationClasse();
}

/// La classe est creee et les eleves du regroupement y sont integres.
final class ClasseCreee extends ResultatCreationClasse {
  /// Cree le resultat.
  const ClasseCreee({required this.classe, required this.elevesIntegres});

  /// La classe creee, qui attend maintenant son enseignant.
  final ClasseSansEnseignant classe;

  /// Le nombre d'eleves integres.
  final int elevesIntegres;
}

/// Un autre membre de la direction a cree cette classe juste avant : rien
/// n'a ete cree en double.
final class CreationDejaFaite extends ResultatCreationClasse {
  /// Cree le resultat.
  const CreationDejaFaite();
}

/// Le serveur a refuse la creation, avec son motif en clair.
final class CreationRefusee extends ResultatCreationClasse {
  /// Cree le resultat.
  const CreationRefusee(this.motif);

  /// Le motif, deja mis en mots par le serveur.
  final String motif;
}

/// La reponse du serveur a la confirmation d'un enseignant.
enum ResultatAffectation {
  /// L'enseignant est affecte ; les familles sont prevenues.
  affecte,

  /// Un autre membre de la direction a deja confirme un enseignant pour
  /// cette classe : rien n'a change.
  dejaAffecte,
}

/// Le port des regroupements de demandes (OFFRES-ADM-1).
abstract interface class PortRegroupementsAdmin {
  /// Les regroupements ouverts : ceux qui attendent leur classe, et ceux
  /// dont la classe attend son enseignant.
  Future<List<RegroupementDemandes>> regroupements();

  /// Cree la classe du regroupement [regroupementId] et y integre ses
  /// eleves. [cleEnvoi] est la meme pour toutes les pressions d'une meme
  /// feuille : le serveur ne cree jamais deux fois. Leve une exception quand
  /// la reponse n'arrive pas : l'ecran ne suppose alors aucun etat.
  Future<ResultatCreationClasse> creerClasse({
    required String regroupementId,
    required GenreClasse genre,
    required String libelle,
    required String cleEnvoi,
  });

  /// Confirme l'enseignant [enseignantId] pour la classe [classeId] et
  /// previent les familles.
  Future<ResultatAffectation> affecterEnseignant({
    required String classeId,
    required String enseignantId,
  });
}

/// Le port : absent avant le branchement serveur.
final Provider<PortRegroupementsAdmin?> portRegroupementsAdminProvider =
    Provider<PortRegroupementsAdmin?>((Ref _) => null);

/// L'identifiant de la dependance serveur, pour la trace et les tests
/// (jamais affiche).
const String dependanceRegroupements = 'DB-OFFRES-ADM-1';

/// Les regroupements ouverts. Sans port : [CapaciteIndisponible], que
/// l'ecran dit en clair. Aucune retentative automatique : une source
/// indisponible le reste, et un echec se relit par « Reessayer ».
final FutureProvider<List<RegroupementDemandes>> regroupementsAdminProvider =
    FutureProvider<List<RegroupementDemandes>>((Ref ref) {
      final PortRegroupementsAdmin? port = ref.watch(
        portRegroupementsAdminProvider,
      );
      if (port == null) {
        return Future<List<RegroupementDemandes>>.error(
          const CapaciteIndisponible(dependanceRegroupements),
        );
      }
      return port.regroupements();
    }, retry: (int _, Object _) => null);
