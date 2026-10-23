// Le double du port du candidat, oracle des tests de widget de CAND-01.
// Importe par aucune ligne de production (`CONTRAT_PORTS_CANDIDATURES.md`,
// section 6, premier double).
//
// Il rejoue ce que fait le serveur de CAND-L2A1 : la definition du
// questionnaire `salle-examen-1` (mêmes champs, mêmes codes, mêmes listes),
// les refus qu'il rend par une exception typee, et la concurrence par version.
// Aucune regle metier de plus : un test qui veut un refus le programme.

import 'dart:async';

import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/pays_iso.dart';

/// Les fuseaux que le serveur de test propose (sous-ensemble de
/// `pg_timezone_names` : les lieux nommes par l'application, plus Dakar).
const List<String> fuseauxDeTest = <String>[
  'Africa/Abidjan',
  'Africa/Casablanca',
  'Africa/Conakry',
  'Africa/Dakar',
  'Africa/Lagos',
  'America/Argentina/Buenos_Aires',
  'America/Los_Angeles',
  'America/New_York',
  'America/Toronto',
  'Asia/Riyadh',
  'Asia/Tokyo',
  'Europe/London',
  'Europe/Paris',
];

/// Les langues hors referentiel de la definition `salle-examen-1` (22/10) :
/// celles du public de l'academie, puis les autres, et « autre » qui ferme la
/// liste. L'arabe y est : il reste une langue maternelle possible, mais le
/// champ des langues d'explication l'exclut.
const List<String> languesHorsReferentielDeTest = <String>[
  'man',
  'sus',
  'sw',
  'ha',
  'wo',
  'bm',
  'snk',
  'mnk',
  'ar',
  'ps',
  'ur',
  'om',
  'am',
  'yo',
  'bn',
  'fa',
  'id',
  'so',
  'hi',
  'uz',
  'tr',
  'de',
  'pt',
  'ru',
  'autre',
];

/// Les vingt riwayat de la definition `salle-examen-1`.
const List<String> riwayatDeTest = <String>[
  'hafs',
  'shuba',
  'warsh',
  'qalun',
  'al_bazzi',
  'qunbul',
  'ad_duri_abi_amr',
  'as_susi',
  'hisham',
  'ibn_dhakwan',
  'khalaf_an_hamza',
  'khallad',
  'abu_al_harith',
  'ad_duri_al_kisai',
  'ibn_wardan',
  'ibn_jammaz',
  'ruways',
  'rawh',
  'ishaq',
  'idris',
];

