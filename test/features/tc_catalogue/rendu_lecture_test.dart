// BIBLIO-LECTURE : le Coran ouvre le lecteur dedie quand la capacite est la ;
// PDF, texte structure et lecon s'ouvrent dans un nouvel onglet par un lien de
// lecture court, demande a chaque ouverture et jamais garde (contrat C-35).

import 'dart:async';

import 'package:flutter/foundation.dart' show DebugPrintCallback;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope, Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/ouvreur_onglet.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_telechargement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/tc_catalogue/detail_ressource_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart' show sessionActive;
import '../../support/aucun_mot_coupe.dart' as mc;
import '../../support/harnais.dart';
import '../../support/sens_et_echelle.dart';
import '../../teaching_core/b/faux/faux_ports_b.dart';

final Uri _lien = Uri.parse('https://stockage.exemple/lecture?sig=SECRET60S');

/// Un depot qui rend un lien de lecture et compte les demandes.
class _Liens extends ArtefactsLocaux {
  _Liens({this.comportement});

  /// Ce que fait la demande : `null` rend le lien ; sinon la fonction decide.
  final Future<Uri> Function()? comportement;
  int demandes = 0;

  @override
  bool get lienLectureServi => true;

  @override
  Future<Uri> lienLecture(String resourceVersionId) {
    demandes++;
    return comportement?.call() ?? Future<Uri>.value(_lien);
  }
}

List<Override> _surcharges({
  required TypeRessource type,
  ArtefactsLocaux? depot,
}) => <Override>[
  ...surchargesCatalogue(
    ressources: <LibraryResource>[
      ressource(
        id: 'r1',
        titre: 'Tableau des lettres',
        type: type,
        versionCourante: 'v1',
      ),
    ],
    versions: <String, List<ResourceVersion>>{
      'r1': <ResourceVersion>[version(id: 'v1', resourceId: 'r1')],
    },
    depotArtefactsPropre: depot,
  ),
];

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

