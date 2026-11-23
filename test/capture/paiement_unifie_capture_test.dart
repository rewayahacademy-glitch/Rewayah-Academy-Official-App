// Captures de recette PAIEMENT-UNIFIE P5 (23/11/2026) : la section « Paiement »
// de la fiche d'un eleve lue par la direction, a 390, 1280 et 1440, en arabe,
// puis la feuille « Reporter ». Donnees : fixtures synthetiques.
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
import 'package:rewayah_academy/features/admin_personnes/section_paiement_fiche.dart';

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

FicheEleveDirection _fiche(Map<String, dynamic> paiement) =>
    FicheEleveDirection.depuisJson(<String, dynamic>{
      'identite': <String, dynamic>{
        'id': 'e1',
        'matricule': 'RA-26-4817',
        'prenom': 'Yasmine',
        'nom': 'Benali',
        'genre': 'female',
        'tranche': 'enfant',
        'langue_cours': 'francais',
        'etat_compte': 'active',
        'inscrit_le': '2026-11-10T09:00:00Z',
        'foyer_id': 'f1',
      },
      'tuteur': <String, dynamic>{
        'id': 't1',
        'matricule': 'RA-26-4001',
        'prenom': 'Amina',
        'nom': 'Benali',
      },
      'classes': <Object>[],
      'presences': <String, dynamic>{'total': 0, 'dernieres': <Object>[]},
      'paiement': paiement,
    })!;

final FicheEleveDirection _aPayer = _fiche(<String, dynamic>{
  'etat': 'a_payer',
  'deja_paye': false,
  'facture': <String, dynamic>{
    'mois': '2026-11-01',
    'total_mineur': 5500,
    'devise': 'USD',
    'statut': 'a_financer',
    'emise_le': '2026-11-20T10:00:00Z',
  },
});

final FicheEleveDirection _exonere = _fiche(<String, dynamic>{
  'etat': 'exonere',
  'deja_paye': false,
  'remise': <String, dynamic>{
    'nature': 'acces_offert',
    'pour_mille': 1000,
    'mois_fin': '2027-01-01',
  },
});

Future<void> _monter(
  WidgetTester tester,
  FicheEleveDirection fiche,
  String nom, {
  required Size taille,
  required double densite,
  EdgeInsets zoneSure = EdgeInsets.zero,
  bool ouvrirReporter = false,
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
  if (ouvrirReporter) {
    await tester.ensureVisible(
      find.byKey(SectionPaiementFiche.cleGeste('reporter')),
    );
    await tester.tap(find.byKey(SectionPaiementFiche.cleGeste('reporter')));
    await stabiliser(tester);
  }
  await capturer(tester, nom);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  group('PAIEMENT-UNIFIE P5', skip: sautSansCapture, () {
    const EdgeInsets zone = EdgeInsets.only(top: 47, bottom: 34);
    testWidgets('01 a payer, 390', (WidgetTester tester) async {
      await _monter(
        tester,
        _aPayer,
        '01-fiche-paiement-390',
        taille: const Size(390, 844),
        densite: 2,
        zoneSure: zone,
      );
    });
    testWidgets('02 a payer, 1280', (WidgetTester tester) async {
      await _monter(
        tester,
        _aPayer,
        '02-fiche-paiement-1280',
        taille: const Size(1280, 800),
        densite: 1,
      );
    });
    testWidgets('03 a payer, 1440', (WidgetTester tester) async {
      await _monter(
        tester,
        _aPayer,
        '03-fiche-paiement-1440',
        taille: const Size(1440, 900),
        densite: 1,
      );
    });
    testWidgets('04 exonere, 1440', (WidgetTester tester) async {
      await _monter(
        tester,
        _exonere,
        '04-fiche-exonere-1440',
        taille: const Size(1440, 900),
        densite: 1,
      );
    });
    testWidgets('05 feuille Reporter, 1440', (WidgetTester tester) async {
      await _monter(
        tester,
        _aPayer,
        '05-feuille-reporter-1440',
        taille: const Size(1440, 900),
        densite: 1,
        ouvrirReporter: true,
      );
    });
  });

  group('PAIEMENT-UNIFIE P5 arabe', skip: sautSansCapture, () {
    const EdgeInsets zone = EdgeInsets.only(top: 47, bottom: 34);
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    testWidgets('06 arabe, 390', (WidgetTester tester) async {
      await _monter(
        tester,
        _aPayer,
        '06-fiche-paiement-ar-390',
        taille: const Size(390, 844),
        densite: 2,
        zoneSure: zone,
      );
    });
  });
}