/// La reponse de `questionnaire_salle_examen()` pour la version
/// `salle-examen-1`, a la forme du serveur (JSON), pour que le test lise ce
/// que l'application lirait.
Map<String, dynamic> questionnaireJsonDeTest({
  String version = 'salle-examen-1',
  int candidatureVersion = 3,
  int versionBrouillon = 0,
  Map<String, Object?>? dernieresReponses,
  bool brouillon = true,
  bool perime = false,
  int classesMax = 3,
  bool moyensConnus = true,
}) => <String, dynamic>{
  'disponible': true,
  'version': version,
  'candidatureVersion': candidatureVersion,
  'versionBrouillon': versionBrouillon,
  'champs': <Map<String, dynamic>>[
    <String, dynamic>{
      'code': 'langueMaternelle',
      'carte': 'langues',
      'type': 'choix',
      'requis': false,
      'options': <Object>[
        <String, Object>{'code': 'poular', 'referentiel': true},
        <String, Object>{'code': 'francais', 'referentiel': true},
        <String, Object>{'code': 'english', 'referentiel': true},
        for (final String c in languesHorsReferentielDeTest)
          <String, Object>{'code': c, 'referentiel': false},
      ],
    },
    <String, dynamic>{
      'code': 'languesExplication',
      'carte': 'langues',
      'type': 'choix_multiple',
      'requis': true,
      'min': 1,
      'options': <Object>[
        <String, Object>{'code': 'poular', 'referentiel': true},
        <String, Object>{'code': 'francais', 'referentiel': true},
        <String, Object>{'code': 'english', 'referentiel': true},
        // L'arabe n'est pas une langue de cours : le serveur ne le rend pas.
        for (final String c in languesHorsReferentielDeTest)
          if (c != 'ar') <String, Object>{'code': c, 'referentiel': false},
      ],
    },
    <String, dynamic>{
      'code': 'niveauMemorisationDeclare',
      'carte': 'recitation',
      'type': 'choix',
      'requis': true,
      'options': <String>[
        'aucune',
        'moins_10_juz',
        'de_10_a_29_juz',
        'coran_entier',
      ],
    },
    <String, dynamic>{
      'code': 'niveauLectureTajwid',
      'carte': 'recitation',
      'type': 'choix',
      'requis': true,
      'options': <String>[
        'lecture_sans_regles_tajwid',
        'tajwid_applique',
        'tajwid_enseigne',
      ],
    },
    <String, dynamic>{
      'code': 'riwayat',
      'carte': 'recitation',
      'type': 'choix_multiple',
      'requis': true,
      'min': 1,
      'max': 20,
      'options': riwayatDeTest,
    },
    <String, dynamic>{
      'code': 'ijazaPresentable',
      'carte': 'recitation',
      'type': 'choix',
      'requis': true,
      'options': <String>['oui', 'pret_test', 'non'],
    },
    <String, dynamic>{
      'code': 'experienceDebutants',
      'carte': 'recitation',
      'type': 'choix',
      'requis': true,
      'options': <String>['oui', 'non'],
    },
    <String, dynamic>{
      'code': 'disponibilitesDeclarees',
      'carte': 'disponibilites',
      'type': 'creneaux',
      'requis': true,
      'min': 1,
      'max': 168,
      'options': <Object>[],
    },
    <String, dynamic>{
      'code': 'fuseauIana',
      'carte': 'disponibilites',
      'type': 'choix',
      'requis': true,
      'options': fuseauxDeTest,
    },
    <String, dynamic>{
      'code': 'classesSouhaitees',
      'carte': 'disponibilites',
      'type': 'choix',
      'requis': true,
      // De 1 au maximum de Classes par enseignant que regle la direction.
      'options': <String>[for (int n = 1; n <= classesMax; n++) '$n'],
    },
    <String, dynamic>{
      'code': 'debutPossible',
      'carte': 'disponibilites',
      'type': 'choix',
      'requis': true,
      'options': <String>[
        'immediat',
        'mois_prochain',
        'sous_3_mois',
        'inconnu',
      ],
    },
    <String, dynamic>{
      'code': 'publics',
      'carte': 'publics',
      'type': 'choix_multiple',
      'requis': true,
      'min': 1,
      'max': 4,
      'options': <String>['6_9', '10_13', '14_17', 'adultes'],
    },
    <String, dynamic>{
      'code': 'paysResidence',
      'carte': 'versement',
      'type': 'choix',
      'requis': true,
      'options': <String>[for (final PaysIso p in paysIso) p.code],
    },
    <String, dynamic>{
      'code': 'paysVersement',
      'carte': 'versement',
      'type': 'choix',
      'requis': true,
      'options': <String>[for (final PaysIso p in paysIso) p.code],
    },
    <String, dynamic>{
      'code': 'compteBancaire',
      'carte': 'versement',
      'type': 'booleen',
      'requis': true,
      'options': <Object>[],
    },
    <String, dynamic>{
      'code': 'operateurs',
      'carte': 'versement',
      'type': 'choix_multiple',
      'requis': false,
      'min': 0,
      'max': 10,
      'dependDe': 'paysVersement',
      'options': <Object>[],
    },
    // Facultatif et informatif : tous les moyens connus du catalogue, confirmes
    // ou non, sans pays ni etat (le serveur ne les lit jamais pour le versement).
    <String, dynamic>{
      'code': 'moyensAccessibles',
      'carte': 'versement',
      'type': 'choix_multiple',
      'requis': false,
      'min': 0,
      'options': <Object>[
        if (moyensConnus) ...<Map<String, Object>>[
          <String, Object>{
            'code': 'wave',
            'methode': 'mobile_money',
            'nom': 'Wave',
          },
          <String, Object>{
            'code': 'orange_money',
            'methode': 'mobile_money',
            'nom': 'Orange Money',
          },
          <String, Object>{
            'code': 'moov_money',
            'methode': 'mobile_money',
            'nom': 'Moov Money',
          },
        ],
      ],
    },
  ],
  'dernieresReponses': dernieresReponses == null
      ? null
      : <String, dynamic>{
          'questionnaireVersion': version,
          'reponses': dernieresReponses,
          'brouillon': brouillon,
          'soumisLe': '2026-10-22T09:00:00Z',
          'envoyeLe': brouillon ? null : '2026-10-22T09:05:00Z',
          'perime': perime,
        },
};

