// Captures de recette du Foyer (lot B, sous-paquet 1), sur le VRAI routeur :
// 390x844 et 1440x900, clair et sombre, les etats, l'ecran « Creer mon
// profil eleve », et les planches maquette | rendu.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Planches :
// CAPTURE_MAQUETTE_FOYER (ancienne capture « Foyer Member », contenu),
// CAPTURE_MAQUETTE_COMPTE_MOBILE et CAPTURE_MAQUETTE_COMPTE_BUREAU (high-fi
// « Mon compte », reference de rendu des lignes groupees, manifeste section
// 2). Donnees : fixtures de test uniquement.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';

final String? _maquetteFoyer = Platform.environment['CAPTURE_MAQUETTE_FOYER'];
final String? _maquetteCompteMobile =
    Platform.environment['CAPTURE_MAQUETTE_COMPTE_MOBILE'];
final String? _maquetteCompteBureau =
    Platform.environment['CAPTURE_MAQUETTE_COMPTE_BUREAU'];

final DateTime _maintenant = DateTime(2026, 9, 24, 12);

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Trois eleves fictifs : sans echeance, echeance a venir, echeance passee.
final List<EleveDuFoyer> _eleves = <EleveDuFoyer>[
  const EleveDuFoyer(
    id: 'foyer-a-eleve-1',
    prenom: 'Eleve A1',
    identifiantImmuable: 'STUD-FA-000001',
    mode: InterfaceMode.enfant,
    camera: CameraPolicy.forbidden,
  ),
  EleveDuFoyer(
    id: 'foyer-a-eleve-2',
    prenom: 'Eleve A2',
    identifiantImmuable: 'STUD-FA-000002',
    mode: InterfaceMode.standard,
    camera: CameraPolicy.allowed,
    finAcces: DateTime(2026, 10, 30, 12),
  ),
  EleveDuFoyer(
    id: 'foyer-a-eleve-3',
    prenom: 'Eleve A3',
    identifiantImmuable: 'STUD-FA-000003',
    mode: InterfaceMode.standard,
    camera: CameraPolicy.forbidden,
    finAcces: DateTime(2026, 9, 1, 12),
  ),
];

/// Les classes fictives, telles qu'un port branche les rendrait
/// (simulation ; en production le port est indisponible).
final FauxClassesFoyer _classes = FauxClassesFoyer(
  classes: <ClasseFoyer>[
    ClasseFoyer(eleveId: 'foyer-a-eleve-1', classe: classeFictive()),
    ClasseFoyer(
      eleveId: 'foyer-a-eleve-2',
      classe: classeFictive(groupeId: 'classe-b', libelle: 'Classe fictive B'),
    ),
  ],
);

class _Appairage extends FauxServiceAppairage {
  bool echoue = false;
  bool attend = false;

  @override
  Future<List<EleveDuFoyer>> eleves() async {
    if (attend) {
      await Completer<void>().future;
    }
    if (echoue) {
      throw Exception('lecture refusee');
    }
    return elevesRendus;
  }
}

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
  _Appairage? appairage,
  bool avecClasses = true,
  bool horsLigne = false,
}) async {
  late GoRouter routeur;
  final _Appairage service =
      appairage ?? (_Appairage()..elevesRendus = _eleves);
  await tester.pumpWidget(
    // Un conteneur neuf a chaque montage : aucun etat ni cache d un montage
    // precedent ne passe dans la capture suivante.
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: service,
        ),
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        if (avecClasses) portClassesFoyerProvider.overrideWithValue(_classes),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
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

Future<(int, int)> _taillePx(WidgetTester tester, String chemin) async {
  late int l;
  late int h;
  await tester.runAsync(() async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      await File(chemin).readAsBytes(),
    );
    final ui.Image image = (await codec.getNextFrame()).image;
    l = image.width;
    h = image.height;
    image.dispose();
  });
  return (l, h);
}

