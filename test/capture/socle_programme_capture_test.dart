// SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026) : le Suivi de l'eleve et
// l'Historique du tuteur, branches sur le hub `ma_progression` (qui lit
// `etape_eleve_lecture`), montes par le VRAI routeur, en clair et en sombre, a 390 et 1440 points.
// Eleve adulte (interface standard), enfant (Interface guidee, sans date
// limite), tuteur. Donnees de test seulement (la reponse du serveur est
// simulee ; rien ne vient de la production).
//
// Saute sans CAPTURE_DIR. Usage :
//   CAPTURE_DIR=docs/current/captures/E2E/socle-programme flutter test --no-pub \
//     test/capture/socle_programme_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/suivi/ma_progression.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';

import '../features/historique/support_historique.dart';
import '../router/support_routeur.dart';
import '../support/harnais.dart';
import 'outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;

Map<String, Object?> _etape(
  int ordre,
  String nom,
  String statut,
  int prevue,
  int limite,
) => <String, Object?>{
  'code': 'BASES-$ordre',
  'ordre': ordre,
  'nom': nom,
  'objectifs': <Object?>[],
  'duree_prevue_semaines': prevue < 0 ? null : prevue,
  'date_limite_semaines': limite < 0 ? null : limite,
  'statut': statut,
};

Map<String, Object?> _reponse({required bool dateLimite}) => <String, Object?>{
  'eleve_voit_dates': dateLimite,
  'etape': <String, Object?>{
    'code': 'BASES-1',
    'ordre': 1,
    'nom': 'Les lettres',
    'objectifs': <Object?>[
      'Reconnaît chaque lettre dans le désordre',
      'Prononce chaque lettre depuis son point de sortie',
      'Distingue les lettres qui se ressemblent',
      "Reconnaît une lettre au début, au milieu et à la fin d'un mot",
    ],
    'matiere_principale': 'Le livre de lecture de Rewayah : les lettres',
    'matiere_secondaire': dateLimite
        ? 'Al-Fatiha dès la première semaine, puis An-Nâs, Al-Falaq et '
              'Al-Ikhlâs, puis les paroles de la prière et les ablutions, puis '
              'les autres invocations'
        : null,
    // Enfant de 6 a 9 ans : le serveur ne rend aucune date ni aucune duree.
    'duree_prevue_semaines': dateLimite ? 3 : null,
    'date_limite_semaines': dateLimite ? 4 : null,
    'entree_le': dateLimite ? '2026-10-22' : null,
    'date_limite': dateLimite ? '2026-11-19' : null,
    'semaines_ecoulees': dateLimite ? 3 : null,
    'rythme': dateLimite ? 'dans_les_temps' : null,
  },
  'niveau': <String, Object?>{
    'nom': 'Les bases',
    'horizon': dateLimite ? '2027-03-11' : null,
    'date_limite_visible': dateLimite,
  },
  'chemin': <Object?>[
    _etape(
      1,
      'Les lettres',
      'en_cours',
      dateLimite ? 3 : -1,
      dateLimite ? 4 : -1,
    ),
    _etape(
      2,
      'Lire avec les voyelles',
      'a_venir',
      dateLimite ? 6 : -1,
      dateLimite ? 8 : -1,
    ),
    _etape(
      3,
      'Lire dans le Coran',
      'a_venir',
      dateLimite ? 3 : -1,
      dateLimite ? 4 : -1,
    ),
    _etape(
      4,
      "Les sourates courtes, d'Al-Masad à Az-Zalzalah",
      'a_venir',
      dateLimite ? 3 : -1,
      dateLimite ? 4 : -1,
    ),
  ],
  'sourates': <String, Object?>{'validees': 0, 'total': 17},
  'page_reprise': 3,
};

class _Programme implements ServiceProgramme, ServiceContenuProgramme {
  const _Programme();

