// Le double du port des autres competences, oracle des tests de widget de
// CAND-07 (« Vos autres talents »). Importe par aucune ligne de production
// (`CONTRAT_PORTS_CANDIDATURES.md`, section 6).
//
// Il rejoue ce que fait le serveur de CAND-AUTRES : le catalogue de 25
// competences en six familles (memes codes, memes familles, memes rangs que la
// migration `20261022000500_cand_autres_competences.sql`), les listes fermees,
// la concurrence par version, l'idempotence par cle, la regle d'une competence
// desactivee, le texte « autre » exige ou refuse, et la fermeture d'une
// candidature close. Aucune regle de plus : un test qui veut un refus le
// programme.

import 'dart:async';

import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_autres_competences.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';

/// Les 25 competences du catalogue initial : code, famille, rang. Les libelles
/// et les exemples sont ceux de la migration (en francais, ceux de la
/// direction), pour qu'un test lise ce que l'application lirait.
const List<(String, String, int, String, String)> catalogueInitialDeTest =
    <(String, String, int, String, String)>[
      (
        'reseaux_sociaux',
        'communication',
        1,
        'Gestion des réseaux sociaux',
        "Publier, animer les comptes de l'académie, répondre aux messages",
      ),
      (
        'relations_publiques',
        'communication',
        2,
        'Relations publiques et partenariats',
        'Mosquées, associations, médias',
      ),
      (
        'design_graphique',
        'communication',
        3,
        'Design graphique',
        'Visuels, affiches, cartes',
      ),
      (
        'montage_video',
        'communication',
        4,
        'Montage vidéo et animation',
        'Courtes vidéos, sous-titres, animations',
      ),
      (
        'photographie',
        'communication',
        5,
        'Photographie et prise de vue',
        'Photos, vidéos, prise de son',
      ),
      (
        'redaction_contenus',
        'communication',
        6,
        'Rédaction et création de contenus',
        "Articles, textes pour les réseaux, lettres d'information",
      ),
      (
        'publicite_en_ligne',
        'communication',
        7,
        'Publicité en ligne',
        'Campagnes, ciblage, suivi des résultats',
      ),
      (
        'traduction',
        'communication',
        8,
        'Traduction',
        'Textes, sous-titres, messages aux familles',
      ),
      (
        'assistanat',
        'administration',
        1,
        'Assistanat administratif ou de direction',
        'Agenda, courriers, organisation du quotidien',
      ),
      (
        'coordination_groupe',
        'administration',
        2,
        "Coordination d'un groupe",
        'Par exemple le groupe des sœurs, ou celui des parents',
      ),
      (
        'accueil_familles',
        'administration',
        3,
        'Accueil et suivi des familles',
        'Répondre aux questions, accompagner une inscription',
      ),
      (
        'gestion_projet',
        'administration',
        4,
        'Planification et gestion de projet',
        "Calendrier, suivi des tâches, coordination d'une équipe",
      ),
      (
        'ressources_humaines',
        'administration',
        5,
        'Ressources humaines et recrutement',
        'Entretiens, sélection, accueil des nouveaux enseignants',
      ),
      (
        'comptabilite',
        'finances_droit',
        1,
        'Comptabilité',
        'Tenue des comptes, factures, bilans',
      ),
      (
        'gestion_financiere',
        'finances_droit',
        2,
        'Gestion financière',
        'Budget, trésorerie, suivi des paiements',
      ),
      (
        'juridique_donnees',
        'finances_droit',
        3,
        'Juridique et protection des données',
        "Contrats, conditions d'utilisation, vie privée",
      ),
      (
        'conception_programmes',
        'pedagogie',
        1,
        'Conception de programmes et de supports',
        'Plans de cours, fiches, exercices',
      ),
      (
        'formation_enseignants',
        'pedagogie',
        2,
        'Formation et accompagnement des enseignants',
        'Former les nouveaux enseignants, les conseiller',
      ),
      (
        'qualite_cours',
        'pedagogie',
        3,
        'Observation et qualité des cours',
        'Observer une séance, donner un retour',
      ),
      (
        'tests_niveau',
        'pedagogie',
        4,
        'Tests de niveau',
        'Évaluer un nouvel élève avant son entrée en classe',
      ),
      (
        'accompagnement_enfants',
        'pedagogie',
        5,
        'Accompagnement des enfants',
        'Psychologie, besoins particuliers',
      ),
      (
        'developpement',
        'technique',
        1,
        'Développement web ou mobile',
        'Sites, applications, outils internes',
      ),
      (
        'assistance_technique',
        'technique',
        2,
        'Assistance technique aux familles et aux enseignants',
        'Aider à se connecter, régler le son et la caméra',
      ),
      (
        'donnees_tableurs',
        'technique',
        3,
        'Données et tableurs',
        'Tableaux de suivi, statistiques, rapports',
      ),
      (
        'autre',
        'autre',
        1,
        'Autre compétence',
        'Quelques mots pour la décrire',
      ),
    ];