Future<void> _planche(
  WidgetTester tester, {
  required String nom,
  required String maquette,
  required double largeurLogique,
  EdgeInsets zoneSure = EdgeInsets.zero,
}) async {
  final (int l, int h) = await _taillePx(tester, maquette);
  fixerVueMaquette(
    tester,
    largeurPx: l,
    hauteurPx: h,
    largeurLogique: largeurLogique,
    zoneSure: zoneSure,
  );
  await _monter(tester, Routes.tuteurFoyer);
  debugPrint('PNG ${await capturerEtComparer(tester, nom, maquette)}');
}

void main() {
  group('Capture : Foyer', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('390x844 @3, contenu, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(tester, Routes.tuteurFoyer, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'foyer_contenu_390x844@3_${mode.name}')}',
        );
      });

      testWidgets('1440x900 @1, contenu, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monter(tester, Routes.tuteurFoyer, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'foyer_contenu_1440x900@1_${mode.name}')}',
        );
      });

      testWidgets('1024x768 @1, contenu, rail, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1024, 768), 1);
        await _monter(tester, Routes.tuteurFoyer, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'foyer_contenu_1024x768@1_${mode.name}')}',
        );
      });

      testWidgets('390x844 @3, classes indisponibles (production), '
          '${mode.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(
          tester,
          Routes.tuteurFoyer,
          mode: mode,
          avecClasses: false,
        );
        debugPrint(
          'PNG ${await capturer(tester, 'foyer_classes_indisponibles_390x844@3_${mode.name}')}',
        );
      });

      for (final (String nom, Size taille, double densite) format
          in <(String, Size, double)>[
            ('390x844@3', const Size(390, 844), 3),
            ('1440x900@1', const Size(1440, 900), 1),
          ]) {
        testWidgets('${format.$1}, etats, ${mode.name}', (
          WidgetTester tester,
        ) async {
          final EdgeInsets zone = format.$3 == 3 ? _zoneSure : EdgeInsets.zero;
          fixerVueCapture(tester, format.$2, format.$3, zoneSure: zone);
          final Map<String, _Appairage Function()> etats =
              <String, _Appairage Function()>{
                'vide': _Appairage.new,
                'erreur': () => _Appairage()..echoue = true,
                'chargement': () => _Appairage()..attend = true,
              };
          for (final MapEntry<String, _Appairage Function()> e
              in etats.entries) {
            await _monter(
              tester,
              Routes.tuteurFoyer,
              mode: mode,
              appairage: e.value(),
            );
            debugPrint(
              'PNG ${await capturer(tester, 'foyer_${e.key}_${format.$1}_${mode.name}')}',
            );
          }
          await _monter(
            tester,
            Routes.tuteurFoyer,
            mode: mode,
            appairage: _Appairage()..echoue = true,
            horsLigne: true,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'foyer_hors_ligne_${format.$1}_${mode.name}')}',
          );
          await _monter(tester, Routes.tuteurAjouterPourMoi, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'foyer_creer_mon_profil_${format.$1}_${mode.name}')}',
          );
        });
      }
    }

    testWidgets(
      'planche : Foyer mobile contre l ancienne capture (contenu)',
      skip: _maquetteFoyer == null,
      (WidgetTester tester) async {
        await _planche(
          tester,
          nom: 'foyer_mobile_contre_ancienne_capture',
          maquette: _maquetteFoyer!,
          largeurLogique: 390,
          zoneSure: _zoneSure,
        );
      },
    );

    testWidgets(
      'planche : Foyer mobile contre Mon compte mobile (rendu des lignes)',
      skip: _maquetteCompteMobile == null,
      (WidgetTester tester) async {
        await _planche(
          tester,
          nom: 'foyer_mobile_contre_compte_mobile',
          maquette: _maquetteCompteMobile!,
          largeurLogique: 390,
          zoneSure: _zoneSure,
        );
      },
    );

    testWidgets(
      'planche : Foyer bureau contre Mon compte bureau (rendu, colonnes)',
      skip: _maquetteCompteBureau == null,
      (WidgetTester tester) async {
        await _planche(
          tester,
          nom: 'foyer_bureau_contre_compte_bureau',
          maquette: _maquetteCompteBureau!,
          largeurLogique: 1440,
        );
      },
    );
  });
}
