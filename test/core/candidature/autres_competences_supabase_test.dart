// CAND-07 : l'adaptateur Supabase des autres competences sur les RPC de
// CAND-AUTRES (`lire_autres_competences`, `enregistrer_autres_competences`,
// `retirer_autres_competences`, `lire_catalogue_competences`). Ce que le test
// prouve :
// - la forme envoyee : domaines code -> niveau, texte « autre », disponibilite,
//   accord, version attendue, cle ; jamais un montant, jamais une autre cle ;
// - les refus metier arrivent DANS la reponse (`{"erreur": ...}`) et deviennent
//   une exception typee, un par code, sans jamais afficher le code ;
// - 42501 devient `PermissionInsuffisante`, une fonction absente du serveur
//   (lot non verse) devient `CapaciteIndisponible`, une panne reseau devient
//   `HorsLigneCandidature` (issue non confirmee) ;
// - une reponse mal formee n'est jamais un succes (`FormatException`).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/autres_competences_supabase.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fixtures/candidature/faux_autres_competences.dart';

const Map<String, String> _json = <String, String>{
  'content-type': 'application/json',
};

class _Appel {
  _Appel(this.fonction, this.corps);

  final String fonction;
  final Map<String, dynamic> corps;
}

SupabaseClient _client(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => SupabaseClient(
  'https://exemple.supabase.co',
  'cle-anonyme',
  httpClient: MockClient((http.Request r) async {
    // Une RPC sans parametre envoie `null` comme corps.
    final Object? corps = r.body.isEmpty ? null : jsonDecode(r.body);
    final _Appel a = _Appel(
      r.url.pathSegments.last,
      corps is Map<String, dynamic> ? corps : <String, dynamic>{},
    );
    appels.add(a);
    final http.Response h = repondre(a);
    return http.Response(h.body, h.statusCode, headers: h.headers, request: r);
  }),
);

AutresCompetencesSupabase _port(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => AutresCompetencesSupabase(_client(repondre, appels));

http.Response _ok(Object? corps) =>
    http.Response(jsonEncode(corps), 200, headers: _json);

http.Response _erreurPg(String code, String message, {int statut = 400}) =>
    http.Response(
      jsonEncode(<String, String>{'code': code, 'message': message}),
      statut,
      headers: _json,
    );

Future<ResultatEnregistrement> _enregistrer(
  AutresCompetencesSupabase port, {
  Map<String, NiveauCompetence> domaines = const <String, NiveauCompetence>{
    'comptabilite': NiveauCompetence.metier,
  },
}) => port.enregistrer(
  domaines: domaines,
  disponibilite: DisponibiliteMission.miTemps,
  accord: true,
  versionAttendue: 2,
  cleIdempotence: 'cle-de-test-0001',
);

void main() {
  group('lire', () {
    test('la lecture : ouvert, version, reponses, referentiel', () async {
      final List<_Appel> appels = <_Appel>[];
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(
          autresCompetencesJsonDeTest(
            version: 3,
            reponses: reponsesJsonDeTest(autreTexte: null),
          ),
        ),
        appels,
      );
      final AutresCompetences lue = await port.lire();
      expect(appels.single.fonction, 'lire_autres_competences');
      expect(lue.ouvert, isTrue);
      expect(lue.raison, isNull);
      expect(lue.version, 3);
      expect(lue.reponses!.domaines['comptabilite'], NiveauCompetence.metier);
      expect(lue.reponses!.disponibilite, DisponibiliteMission.quelquesHeures);
      expect(lue.reponses!.accord, isTrue);
      expect(lue.reponses!.accordLe, DateTime.utc(2026, 10, 22, 14, 5));
      expect(lue.referentiel.competences, hasLength(25));
      expect(lue.referentiel.autreTexteMax, 200);
    });

    test('une personne sans reponse : version 0 et aucune reponse', () async {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(autresCompetencesJsonDeTest()),
        <_Appel>[],
      );
      final AutresCompetences lue = await port.lire();
      expect(lue.version, 0);
      expect(lue.reponses, isNull);
      expect(lue.aDesReponses, isFalse);
    });

    test('pas encore ouvert : la raison est rendue', () async {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(
          autresCompetencesJsonDeTest(
            ouvert: false,
            raison: 'questionnaire_non_envoye',
          ),
        ),
        <_Appel>[],
      );
      final AutresCompetences lue = await port.lire();
      expect(lue.ouvert, isFalse);
      expect(lue.raison, RaisonFermeture.questionnaireNonEnvoye);
    });

    test('une competence desactivee de sa reponse reste lisible', () async {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(
          autresCompetencesJsonDeTest(
            version: 1,
            reponses: reponsesJsonDeTest(
              domaines: const <String, String>{'tests_niveau': 'debutant'},
            ),
            desactivees: <String>{'tests_niveau'},
          ),
        ),
        <_Appel>[],
      );
      final AutresCompetences lue = await port.lire();
      final EntreeCatalogue e = lue.referentiel.entree('tests_niveau')!;
      expect(e.actif, isFalse);
      expect(e.libelle, 'Tests de niveau');
    });

    test('un code que cette version ne connait pas garde le libelle du '
        'catalogue', () async {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(
          autresCompetencesJsonDeTest(
            ajoutees: <Map<String, Object?>>[
              entreeJsonDeTest(
                'moderation_forum',
                famille: 'administration',
                ordre: 6,
                libelle: 'Modération du forum',
                exemple: 'Relire les messages',
              ),
            ],
          ),
        ),
        <_Appel>[],
      );
      final AutresCompetences lue = await port.lire();
      final EntreeCatalogue e = lue.referentiel.entree('moderation_forum')!;
      expect(e.libelle, 'Modération du forum');
      expect(e.famille, FamilleCompetence.administration);
    });

    test('une reponse sans le booleen « ouvert » n est pas une lecture', () {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{'version': 1}),
        <_Appel>[],
      );
      expect(port.lire(), throwsA(isA<FormatException>()));
    });

    test('42501 : permission insuffisante, sans « Reessayer »', () {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _erreurPg('42501', 'reserve au titulaire', statut: 403),
        <_Appel>[],
      );
      expect(port.lire(), throwsA(isA<PermissionInsuffisante>()));
    });

    test('un lot serveur non verse : capacite indisponible', () {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _erreurPg('PGRST202', 'fonction absente', statut: 404),
        <_Appel>[],
      );
      expect(
        port.lire(),
        throwsA(
          isA<CapaciteIndisponible>().having(
            (CapaciteIndisponible e) => e.dependance,
            'dependance',
            dependanceAutresCompetences,
          ),
        ),
      );
    });

    test('un reseau coupe : hors ligne, issue non confirmee', () {
      final AutresCompetencesSupabase port = AutresCompetencesSupabase(
        SupabaseClient(
          'https://exemple.supabase.co',
          'cle-anonyme',
          httpClient: MockClient(
            (http.Request r) async => throw http.ClientException('coupe'),
          ),
        ),
      );
      expect(port.lire(), throwsA(isA<HorsLigneCandidature>()));
    });
  });

  group('enregistrer', () {
    test('la forme envoyee : domaines, texte, disponibilite, accord, version, '
        'cle', () async {
      final List<_Appel> appels = <_Appel>[];
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'version': 3,
          'inchange': false,
          'rejoue': false,
        }),
        appels,
      );
      final ResultatEnregistrement r = await port.enregistrer(
        domaines: const <String, NiveauCompetence>{
          'comptabilite': NiveauCompetence.metier,
          'autre': NiveauCompetence.debutant,
        },
        autreTexte: 'Secrétariat médical',
        disponibilite: DisponibiliteMission.pasMaintenant,
        accord: false,
        versionAttendue: 2,
        cleIdempotence: 'cle-de-test-0001',
      );
      expect(r.version, 3);
      expect(r.inchange, isFalse);
      expect(appels.single.fonction, 'enregistrer_autres_competences');
      expect(appels.single.corps, <String, dynamic>{
        'p_domaines': <String, String>{
          'comptabilite': 'metier',
          'autre': 'debutant',
        },
        'p_autre_texte': 'Secrétariat médical',
        'p_disponibilite': 'pas_maintenant',
        'p_accord': false,
        'p_version_attendue': 2,
        'p_cle_idempotence': 'cle-de-test-0001',
      });
    });

    test('sans « autre », le texte part nul', () async {
      final List<_Appel> appels = <_Appel>[];
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'version': 1,
          'inchange': false,
          'rejoue': false,
        }),
        appels,
      );
      await _enregistrer(port);
      expect(appels.single.corps['p_autre_texte'], isNull);
    });

    test('une cle rejouee rend le premier resultat, marque rejoue', () async {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'version': 3,
          'inchange': false,
          'rejoue': true,
        }),
        <_Appel>[],
      );
      expect((await _enregistrer(port)).rejoue, isTrue);
    });

    test('jamais une reponse dans le resultat : l ecran relit', () async {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'version': 3,
          'inchange': true,
          'rejoue': false,
          'reponses': <String, Object?>{'domaines': <String, String>{}},
        }),
        <_Appel>[],
      );
      final ResultatEnregistrement r = await _enregistrer(port);
      expect(r.inchange, isTrue);
    });

    final Map<String, (Map<String, Object?>, Matcher)> refus =
        <String, (Map<String, Object?>, Matcher)>{
          'questionnaire non envoye': (
            <String, Object?>{'erreur': 'questionnaire_non_envoye'},
            isA<QuestionnaireNonEnvoye>(),
          ),
          'candidature close (l issue est rendue)': (
            <String, Object?>{
              'erreur': 'candidature_close',
              'issue': 'refusee',
            },
            isA<CandidatureClose>().having(
              (CandidatureClose e) => e.issue,
              'issue',
              IssueCandidature.refusee,
            ),
          ),
          'conflit (la version courante est rendue)': (
            <String, Object?>{
              'erreur': 'conflit_autres_competences',
              'versionCourante': 5,
            },
            isA<ConflitAutresCompetences>().having(
              (ConflitAutresCompetences e) => e.versionCourante,
              'versionCourante',
              5,
            ),
          ),
          'cle reutilisee': (
            <String, Object?>{'erreur': 'cle_idempotence_reutilisee'},
            isA<CleAutresCompetencesReutilisee>(),
          ),
          'reponses invalides, une competence desactivee': (
            <String, Object?>{
              'erreur': 'reponses_invalides',
              'champs': <String>['domaines'],
              'motifs': <String, String>{'domaines': 'domaine_desactive'},
            },
            isA<ReponsesAutresCompetencesInvalides>()
                .having(
                  (ReponsesAutresCompetencesInvalides e) => e.champs,
                  'champs',
                  <String>['domaines'],
                )
                .having(
                  (ReponsesAutresCompetencesInvalides e) => e.domaineDesactive,
                  'domaineDesactive',
                  isTrue,
                ),
          ),
          'reponses invalides, un texte trop long': (
            <String, Object?>{
              'erreur': 'reponses_invalides',
              'champs': <String>['autreTexte'],
              'motifs': <String, String>{'autreTexte': 'texte_trop_long'},
            },
            isA<ReponsesAutresCompetencesInvalides>().having(
              (ReponsesAutresCompetencesInvalides e) => e.texteTropLong,
              'texteTropLong',
              isTrue,
            ),
          ),
        };
    refus.forEach((String nom, (Map<String, Object?>, Matcher) cas) {
      test('refus rendu : $nom', () {
        final AutresCompetencesSupabase port = _port(
          (_Appel a) => _ok(cas.$1),
          <_Appel>[],
        );
        expect(_enregistrer(port), throwsA(cas.$2));
      });
    });

    test('un refus inconnu n est jamais un succes', () {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{'erreur': 'refus_de_demain'}),
        <_Appel>[],
      );
      expect(_enregistrer(port), throwsA(isA<FormatException>()));
    });

    test('22023 (argument mal forme) remonte tel quel, sans etre cache', () {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _erreurPg('22023', 'cle invalide'),
        <_Appel>[],
      );
      expect(_enregistrer(port), throwsA(isA<PostgrestException>()));
    });

    test('un reseau coupe : issue non confirmee', () {
      final AutresCompetencesSupabase port = AutresCompetencesSupabase(
        SupabaseClient(
          'https://exemple.supabase.co',
          'cle-anonyme',
          httpClient: MockClient(
            (http.Request r) async => throw http.ClientException('coupe'),
          ),
        ),
      );
      expect(_enregistrer(port), throwsA(isA<HorsLigneCandidature>()));
    });
  });

  group('retirer', () {
    test('la forme envoyee et le resultat', () async {
      final List<_Appel> appels = <_Appel>[];
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'retire': true,
          'version': 0,
          'rejoue': false,
        }),
        appels,
      );
      final ResultatRetrait r = await port.retirer(
        versionAttendue: 4,
        cleIdempotence: 'cle-de-test-0002',
      );
      expect(r.retire, isTrue);
      expect(appels.single.fonction, 'retirer_autres_competences');
      expect(appels.single.corps, <String, dynamic>{
        'p_version_attendue': 4,
        'p_cle_idempotence': 'cle-de-test-0002',
      });
    });

    test('rien n etait enregistre : retire = faux', () async {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'retire': false,
          'version': 0,
          'rejoue': false,
        }),
        <_Appel>[],
      );
      final ResultatRetrait r = await port.retirer(
        versionAttendue: 0,
        cleIdempotence: 'cle-de-test-0003',
      );
      expect(r.retire, isFalse);
    });

    test('un conflit de version : exception typee', () {
      final AutresCompetencesSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'erreur': 'conflit_autres_competences',
          'versionCourante': 6,
        }),
        <_Appel>[],
      );
      expect(
        port.retirer(versionAttendue: 4, cleIdempotence: 'cle-de-test-0004'),
        throwsA(isA<ConflitAutresCompetences>()),
      );
    });
  });

  group('le catalogue lu par la direction', () {
    test('tout le catalogue, avec les versions et peutModifier', () async {
      final List<_Appel> appels = <_Appel>[];
      final CatalogueCompetencesSupabase port = CatalogueCompetencesSupabase(
        _client(
          (_Appel a) => _ok(<String, Object?>{
            'familles': famillesDeTest,
            'competences': catalogueJsonDeTest(
              desactivees: <String>{'photographie'},
              avecVersion: true,
            ),
            'peutModifier': true,
          }),
          appels,
        ),
      );
      final CatalogueCompetences c = await port.lire();
      expect(appels.single.fonction, 'lire_catalogue_competences');
      expect(c.peutModifier, isTrue);
      expect(c.competences, hasLength(25));
      expect(c.entree('photographie')!.actif, isFalse);
      expect(c.entree('comptabilite')!.version, 1);
      expect(c.familles, hasLength(6));
    });

    test('un compte qui n est ni la direction ni le titulaire : 42501', () {
      final CatalogueCompetencesSupabase port = CatalogueCompetencesSupabase(
        _client(
          (_Appel a) => _erreurPg('42501', 'reserve', statut: 403),
          <_Appel>[],
        ),
      );
      expect(port.lire(), throwsA(isA<PermissionInsuffisante>()));
    });
  });

  group('les formes', () {
    test(
      'une entree sans libelle ou sans famille n est pas une competence',
      () {
        expect(
          EntreeCatalogue.depuisJson(<String, Object?>{
            'code': 'x',
            'famille': 'technique',
            'libelle': '  ',
          }),
          isNull,
        );
        expect(
          EntreeCatalogue.depuisJson(<String, Object?>{
            'code': 'x',
            'libelle': 'Un libelle',
          }),
          isNull,
        );
      },
    );

    test(
      'une famille inconnue de cette version reste lisible sans etre nommee',
      () {
        final EntreeCatalogue e = EntreeCatalogue.depuisJson(<String, Object?>{
          'code': 'x_y',
          'famille': 'sante',
          'ordre': 1,
          'libelle': 'Premiers secours',
        })!;
        expect(e.famille, isNull);
        expect(e.familleCode, 'sante');
      },
    );

    test(
      'les reponses : un niveau inconnu n entre pas, l accord a sa date',
      () {
        final ReponsesAutresCompetences r =
            ReponsesAutresCompetences.depuisJson(
              reponsesJsonDeTest(
                domaines: const <String, String>{
                  'comptabilite': 'metier',
                  'assistanat': 'maitre_zen',
                },
              ),
            )!;
        expect(r.domaines.keys, <String>['comptabilite']);
        expect(r.accordLe, isNotNull);
      },
    );
  });
}