/// Les six familles, dans l'ordre d'affichage du serveur.
const List<String> famillesDeTest = <String>[
  'communication',
  'administration',
  'finances_droit',
  'pedagogie',
  'technique',
  'autre',
];

/// Une entree du catalogue, a la forme du serveur (JSON).
Map<String, Object?> entreeJsonDeTest(
  String code, {
  String? famille,
  int? ordre,
  String? libelle,
  String? exemple,
  bool actif = true,
  int? version,
}) {
  final (String, String, int, String, String)? connue = catalogueInitialDeTest
      .where(((String, String, int, String, String) c) => c.$1 == code)
      .firstOrNull;
  return <String, Object?>{
    'code': code,
    'famille': famille ?? connue?.$2 ?? 'autre',
    'ordre': ordre ?? connue?.$3 ?? 99,
    'libelle': libelle ?? connue?.$4 ?? 'Libellé du catalogue',
    'exemple': exemple ?? connue?.$5,
    'actif': actif,
    'version': ?version,
  };
}

/// Les entrees du catalogue initial, a la forme du serveur : les actives, plus
/// celles de [desactivees] rendues avec `actif = false`.
List<Map<String, Object?>> catalogueJsonDeTest({
  Set<String> desactivees = const <String>{},
  Set<String> retirees = const <String>{},
  List<Map<String, Object?>> ajoutees = const <Map<String, Object?>>[],
  bool avecVersion = false,
}) => <Map<String, Object?>>[
  for (final (String, String, int, String, String) c in catalogueInitialDeTest)
    if (!retirees.contains(c.$1))
      entreeJsonDeTest(
        c.$1,
        actif: !desactivees.contains(c.$1),
        version: avecVersion ? 1 : null,
      ),
  ...ajoutees,
];

/// La reponse de `lire_autres_competences()`, a la forme du serveur (JSON).
Map<String, dynamic> autresCompetencesJsonDeTest({
  bool ouvert = true,
  String? raison,
  int version = 0,
  Map<String, Object?>? reponses,
  Set<String> desactivees = const <String>{},
  List<Map<String, Object?>> ajoutees = const <Map<String, Object?>>[],
}) {
  // Ce que fait le serveur : une competence desactivee n'est rendue (avec
  // `actif = false`) que si elle est dans la propre reponse de la personne ;
  // sinon elle n'est plus offerte du tout.
  final Set<String> propres = reponses?['domaines'] is Map
      ? (reponses!['domaines']! as Map<Object?, Object?>).keys
            .whereType<String>()
            .toSet()
      : <String>{};
  return <String, dynamic>{
    'ouvert': ouvert,
    'raison': raison,
    'version': version,
    'reponses': reponses,
    'referentiel': <String, Object?>{
      'familles': famillesDeTest,
      'competences': catalogueJsonDeTest(
        desactivees: desactivees,
        retirees: desactivees.difference(propres),
        ajoutees: ajoutees,
      ),
      'niveaux': <String>['debutant', 'experience', 'metier'],
      'disponibilites': <String>[
        'quelques_heures',
        'mi_temps',
        'plus',
        'pas_maintenant',
      ],
      'autreTexteMax': 200,
    },
  };
}

/// Des reponses enregistrees, a la forme du serveur (JSON).
Map<String, Object?> reponsesJsonDeTest({
  Map<String, String> domaines = const <String, String>{
    'comptabilite': 'metier',
    'reseaux_sociaux': 'experience',
  },
  String? autreTexte,
  String disponibilite = 'quelques_heures',
  bool accord = true,
}) => <String, Object?>{
  'domaines': domaines,
  'autreTexte': autreTexte,
  'disponibilite': disponibilite,
  'accord': accord,
  'accordLe': accord ? '2026-10-22T14:05:00Z' : null,
  'majLe': '2026-10-22T14:05:00Z',
};

/// Un enregistrement vu par le double.
class EnregistrementTalents {
  /// Cree la trace.
  EnregistrementTalents({
    required this.domaines,
    required this.disponibilite,
    required this.accord,
    required this.versionAttendue,
    required this.cleIdempotence,
    this.autreTexte,
  });