Future<GoRouter> _monter(
  WidgetTester tester,
  List<Override> surcharges, {
  AppRole? role,
  bool autonome = false,
  Size taille = const Size(1200, 2400),
  double echelle = 1,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: '/tc/bibliotheque/r1',
    routes: <RouteBase>[
      GoRoute(
        path: '/tc/bibliotheque/r1',
        builder: (BuildContext _, GoRouterState _) =>
            const DetailRessourcePage(resourceId: 'r1'),
      ),
      GoRoute(
        path: Routes.eleveCoran,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('lecteur')),
      ),
    ],
  );
  await tester.pumpWidget(
    hoteRoutantAvecRouteur(
      routeur,
      <Override>[
        ...surcharges,
        if (role != null) ...<Override>[
          sourceSessionProvider.overrideWithValue(
            FausseSourceSession(sessionActive(role)),
          ),
          portCapaciteEleveProvider.overrideWithValue(
            PortCapaciteEleveFactice(
              autonomes: autonome
                  ? <String>{'p-${role.valeurSql}'}
                  : <String>{},
            ),
          ),
        ],
      ],
      echelle: echelle,
      direction: direction,
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

Widget hoteRoutantAvecRouteur(
  GoRouter routeur,
  List<Override> surcharges, {
  double echelle = 1,
  TextDirection? direction,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp.router(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      builder: sensEtEchelle(direction: direction, echelle: echelle),
      routerConfig: routeur,
    ),
  ),
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Coran : « Ouvrir le mushaf »', () {
    testWidgets('l\'eleve : le bouton ouvre le lecteur dedie', (tester) async {
      final GoRouter r = await _monter(
        tester,
        _surcharges(type: TypeRessource.quran),
        role: AppRole.student,
      );
      expect(find.text(t.tc.bibliotheque.detail.renduCoran), findsOneWidget);
      expect(_cle('rendu-ouvrir-mushaf'), findsOneWidget);
      await tester.tap(_cle('rendu-ouvrir-mushaf'));
      await tester.pumpAndSettle();
      expect(
        r.routerDelegate.currentConfiguration.matches.last.matchedLocation,
        Routes.eleveCoran,
      );
    });

    testWidgets('l\'adulte eleve autonome (compte tuteur) : le bouton aussi', (
      tester,
    ) async {
      await _monter(
        tester,
        _surcharges(type: TypeRessource.quran),
        role: AppRole.guardian,
        autonome: true,
      );
      expect(_cle('rendu-ouvrir-mushaf'), findsOneWidget);
    });

    for (final AppRole role in <AppRole>[
      AppRole.guardian,
      AppRole.teacher,
      AppRole.controller,
      AppRole.admin,
    ]) {
      testWidgets('${role.name} sans la capacite : la phrase seule, jamais un '
          'bouton grise', (tester) async {
        await _monter(
          tester,
          _surcharges(type: TypeRessource.quran),
          role: role,
        );
        expect(find.text(t.tc.bibliotheque.detail.renduCoran), findsOneWidget);
        expect(_cle('rendu-ouvrir-mushaf'), findsNothing);
        expect(find.text(t.tc.bibliotheque.rendu.ouvrirMushaf), findsNothing);
      });
    }

    testWidgets('session illisible : la phrase seule, sans exception', (
      tester,
    ) async {
      await _monter(tester, _surcharges(type: TypeRessource.quran));
      expect(_cle('rendu-ouvrir-mushaf'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  for (final TypeRessource type in <TypeRessource>[
    TypeRessource.pdf,
    TypeRessource.texteStructure,
    TypeRessource.lecon,
  ]) {
    group('${type.name} : « Ouvrir » dans un nouvel onglet', () {
      testWidgets('demande un lien court, l\'ouvre, ne le garde pas', (
        tester,
      ) async {
        final List<Uri> ouverts = <Uri>[];
        final List<String> journal = <String>[];
        final DebugPrintCallback ancien = debugPrint;
        debugPrint = (String? m, {int? wrapWidth}) => journal.add('$m');
        final _Liens depot = _Liens();
        await _monter(tester, <Override>[
          ..._surcharges(type: type, depot: depot),
          ouvreurOngletProvider.overrideWithValue((Uri u) {
            ouverts.add(u);
            return true;
          }),
        ]);
        expect(_cle('rendu-sans-lecteur'), findsNothing);
        await tester.tap(_cle('rendu-ouvrir'));
        await tester.pumpAndSettle();
        // Le journal de Flutter est rendu avant de conclure : le moteur de
        // test verifie qu'aucune variable de debogage n'a ete laissee.
        debugPrint = ancien;
        expect(ouverts, <Uri>[_lien]);
        expect(depot.demandes, 1);
        // Revenu au repos : le lien n'est nulle part a l'ecran ni dans le
        // journal, et un second geste en redemande un (jamais reutilise).
        expect(find.textContaining('SECRET60S'), findsNothing);
        expect(journal.where((String l) => l.contains('SECRET60S')), isEmpty);
        await tester.tap(_cle('rendu-ouvrir'));
        await tester.pumpAndSettle();
        expect(depot.demandes, 2);
      });

      testWidgets('chargement : le bouton porte l\'etat, un second geste est '
          'ignore', (tester) async {
        final Completer<Uri> attente = Completer<Uri>();
        final _Liens depot = _Liens(comportement: () => attente.future);
        final List<Uri> ouverts = <Uri>[];
        await _monter(tester, <Override>[
          ..._surcharges(type: type, depot: depot),
          ouvreurOngletProvider.overrideWithValue((Uri u) {
            ouverts.add(u);
            return true;
          }),
        ]);
        await tester.tap(_cle('rendu-ouvrir'));
        await tester.pump();
        await tester.tap(_cle('rendu-ouvrir'));
        await tester.pump();
        expect(depot.demandes, 1);
        attente.complete(_lien);
        await tester.pumpAndSettle();
        expect(ouverts, hasLength(1));
      });

      testWidgets('echec : la phrase et « Réessayer » relancent', (
        tester,
      ) async {
        int appels = 0;
        final _Liens depot = _Liens(
          comportement: () {
            appels++;
            return appels == 1
                ? Future<Uri>.error(StateError('reseau'))
                : Future<Uri>.value(_lien);
          },
        );
        final List<Uri> ouverts = <Uri>[];
        await _monter(tester, <Override>[
          ..._surcharges(type: type, depot: depot),
          ouvreurOngletProvider.overrideWithValue((Uri u) {
            ouverts.add(u);
            return true;
          }),
        ]);
        await tester.tap(_cle('rendu-ouvrir'));
        await tester.pumpAndSettle();
        expect(find.text(t.tc.bibliotheque.rendu.lienEchec), findsOneWidget);
        expect(find.text(t.tc.bibliotheque.rendu.reessayer), findsOneWidget);
        await tester.tap(_cle('rendu-ouvrir'));
        await tester.pumpAndSettle();
        expect(ouverts, <Uri>[_lien]);
        expect(find.text(t.tc.bibliotheque.rendu.lienEchec), findsNothing);
      });

      testWidgets('rien a ouvrir pour ce support : la phrase, aucun bouton', (
        tester,
      ) async {
        final _Liens depot = _Liens(
          comportement: () =>
              Future<Uri>.error(const EchecArtefact('aucun artefact')),
        );
        await _monter(tester, <Override>[
          ..._surcharges(type: type, depot: depot),
          ouvreurOngletProvider.overrideWithValue((Uri _) => true),
        ]);
        await tester.tap(_cle('rendu-ouvrir'));
        await tester.pumpAndSettle();
        expect(
          find.text(t.tc.bibliotheque.rendu.lienIndisponible),
          findsOneWidget,
        );
        expect(_cle('rendu-ouvrir'), findsNothing);
      });

      testWidgets('hors ligne : aucune demande ne part, la phrase le dit', (
        tester,
      ) async {
        final _Liens depot = _Liens();
        await _monter(tester, <Override>[
          ..._surcharges(type: type, depot: depot),
          ouvreurOngletProvider.overrideWithValue((Uri _) => true),
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        ]);
        await tester.tap(_cle('rendu-ouvrir'));
        await tester.pumpAndSettle();
        expect(depot.demandes, 0);
        expect(
          find.text(t.tc.bibliotheque.rendu.lienHorsLigne),
          findsOneWidget,
        );
        expect(find.text(t.tc.bibliotheque.rendu.reessayer), findsOneWidget);
      });

      testWidgets('onglet bloque par le navigateur : la phrase et la relance', (
        tester,
      ) async {
        await _monter(tester, <Override>[
          ..._surcharges(type: type, depot: _Liens()),
          ouvreurOngletProvider.overrideWithValue((Uri _) => false),
        ]);
        await tester.tap(_cle('rendu-ouvrir'));
        await tester.pumpAndSettle();
        expect(find.text(t.tc.bibliotheque.rendu.lienBloque), findsOneWidget);
        expect(_cle('rendu-ouvrir'), findsOneWidget);
      });

      testWidgets('port absent (production) : la phrase d\'aujourd\'hui, '
          'aucun bouton', (tester) async {
        await _monter(tester, <Override>[
          ..._surcharges(type: type),
          ouvreurOngletProvider.overrideWithValue((Uri _) => true),
        ]);
        expect(_cle('rendu-sans-lecteur'), findsOneWidget);
        expect(_cle('rendu-ouvrir'), findsNothing);
      });

      testWidgets('hors navigateur : la phrase, aucun bouton', (tester) async {
        await _monter(tester, <Override>[
          ..._surcharges(type: type, depot: _Liens()),
          ouvreurOngletProvider.overrideWithValue(null),
        ]);
        expect(_cle('rendu-sans-lecteur'), findsOneWidget);
        expect(_cle('rendu-ouvrir'), findsNothing);
      });
    });
  }

  Future<void> echec(
    WidgetTester tester,
    Size taille,
    double echelle, {
    TextDirection? direction,
  }) async {
    await _monter(
      tester,
      <Override>[
        ..._surcharges(
          type: TypeRessource.pdf,
          depot: _Liens(comportement: () => Future<Uri>.error(StateError('x'))),
        ),
        ouvreurOngletProvider.overrideWithValue((Uri _) => true),
      ],
      taille: taille,
      echelle: echelle,
      direction: direction,
    );
    await tester.tap(_cle('rendu-ouvrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      mc.motsCoupes(tester, _cle('rendu-lecture'), traitDUnionPermis: true),
      isEmpty,
    );
  }

  group('formats', () {
    testWidgets(
      '320 texte x2 : la phrase d\'echec ne coupe aucun mot',
      (tester) => echec(tester, const Size(320, 900), 2),
    );
    testWidgets(
      '390 : la phrase d\'echec ne coupe aucun mot',
      (tester) => echec(tester, const Size(390, 844), 1),
    );
  });

  group('arabe (a relire par un arabophone)', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    testWidgets(
      'RTL 320 texte x2 : aucun mot coupe',
      (tester) =>
          echec(tester, const Size(320, 900), 2, direction: TextDirection.rtl),
    );
  });
}
