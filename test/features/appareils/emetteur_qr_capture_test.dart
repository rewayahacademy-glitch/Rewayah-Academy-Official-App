// Captures de recette de l'emetteur QR (lot D, sous-paquet 1), sur le VRAI
// routeur : 390x844 et 1440x900, clair et sombre, chaque etat utile, et une
// planche contre l'ecran resultat M5 (maquette approuvee la plus proche,
// manifeste section 2 : l'emetteur n'a pas de maquette propre).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. La
// planche demande en plus CAPTURE_MAQUETTE_M5 (le panneau M5 decoupe dans
// `tuteur observation mobile light.png`). Mode d'emploi :
// `test/capture/LISEZ-MOI.md`.

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
import 'package:rewayah_academy/core/appairage/statut_code_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/appareils/appairage_page.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';
import 'faux_statut_code.dart';

final String? _maquetteM5 = Platform.environment['CAPTURE_MAQUETTE_M5'];

final DateTime _depart = DateTime(2026, 9, 24, 18);

const EleveDuFoyer _amina = EleveDuFoyer(
  id: 'e1',
  prenom: 'Amina',
  identifiantImmuable: 'STUDENT-AD-000001',
  mode: InterfaceMode.enfant,
  camera: CameraPolicy.forbidden,
);

/// Un etat a capturer : comment regler les faux, et ce qu'il faut attendre.
typedef _Etat = ({
  String nom,
  void Function(FauxServiceAppairage, FauxStatutCode) regler,
  bool scruter,
  bool horsLigne,
  bool attente,
});

final List<_Etat> _etats = <_Etat>[
  (
    nom: 'actif',
    regler: (_, _) {},
    scruter: false,
    horsLigne: false,
    attente: false,
  ),
  (
    nom: 'preparation',
    regler: (_, _) {},
    scruter: false,
    horsLigne: false,
    attente: true,
  ),
  (
    nom: 'hors_ligne',
    regler: (_, _) {},
    scruter: false,
    horsLigne: true,
    attente: false,
  ),
  (
    nom: 'confirme',
    regler: (FauxServiceAppairage _, FauxStatutCode s) =>
        s.statutRendu = StatutCode.consomme,
    scruter: true,
    horsLigne: false,
    attente: false,
  ),
  (
    nom: 'expire',
    regler: (FauxServiceAppairage a, FauxStatutCode _) =>
        a.code = CodeAppairage(
          code: 'AB23CD',
          expireA: _depart.subtract(const Duration(seconds: 1)),
        ),
    scruter: false,
    horsLigne: false,
    attente: false,
  ),
  (
    nom: 'remplace',
    regler: (FauxServiceAppairage _, FauxStatutCode s) =>
        s.statutRendu = StatutCode.remplace,
    scruter: true,
    horsLigne: false,
    attente: false,
  ),
  (
    nom: 'deja_actif',
    regler: (FauxServiceAppairage _, FauxStatutCode s) =>
        s.vivant = CodeVivant(expireA: _depart.add(const Duration(minutes: 7))),
    scruter: false,
    horsLigne: false,
    attente: false,
  ),
  (
    nom: 'plafond',
    regler: (FauxServiceAppairage a, FauxStatutCode _) =>
        a.erreurAJeter = StateError("plafond d'appareils atteint"),
    scruter: false,
    horsLigne: false,
    attente: false,
  ),
  (
    nom: 'erreur',
    regler: (FauxServiceAppairage a, FauxStatutCode _) =>
        a.erreurAJeter = StateError('panne'),
    scruter: false,
    horsLigne: false,
    attente: false,
  ),
];

_Etat _etat(String nom) => _etats.firstWhere((_Etat e) => e.nom == nom);

Future<void> _monter(
  WidgetTester tester,
  _Etat etat, {
  ThemeMode mode = ThemeMode.light,
}) async {
  final FauxServiceAppairage appairage =
      (etat.attente ? _AttenteSansFin() : FauxServiceAppairage())
        ..elevesRendus = <EleveDuFoyer>[_amina]
        ..code = CodeAppairage(
          code: 'AB23CD',
          expireA: _depart.add(const Duration(minutes: 10)),
        );
  final FauxStatutCode statut = FauxStatutCode();
  etat.regler(appairage, statut);
  final HorlogePilotee horloge = HorlogePilotee(_depart);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        portStatutCodeAppairageProvider.overrideWithValue(statut),
        horlogeEmetteurProvider.overrideWithValue(horloge.lire),
        // Hors ligne : le fait lu par tous les ecrans (bandeau compris).
        if (etat.horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
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
  routeur.go(Routes.appairerPour('e1'));
  await stabiliser(tester);
  if (etat.scruter) {
    await tester.pump(AppairagePage.intervalleScrutation);
    await stabiliser(tester);
  }
}

/// Une demande de code qui ne rend jamais la main : l etat de preparation.
class _AttenteSansFin extends FauxServiceAppairage {
  @override
  Future<CodeAppairage> creerCode(String eleveId) =>
      Completer<CodeAppairage>().future;
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

void main() {
  group('Capture : emetteur QR', skip: sautSansCapture, () {
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
      for (final _Etat etat in _etats) {
        testWidgets('390x844 @3, ${etat.nom}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _monter(tester, etat, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'emetteur_${etat.nom}_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('1440x900 @1, ${etat.nom}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monter(tester, etat, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'emetteur_${etat.nom}_1440x900@1_${mode.name}')}',
          );
        });
      }
    }

    testWidgets(
      'planche : association confirmee contre l ecran resultat M5',
      skip: _maquetteM5 == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteM5!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
        );
        await _monter(tester, _etat('confirme'));
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'emetteur_confirme_contre_M5', _maquetteM5!)}',
        );
      },
    );

    testWidgets(
      'planche : code actif contre l ecran resultat M5 (colonne centree)',
      skip: _maquetteM5 == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteM5!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
        );
        await _monter(tester, _etat('actif'));
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'emetteur_actif_contre_M5', _maquetteM5!)}',
        );
      },
    );
  });
}