  /// Les domaines envoyes.
  final Map<String, NiveauCompetence> domaines;

  /// Le texte « autre » envoye.
  final String? autreTexte;

  /// La disponibilite envoyee.
  final DisponibiliteMission disponibilite;

  /// L'accord envoye.
  final bool accord;

  /// La version attendue envoyee.
  final int versionAttendue;

  /// La cle d'idempotence envoyee.
  final String cleIdempotence;
}

/// Le double du port.
class FauxAutresCompetences implements PortAutresCompetences {
  /// Cree le double. [lectureJson] est la reponse de `lire_autres_competences()` ;
  /// par defaut, ouvert et sans reponse.
  FauxAutresCompetences({Map<String, dynamic>? lectureJson})
    : lectureJson = lectureJson ?? autresCompetencesJsonDeTest();

  /// Ce que rend la prochaine lecture, a la forme du serveur.
  Map<String, dynamic> lectureJson;

  /// Une erreur a lever a la lecture (une fois, puis effacee), ou `null`.
  Object? erreurLecture;

  /// Une erreur a lever a chaque lecture tant qu'elle est posee.
  Object? erreurLectureDurable;

  /// Une erreur a lever au prochain enregistrement (une fois), ou `null`.
  Object? erreurEnregistrement;

  /// Une erreur a lever au prochain retrait (une fois), ou `null`.
  Object? erreurRetrait;

  /// Tant qu'elle est posee, la lecture attend ce completeur.
  Completer<void>? attente;

  /// Tant qu'il est pose, l'enregistrement attend ce completeur.
  Completer<void>? attenteEnregistrement;

  /// Les lectures faites.
  int lectures = 0;

  /// Les enregistrements recus, y compris ceux qui ont echoue.
  final List<EnregistrementTalents> enregistrements = <EnregistrementTalents>[];

  /// Les retraits recus : (version attendue, cle).
  final List<(int, String)> retraits = <(int, String)>[];

  /// Les cles deja gardees avec leur resultat (idempotence).
  final Map<String, ResultatEnregistrement> _cles =
      <String, ResultatEnregistrement>{};

  @override
  Future<AutresCompetences> lire() async {
    lectures++;
    if (attente != null) {
      await attente!.future;
    }
    final Object? durable = erreurLectureDurable;
    if (durable != null) {
      // ignore: only_throw_errors
      throw durable;
    }
    final Object? erreur = erreurLecture;
    if (erreur != null) {
      erreurLecture = null;
      // ignore: only_throw_errors
      throw erreur;
    }
    return AutresCompetences.depuisJson(lectureJson);
  }

