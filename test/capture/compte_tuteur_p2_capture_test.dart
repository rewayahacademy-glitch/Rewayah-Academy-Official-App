// Captures R3 de PROFILS P2 : « Mon compte » du tuteur sur le gabarit unique
// (PageCompte), sur le VRAI routeur : 390 et 1440, clair, sombre, francais,
// arabe, texte x1 et x2.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Mode d'emploi : `test/capture/LISEZ-MOI.md`. Donnees : fixtures isolees.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/identite/port_matricule.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/version/ligne_version.dart';
import 'package:rewayah_academy/features/demo/identite/matricule_demo.dart';

import '../features/compte/support_compte.dart';
import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

/// Le foyer A, avec une echeance a venir pour montrer la pastille reelle.
final List<EleveDuFoyer> _eleves = <EleveDuFoyer>[
  FoyersFictifs.a1,
  EleveDuFoyer(
    id: FoyersFictifs.a2.id,
    prenom: FoyersFictifs.a2.prenom,
    identifiantImmuable: FoyersFictifs.a2.identifiantImmuable,
    mode: FoyersFictifs.a2.mode,
    camera: FoyersFictifs.a2.camera,
    finAcces: DateTime.utc(2026, 10, 30, 12),
  ),
];

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
}) async {
  late GoRouter routeur;
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = _eleves;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        // Les donnees d'essai portent un matricule et une version, pour les
        // montrer (la capture ne les invente pas en production).
        portMatriculeProvider.overrideWithValue(
          const MatriculeDemo(<String, Matricule>{
            'p-guardian': Matricule(
              valeur: 'RA-26-4817',
              role: RoleAffiche.tuteur,
            ),
          }),
        ),
        versionAppliProvider.overrideWith(
          (Ref _) async => (version: '1.0.0', build: '423'),
        ),
        ...surchargesCompte(
          eleves: _eleves,
          acceptations: FauxServiceAcceptations(
            rendues: <Acceptation>[
              Acceptation(
                sorte: SorteContrat.conditionsTuteur,
                version: '2026-09',
                accepteeLe: DateTime(2026, 9, 12, 10),
              ),
            ],
          ),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
                builder: (BuildContext context, Widget? enfant) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: enfant!,
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
}

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  group('Capture : PROFILS P2, Compte du tuteur', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final double largeur in <double>[390, 1440]) {
      for (final (String nomMode, ThemeMode mode) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        for (final String langue in <String>['fr', 'ar']) {
          for (final double echelle in <double>[1, 2]) {
            final String nom =
                'compte_tuteur_${largeur.toInt()}_${nomMode}_${langue}_'
                'x${echelle.toInt()}';
            testWidgets(nom, (WidgetTester tester) async {
              if (langue == 'ar') {
                await tester.runAsync(
                  () => LocaleSettings.setLocale(AppLocale.ar),
                );
              }
              fixerVueCapture(
                tester,
                Size(largeur, echelle == 2 ? 3600 : 1900),
                1,
              );
              await _monter(
                tester,
                Routes.tuteurCompte,
                mode: mode,
                echelle: echelle,
              );
              debugPrint('PNG ${await capturer(tester, nom)}');
            });
          }
        }
      }
    }
  });
}