  @override
  Future<List<VersionProgramme>> versions() async => <VersionProgramme>[
    VersionProgramme(
      id: 'v2',
      statut: StatutVersionProgramme.brouillon,
      numeroVersion: 2,
      creeParIdentifiant: 'x',
      creeParPrenom: null,
      creeParNom: null,
      publieeAt: null,
      nombreNiveaux: 1,
      createdAt: DateTime.utc(2026, 11, 12),
    ),
  ];

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async =>
      const <NiveauProgramme>[
        NiveauProgramme(
          id: 'n2',
          codeTechnique: 'BASES-2',
          nomHumain: 'Lire avec les voyelles',
          cycle: 'Les bases',
          ordre: 2,
          description: null,
          objectifs: <String>[
            'Lit une lettre avec chacune des trois voyelles',
            'Lit le tanwin',
            'Lit la chadda',
          ],
          durees: <String, DureeEtape>{
            'enfant_6_9': DureeEtape(prevue: 14, limite: 19),
            'enfant_10_13': DureeEtape(prevue: 11, limite: 14),
            'ado_14_17': DureeEtape(prevue: 9, limite: 13),
            'adulte_18_plus': DureeEtape(prevue: 6, limite: 8),
          },
          complet: true,
        ),
      ];

  @override
  Future<String> creerVersion({String? versionSourceId}) async => 'v3';