/// Des reponses completes et valides pour `salle-examen-1`. Les disponibilites
/// sont les plages que le serveur recoit pour des cours d'enfants (60 minutes) :
/// les heures de debut 18 h et 19 h du lundi, du mercredi et du vendredi.
Map<String, Object?> reponsesCompletesDeTest() => <String, Object?>{
  'langueMaternelle': 'poular',
  'languesExplication': <String>['poular', 'francais'],
  'niveauMemorisationDeclare': 'de_10_a_29_juz',
  'niveauLectureTajwid': 'tajwid_applique',
  'riwayat': <String>['hafs'],
  'ijazaPresentable': 'non',
  'experienceDebutants': 'oui',
  'disponibilitesDeclarees': <Map<String, Object?>>[
    <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '20:00'},
    <String, Object?>{'jour': 3, 'debut': '18:00', 'fin': '20:00'},
    <String, Object?>{'jour': 5, 'debut': '18:00', 'fin': '20:00'},
  ],
  'fuseauIana': 'Africa/Conakry',
  'classesSouhaitees': '1',
  'debutPossible': 'mois_prochain',
  'publics': <String>['6_9'],
  'paysResidence': 'GN',
  'paysVersement': 'GN',
  'compteBancaire': false,
  'operateurs': <String>['orange_money'],
};

/// Un envoi vu par le double.
class EnvoiVu {
  /// Cree l'envoi.
  EnvoiVu({
    required this.versionQuestionnaire,
    required this.reponses,
    required this.accordRemuneration,
    required this.versionConditions,
    required this.versionAttendue,
    required this.cleIdempotence,
  });

  /// La version du questionnaire envoyee.
  final String versionQuestionnaire;

  /// Les reponses envoyees.
  final Map<String, Object?> reponses;

  /// La case des conditions de remuneration.
  final bool accordRemuneration;

  /// La version des conditions lue.
  final String versionConditions;

  /// La version attendue de la candidature.
  final int versionAttendue;

  /// La cle d'idempotence.
  final String cleIdempotence;
}

/// Le double du port.
class FauxMaCandidature implements PortMaCandidature {
  /// Cree le double.
  FauxMaCandidature({
    Map<String, dynamic>? questionnaireJson,
    this.conditions = const ConditionsRemuneration(
      version: 'v2.0.0',
      enVigueur: true,
      publics: <PublicRemuneration>[
        PublicRemuneration(code: 'enfant', partPourMille: 470),
        PublicRemuneration(code: 'adulte', partPourMille: 470),
      ],
    ),
    Map<String, MoyensConfirmes>? moyens,
  }) : questionnaireJson = questionnaireJson ?? questionnaireJsonDeTest(),
       moyens = moyens ?? _moyensParDefaut;

  static const Map<String, MoyensConfirmes> _moyensParDefaut =
      <String, MoyensConfirmes>{
        'GN': MoyensConfirmes(
          operateurs: <OperateurPaiement>[
            OperateurPaiement(code: 'orange_money', nom: 'Orange Money'),
            OperateurPaiement(code: 'wave', nom: 'Wave'),
          ],
        ),
        'SA': MoyensConfirmes(virementBancaire: true),
      };

  /// La reponse du questionnaire, a la forme du serveur.
  Map<String, dynamic> questionnaireJson;

  /// Les conditions de remuneration rendues.
  ConditionsRemuneration conditions;

  /// Les moyens confirmes par pays ; un pays absent n'en a aucun.
  Map<String, MoyensConfirmes> moyens;

  /// Une erreur a lever a la lecture du questionnaire.
  Object? erreurQuestionnaire;

  /// Une erreur a lever a la lecture des conditions.
  Object? erreurConditions;

  /// Une erreur a lever a la lecture des moyens.
  Object? erreurMoyens;

  /// Une erreur a lever a l'envoi (une seule fois si [erreurEnvoiUneFois]).
  Object? erreurEnvoi;

  /// Vrai : l'erreur d'envoi ne sert qu'une fois.
  bool erreurEnvoiUneFois = true;

  /// Une erreur a lever au retrait.
  Object? erreurRetrait;

  /// Une erreur a lever a l'enregistrement du brouillon.
  Object? erreurBrouillon;

  /// Si non nul, l'envoi attend ce completer.
  Completer<void>? attenteEnvoi;

  /// Le bloc `candidature` rendu apres l'envoi.
  CandidatureDossier candidatureApresEnvoi = const CandidatureDossier(
    existe: true,
    etape: EtapeCandidature.prequalification,
    etat: EtatCandidature.enExamen,
    version: 4,
  );

  /// Le bloc `candidature` rendu apres le retrait.
  CandidatureDossier candidatureApresRetrait = const CandidatureDossier(
    existe: true,
    etape: EtapeCandidature.prequalification,
    issue: IssueCandidature.retiree,
    version: 4,
  );