  @override
  Future<ResultatEnregistrement> enregistrer({
    required Map<String, NiveauCompetence> domaines,
    required DisponibiliteMission disponibilite,
    required bool accord,
    required int versionAttendue,
    required String cleIdempotence,
    String? autreTexte,
  }) async {
    enregistrements.add(
      EnregistrementTalents(
        domaines: Map<String, NiveauCompetence>.of(domaines),
        autreTexte: autreTexte,
        disponibilite: disponibilite,
        accord: accord,
        versionAttendue: versionAttendue,
        cleIdempotence: cleIdempotence,
      ),
    );
    if (attenteEnregistrement != null) {
      await attenteEnregistrement!.future;
    }
    final Object? erreur = erreurEnregistrement;
    if (erreur != null) {
      erreurEnregistrement = null;
      // ignore: only_throw_errors
      throw erreur;
    }
    final ResultatEnregistrement? rejoue = _cles[cleIdempotence];
    if (rejoue != null) {
      return ResultatEnregistrement(
        version: rejoue.version,
        inchange: rejoue.inchange,
        rejoue: true,
      );
    }
    final AutresCompetences actuel = AutresCompetences.depuisJson(lectureJson);
    if (!actuel.ouvert) {
      if (actuel.raison == RaisonFermeture.questionnaireNonEnvoye) {
        throw const QuestionnaireNonEnvoye();
      }
      throw const CandidatureClose(IssueCandidature.refusee);
    }
    if (versionAttendue != actuel.version) {
      throw ConflitAutresCompetences(actuel.version);
    }
    final List<String> champs = <String>[];
    final Map<String, String> motifs = <String, String>{};
    if (domaines.isEmpty) {
      champs.add('domaines');
      motifs['domaines'] = 'domaines_requis';
    } else {
      for (final String code in domaines.keys) {
        final EntreeCatalogue? e = actuel.referentiel.entree(code);
        if (e == null) {
          champs.add('domaines');
          motifs['domaines'] = 'domaine_inconnu';
          break;
        }
        if (!e.actif &&
            !(actuel.reponses?.domaines.containsKey(code) ?? false)) {
          champs.add('domaines');
          motifs['domaines'] = 'domaine_desactive';
          break;
        }
      }
    }
    final String? texte = autreTexte?.trim();
    final bool autre = domaines.containsKey('autre');
    if (autre && (texte == null || texte.isEmpty)) {
      champs.add('autreTexte');
      motifs['autreTexte'] = 'texte_requis';
    } else if (!autre && texte != null && texte.isNotEmpty) {
      champs.add('autreTexte');
      motifs['autreTexte'] = 'texte_non_attendu';
    } else if (texte != null && texte.length > 200) {
      champs.add('autreTexte');
      motifs['autreTexte'] = 'texte_trop_long';
    }
    if (champs.isNotEmpty) {
      throw ReponsesAutresCompetencesInvalides(champs, motifs: motifs);
    }
    final ReponsesAutresCompetences? avant = actuel.reponses;
    final bool identique =
        avant != null &&
        _memeDomaines(avant.domaines, domaines) &&
        avant.autreTexte == (texte?.isEmpty ?? true ? null : texte) &&
        avant.disponibilite == disponibilite &&
        avant.accord == accord;
    final int version = identique ? actuel.version : actuel.version + 1;
    final ResultatEnregistrement resultat = ResultatEnregistrement(
      version: version,
      inchange: identique,
      rejoue: false,
    );
    if (!identique) {
      _cles[cleIdempotence] = resultat;
      lectureJson = <String, dynamic>{
        ...lectureJson,
        'version': version,
        'reponses': <String, Object?>{
          'domaines': <String, String>{
            for (final MapEntry<String, NiveauCompetence> e in domaines.entries)
              e.key: e.value.valeurSql,
          },
          'autreTexte': texte,
          'disponibilite': disponibilite.valeurSql,
          'accord': accord,
          'accordLe': accord ? '2026-10-23T09:30:00Z' : null,
          'majLe': '2026-10-23T09:30:00Z',
        },
      };
    }
    return resultat;
  }

  @override
  Future<ResultatRetrait> retirer({
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    retraits.add((versionAttendue, cleIdempotence));
    final Object? erreur = erreurRetrait;
    if (erreur != null) {
      erreurRetrait = null;
      // ignore: only_throw_errors
      throw erreur;
    }
    final AutresCompetences actuel = AutresCompetences.depuisJson(lectureJson);
    if (versionAttendue != actuel.version) {
      throw ConflitAutresCompetences(actuel.version);
    }
    final bool retire = actuel.aDesReponses;
    if (retire) {
      lectureJson = <String, dynamic>{
        ...lectureJson,
        'version': 0,
        'reponses': null,
      };
    }
    return ResultatRetrait(retire: retire, version: 0, rejoue: false);
  }

  static bool _memeDomaines(
    Map<String, NiveauCompetence> a,
    Map<String, NiveauCompetence> b,
  ) =>
      a.length == b.length &&
      a.entries.every(
        (MapEntry<String, NiveauCompetence> e) => b[e.key] == e.value,
      );
}

/// Le double du catalogue lu par la direction.
class FauxCatalogueCompetences implements PortCatalogueCompetences {
  /// Cree le double.
  FauxCatalogueCompetences({
    Map<String, dynamic>? json,
    this.erreur,
    this.attente,
  }) : json =
           json ??
           <String, dynamic>{
             'familles': famillesDeTest,
             'competences': catalogueJsonDeTest(avecVersion: true),
             'peutModifier': true,
           };

  /// Ce que rend la lecture, a la forme du serveur.
  Map<String, dynamic> json;

  /// Une erreur a lever a la lecture.
  Object? erreur;

  /// Tant qu'elle est posee, la lecture attend ce completeur.
  Completer<void>? attente;

  /// Les lectures faites.
  int lectures = 0;

  @override
  Future<CatalogueCompetences> lire() async {
    lectures++;
    if (attente != null) {
      await attente!.future;
    }
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur!;
    }
    return CatalogueCompetences.depuisJson(json);
  }
}

/// L'erreur qu'un port sans lot serveur leve.
const CapaciteIndisponible capaciteAutresCompetencesIndisponible =
    CapaciteIndisponible(dependanceAutresCompetences);
