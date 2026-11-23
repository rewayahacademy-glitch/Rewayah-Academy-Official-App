// Captures de recette FICHE-ELEVE-DIRECTION (22/11/2026) : la fiche d'un eleve
// lue par la direction, a 390, 1280 et 1440, clair ; en arabe a 390 ; et
// l'etat vide (adulte sans classe). Donnees : fixtures synthetiques.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/fiche_eleve_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_personnes/fiche_eleve_direction_page.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

class _Port implements PortFicheEleveDirection {
  _Port(this._fiche);

  final FicheEleveDirection _fiche;

  @override
  Future<FicheEleveDirection?> lire(String eleveId) async => _fiche;

  @override
  Future<ResultatDemandePaiement> demanderPaiement(String eleveId) async =>
      ResultatDemandePaiement.demandee;
}

final FicheEleveDirection _enfant = FicheEleveDirection.depuisJson(
  <String, dynamic>{
    'identite': <String, dynamic>{
      'id': 'e1',
      'matricule': 'RA-26-4817',
      'prenom': 'Yasmine',
      'nom': 'Benali',
      'genre': 'female',
      'tranche': 'enfant',
      'langue_cours': 'francais',
      'langue_communication': 'fr',
      'etat_compte': 'active',
      'inscrit_le': '2026-11-10T09:00:00Z',
      'foyer_id': 'f1',
    },
    'tuteur': <String, dynamic>{
      'id': 't1',
      'matricule': 'RA-26-4001',
      'prenom': 'Amina',
      'nom': 'Benali',
      'courriel': 'amina@example.test',
      'telephone': '+33 6 00 00 00 00',
    },
    'admission': <String, dynamic>{
      'age': 9,
      'niveau': 'lecture_lente',
      'objectif': 'devenir_fluide',
      'langue': 'fr',
      'moments': <String>['soir'],
      'source': 'mosquee',
    },
    'classes': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'c1',
        'libelle': 'Classe des lettres',
        'fuseau': 'Asia/Riyadh',
        'depuis': '2026-11-12T09:00:00Z',
        'enseignant': <String, dynamic>{
          'id': 'p1',
          'prenom': 'Salma',
          'nom': 'Idrissi',
        },
        'creneaux': <Map<String, dynamic>>[
          <String, dynamic>{'jour': 3, 'heure': 20, 'duree': 45},
        ],
      },
    ],
    'presences': <String, dynamic>{
      'total': 3,
      'presents': 2,
      'retards': 1,
      'absents': 0,
      'excuses': 0,
      'dernieres': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 's1',
          'debut': '2026-11-18T17:00:00Z',
          'etat': 'presente',
        },
        <String, dynamic>{
          'id': 's2',
          'debut': '2026-11-11T17:00:00Z',
          'etat': 'en_retard',
        },
      ],
    },
    'progression': <String, dynamic>{
      'etape': 'Les bases',
      'ordre': 1,
      'depuis': '2026-11-12T09:00:00Z',
      'rythme': 'dans_les_temps',
    },
  },
)!;

final FicheEleveDirection _adulteSansClasse = FicheEleveDirection.depuisJson(
  <String, dynamic>{
    'identite': <String, dynamic>{
      'id': 'e2',
      'matricule': 'RA-26-5120',
      'prenom': 'Karim',
      'nom': 'Haddad',
      'genre': 'male',
      'tranche': 'adulte',
      'etat_compte': 'pending_kyc',
      'inscrit_le': '2026-11-21T09:00:00Z',
      'est_titulaire': true,
    },
    'tuteur': null,
    'admission': null,
    'classes': <Object>[],
    'presences': <String, dynamic>{'total': 0, 'dernieres': <Object>[]},
    'progression': null,
  },
)!;

Future<void> _monter(
  WidgetTester tester,
  FicheEleveDirection fiche,
  String nom, {
  required Size taille,
  required double densite,
  EdgeInsets zoneSure = EdgeInsets.zero,
  bool arabe = false,
}) async {
  fixerVueCapture(tester, taille, densite, zoneSure: zoneSure);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.adminPersonnesElevePour(fiche.id),
    routes: <RouteBase>[
      GoRoute(
        path: Routes.adminPersonnesEleve,
        builder: (BuildContext _, GoRouterState e) =>
            FicheEleveDirectionPage(eleveId: e.pathParameters['eleveId'] ?? ''),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portFicheEleveDirectionProvider.overrideWithValue(_Port(fiche)),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  await capturer(tester, nom);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  group('FICHE-ELEVE-DIRECTION', skip: sautSansCapture, () {
    const EdgeInsets zone = EdgeInsets.only(top: 47, bottom: 34);
    testWidgets('01 enfant, 390', (WidgetTester tester) async {
      await _monter(
        tester,
        _enfant,
        '01-fiche-enfant-390',
        taille: const Size(390, 844),
        densite: 2,
        zoneSure: zone,
      );
    });
    testWidgets('02 enfant, 1280', (WidgetTester tester) async {
      await _monter(
        tester,
        _enfant,
        '02-fiche-enfant-1280',
        taille: const Size(1280, 800),
        densite: 1,
      );
    });
    testWidgets('03 enfant, 1440', (WidgetTester tester) async {
      await _monter(
        tester,
        _enfant,
        '03-fiche-enfant-1440',
        taille: const Size(1440, 900),
        densite: 1,
      );
    });
    testWidgets('05 adulte sans classe, 1440', (WidgetTester tester) async {
      await _monter(
        tester,
        _adulteSansClasse,
        '05-fiche-adulte-vide-1440',
        taille: const Size(1440, 900),
        densite: 1,
      );
    });
  });

  group('FICHE-ELEVE-DIRECTION arabe', skip: sautSansCapture, () {
    const EdgeInsets zone = EdgeInsets.only(top: 47, bottom: 34);
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    testWidgets('04 arabe, 390', (WidgetTester tester) async {
      await _monter(
        tester,
        _enfant,
        '04-fiche-ar-390',
        taille: const Size(390, 844),
        densite: 2,
        zoneSure: zone,
        arabe: true,
      );
    });
  });
}