  /// Les brouillons enregistres, dans l'ordre.
  final List<Map<String, Object?>> brouillons = <Map<String, Object?>>[];

  /// Les versions de brouillon recues, dans l'ordre.
  final List<int> versionsBrouillonRecues = <int>[];

  /// Les envois recus, dans l'ordre.
  final List<EnvoiVu> envois = <EnvoiVu>[];

  /// Les retraits recus (version attendue, cle).
  final List<(int, String)> retraits = <(int, String)>[];

  /// Les pays dont les moyens ont ete lus.
  final List<String> moyensLus = <String>[];

  /// Le nombre de lectures du questionnaire.
  int lecturesQuestionnaire = 0;

  int? _versionBrouillon;

  @override
  Future<ConditionsRemuneration> conditionsRemuneration() async {
    final Object? e = erreurConditions;
    if (e != null) {
      // Un Object : le vrai client jette aussi des erreurs de plateforme.
      // ignore: only_throw_errors
      throw e;
    }
    return conditions;
  }

  @override
  Future<Questionnaire> questionnaire() async {
    lecturesQuestionnaire++;
    final Object? e = erreurQuestionnaire;
    if (e != null) {
      // Un Object : le vrai client jette aussi des erreurs de plateforme.
      // ignore: only_throw_errors
      throw e;
    }
    return Questionnaire.depuisJson(questionnaireJson);
  }

  @override
  Future<MoyensConfirmes> moyensConfirmes(String paysVersement) async {
    moyensLus.add(paysVersement);
    final Object? e = erreurMoyens;
    if (e != null) {
      // Un Object : le vrai client jette aussi des erreurs de plateforme.
      // ignore: only_throw_errors
      throw e;
    }
    return moyens[paysVersement] ?? const MoyensConfirmes();
  }

  @override
  Future<ResultatBrouillon> enregistrerBrouillon({
    required String versionQuestionnaire,
    required Map<String, Object?> reponses,
    required int versionBrouillon,
    required String cleIdempotence,
  }) async {
    final Object? e = erreurBrouillon;
    if (e != null) {
      // Un Object : le vrai client jette aussi des erreurs de plateforme.
      // ignore: only_throw_errors
      throw e;
    }
    versionsBrouillonRecues.add(versionBrouillon);
    // Le serveur compare la version attendue a celle du brouillon ouvert
    // (0 sans brouillon) : une autre valeur est un conflit, sans ecriture.
    final int courante =
        _versionBrouillon ??
        (questionnaireJson['versionBrouillon'] as int? ?? 0);
    if (versionBrouillon != courante) {
      throw ConflitBrouillon(courante);
    }
    brouillons.add(Map<String, Object?>.from(reponses));
    _versionBrouillon = courante + 1;
    return ResultatBrouillon(versionBrouillon: courante + 1, complet: false);
  }

  @override
  Future<CandidatureDossier> envoyerReponses({
    required String versionQuestionnaire,
    required Map<String, Object?> reponses,
    required bool accordRemuneration,
    required String versionConditions,
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    envois.add(
      EnvoiVu(
        versionQuestionnaire: versionQuestionnaire,
        reponses: Map<String, Object?>.from(reponses),
        accordRemuneration: accordRemuneration,
        versionConditions: versionConditions,
        versionAttendue: versionAttendue,
        cleIdempotence: cleIdempotence,
      ),
    );
    final Completer<void>? attente = attenteEnvoi;
    if (attente != null) {
      await attente.future;
    }
    final Object? e = erreurEnvoi;
    if (e != null) {
      if (erreurEnvoiUneFois) {
        erreurEnvoi = null;
      }
      // Un Object : le vrai client jette aussi des erreurs de plateforme.
      // ignore: only_throw_errors
      throw e;
    }
    return candidatureApresEnvoi;
  }

  @override
  Future<CandidatureDossier> retirer({
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    retraits.add((versionAttendue, cleIdempotence));
    final Object? e = erreurRetrait;
    if (e != null) {
      // Un Object : le vrai client jette aussi des erreurs de plateforme.
      // ignore: only_throw_errors
      throw e;
    }
    return candidatureApresRetrait;
  }
}

/// Un double dont tout manque : le lot serveur n'est pas verse.
class FauxMaCandidatureIndisponible extends FauxMaCandidature {
  /// Cree le double.
  FauxMaCandidatureIndisponible() {
    erreurQuestionnaire = const CapaciteIndisponible(dependanceCandidature);
    erreurConditions = const CapaciteIndisponible(
      dependanceConditionsRemuneration,
    );
  }
}