  @override
  Future<String> ajouterNiveau({
    required String versionId,
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async => 'n';

  @override
  Future<void> modifierNiveau({
    required String niveauId,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async {}

  @override
  Future<void> supprimerNiveau({
    required String niveauId,
    required String motif,
  }) async {}

  @override
  Future<void> publierVersion({
    required String versionId,
    required String motif,
  }) async {}

  @override
  Future<void> modifierContenu({
    required String niveauId,
    required List<String> objectifs,
    required PlageSupport? plage,
    required Map<String, DureeEtape> durees,
  }) async {}

  @override
  Future<void> preremplirBases(String versionId) async {}
}

/// La reponse de `ma_progression` : l'etape et le niveau de la lecture unique,
/// le chemin sous `etapes_du_cycle` (`franchie` pour une etape passee), les
/// sourates et le reglage.
Map<String, Object?> _enHub(Map<String, Object?> lecture) {
  final Map<String, Object?> etape = <String, Object?>{
    ...(lecture['etape']! as Map<String, Object?>),
    'page_reprise': lecture['page_reprise'],
  };
  final Map<String, Object?> sourates =
      lecture['sourates']! as Map<String, Object?>;
  return <String, Object?>{
    if (lecture.containsKey('eleve_voit_dates'))
      'eleve_voit_dates': lecture['eleve_voit_dates'],
    'etape': etape,
    'niveau': lecture['niveau'],
    'etapes_du_cycle': <Object?>[
      for (final Object? e in lecture['chemin']! as List<Object?>)
        <String, Object?>{
          ...(e! as Map<String, Object?>),
          'statut': (e as Map<String, Object?>)['statut'] == 'precedente'
              ? 'franchie'
              : e['statut'],
        },
    ],
    'sourates': <String, Object?>{
      'sourates_validees': sourates['validees'],
      'sourates_total': sourates['total'],
    },
    'reglage': null,
  };
}

class _Port implements PortMaProgression {
  const _Port(this.brut);

  final Map<String, Object?> brut;

  @override
  Future<MaProgression?> pourEleve(String eleveId) async =>
      MaProgression.depuisJson(_enHub(brut));
}

void main() {
  group('Capture SOCLE-PROGRAMME', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      final String nomTheme = theme == ThemeMode.light ? 'clair' : 'sombre';
      for (final double largeur in <double>[390, 1440]) {
        final String l = '${largeur.toInt()}';
        testWidgets('eleve adulte $l $nomTheme', (WidgetTester tester) async {
          await monterRouteur(
            tester,
            Routes.eleveSuivi,
            source: FausseSourceSession(sessionActive(AppRole.student)),
            taille: Size(largeur, 2000),
            themeMode: theme,
            surcharges: <Override>[
              portMaProgressionProvider.overrideWithValue(
                _Port(_reponse(dateLimite: true)),
              ),
              horsLigneProvider.overrideWith(
                (Ref ref) => Stream<bool>.value(false),
              ),
            ],
          );
          await tester.pump(const Duration(milliseconds: 600));
          debugPrint('PNG ${await capturerVue(tester, 'eleve-$l-$nomTheme')}');
        });
        // Refus par defaut (13/11) : un serveur d'avant le socle rend les dates mais
        // pas `eleve_voit_dates` ; l'eleve en presentation standard n'en lit aucune.
        testWidgets('eleve sans drapeau $l $nomTheme', (
          WidgetTester tester,
        ) async {
          await monterRouteur(
            tester,
            Routes.eleveSuivi,
            source: FausseSourceSession(sessionActive(AppRole.student)),
            taille: Size(largeur, 2000),
            themeMode: theme,
            surcharges: <Override>[
              portMaProgressionProvider.overrideWithValue(
                _Port(_reponse(dateLimite: true)..remove('eleve_voit_dates')),
              ),
              horsLigneProvider.overrideWith(
                (Ref ref) => Stream<bool>.value(false),
              ),
            ],
          );
          await tester.pump(const Duration(milliseconds: 600));
          debugPrint(
            'PNG ${await capturerVue(tester, 'eleve-sans-drapeau-$l-$nomTheme')}',
          );
        });
        testWidgets('enfant guide $l $nomTheme', (WidgetTester tester) async {
          await monterRouteur(
            tester,
            Routes.eleveSuivi,
            source: FausseSourceSession(
              sessionActive(AppRole.student, mode: InterfaceMode.enfant),
            ),
            interface: InterfaceMode.enfant,
            taille: Size(largeur, 2400),
            themeMode: theme,
            surcharges: <Override>[
              portMaProgressionProvider.overrideWithValue(
                _Port(_reponse(dateLimite: false)),
              ),
              horsLigneProvider.overrideWith(
                (Ref ref) => Stream<bool>.value(false),
              ),
            ],
          );
          await tester.pump(const Duration(milliseconds: 600));
          debugPrint('PNG ${await capturerVue(tester, 'enfant-$l-$nomTheme')}');
        });
        testWidgets('direction, feuille d une etape $l $nomTheme', (
          WidgetTester tester,
        ) async {
          await monterRouteur(
            tester,
            Routes.adminPedagogieProgrammes,
            source: FausseSourceSession(sessionActive(AppRole.admin)),
            taille: Size(largeur, 2000),
            themeMode: theme,
            surcharges: <Override>[
              serviceProgrammeProvider.overrideWithValue(const _Programme()),
              serviceContenuProgrammeProvider.overrideWithValue(
                const _Programme(),
              ),
            ],
          );
          await stabiliser(tester);
          await tester.tap(
            find.byWidgetPredicate(
              (Widget w) =>
                  w is MenuActions &&
                  (w.objet ?? '').contains('Lire avec les voyelles'),
            ),
          );
          await stabiliser(tester);
          await tester.tap(find.text(t.admin.programmes.contenu.ouvrir).last);
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturerVue(tester, 'direction-etape-$l-$nomTheme')}',
          );
        });
        testWidgets('tuteur $l $nomTheme', (WidgetTester tester) async {
          await monterHistorique(
            tester,
            depart: Routes.tuteurSuivi,
            taille: Size(largeur, 2400),
            mode: theme,
            autres: <Override>[
              portMaProgressionProvider.overrideWithValue(
                _Port(_reponse(dateLimite: true)),
              ),
            ],
          );
          await tester.pump(const Duration(milliseconds: 600));
          debugPrint('PNG ${await capturerVue(tester, 'tuteur-$l-$nomTheme')}');
        });
      }
    }
  });
}
