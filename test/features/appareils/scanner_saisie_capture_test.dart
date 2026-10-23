// Captures de recette du scanner et de la saisie du code (lot D, sous-paquet
// 2), sur le VRAI routeur : 390x844 et 1440x900, clair et sombre, chaque etat
// utile, et deux planches contre les maquettes approuvees les plus proches
// (manifeste section 2 : scanner = plein cadre sombre de la salle M3, saisie
// = champ E3 de l'admission). Aucun de ces deux ecrans n'a de maquette
// propre.
//
// Saute sans CAPTURE_DIR. Les planches demandent en plus CAPTURE_MAQUETTE_M3
// (panneau M3 decoupe dans `tuteur observation mobile light.png`) et
// CAPTURE_MAQUETTE_E3 (panneau E3 decoupe dans `onboarding mobile 1.png`).
// La camera n'existe pas sous `flutter test` : le viseur montre son fond et
// son carre de visee, sans image. Mode d'emploi : `test/capture/LISEZ-MOI.md`.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/lecteur_qr.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/eleve_connexion/saisie_code_page.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';
import 'faux_lecteur_qr.dart';

final String? _maquetteM3 = Platform.environment['CAPTURE_MAQUETTE_M3'];
final String? _maquetteE3 = Platform.environment['CAPTURE_MAQUETTE_E3'];

/// Un etat a capturer.
typedef _Etat = ({
  String nom,
  String route,
  FauxLecteurQr Function() lecteur,
  void Function(FauxServiceEnfantPilote) regler,
  bool horsLigne,
  Future<void> Function(WidgetTester, FauxLecteurQr?)? geste,
});

void _rien(FauxServiceEnfantPilote _) {}

FauxLecteurQr _pret() => FauxLecteurQr();

FauxLecteurQr _camera(EtatCamera e) => FauxLecteurQr(defaut: e);

Future<void> _taperCode(WidgetTester tester, FauxLecteurQr? _) async {
  await tester.enterText(find.byKey(SaisieCodePage.champKey), 'AB23CD');
  await stabiliser(tester);
}

Future<void> _envoyerCode(WidgetTester tester, FauxLecteurQr? l) async {
  await _taperCode(tester, l);
  await tester.tap(
    find.widgetWithText(ActionPrincipale, t.eleveConnexion.saisie.valider),
  );
  await stabiliser(tester);
}

Future<void> _lire(WidgetTester tester, FauxLecteurQr? l, String brut) async {
  l!.lire(brut);
  await stabiliser(tester);
}

final List<_Etat> _etats = <_Etat>[
  // Scanner.
  (
    nom: 'scanner_lecture',
    route: Routes.connexionEleveScanner,
    lecteur: _pret,
    regler: _rien,
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'scanner_demarrage',
    route: Routes.connexionEleveScanner,
    lecteur: () => FauxLecteurQr()..attente = Completer<void>(),
    regler: _rien,
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'scanner_contenu_invalide',
    route: Routes.connexionEleveScanner,
    lecteur: _pret,
    regler: _rien,
    horsLigne: false,
    geste: (WidgetTester t, FauxLecteurQr? l) =>
        _lire(t, l, 'https://exemple.test'),
  ),
  (
    nom: 'scanner_verification',
    route: Routes.connexionEleveScanner,
    lecteur: _pret,
    regler: (FauxServiceEnfantPilote s) => s.attente = Completer<void>(),
    horsLigne: false,
    geste: (WidgetTester t, FauxLecteurQr? l) => _lire(t, l, 'AB23CD'),
  ),
  (
    nom: 'scanner_refus_expire',
    route: Routes.connexionEleveScanner,
    lecteur: _pret,
    regler: (FauxServiceEnfantPilote s) => s.refus = MotifRefusAppairage.expire,
    horsLigne: false,
    geste: (WidgetTester t, FauxLecteurQr? l) => _lire(t, l, 'AB23CD'),
  ),
  (
    nom: 'scanner_refus_hors_ligne',
    route: Routes.connexionEleveScanner,
    lecteur: _pret,
    regler: (FauxServiceEnfantPilote s) =>
        s.refus = MotifRefusAppairage.horsLigne,
    horsLigne: true,
    geste: (WidgetTester t, FauxLecteurQr? l) => _lire(t, l, 'AB23CD'),
  ),
  (
    nom: 'scanner_hors_ligne',
    route: Routes.connexionEleveScanner,
    lecteur: _pret,
    regler: _rien,
    horsLigne: true,
    geste: null,
  ),
  for (final EtatCamera e in <EtatCamera>[
    EtatCamera.refusee,
    EtatCamera.refuseeDurablement,
    EtatCamera.occupee,
    EtatCamera.absente,
    EtatCamera.nonSupportee,
    EtatCamera.erreur,
  ])
    (
      nom: 'scanner_camera_${e.name}',
      route: Routes.connexionEleveScanner,
      lecteur: () => _camera(e),
      regler: _rien,
      horsLigne: false,
      geste: null,
    ),
  // Saisie du code.
  (
    nom: 'saisie_vide',
    route: Routes.connexionEleveCode,
    lecteur: _pret,
    regler: _rien,
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'saisie_code',
    route: Routes.connexionEleveCode,
    lecteur: _pret,
    regler: _rien,
    horsLigne: false,
    geste: _taperCode,
  ),
  (
    nom: 'saisie_verification',
    route: Routes.connexionEleveCode,
    lecteur: _pret,
    regler: (FauxServiceEnfantPilote s) => s.attente = Completer<void>(),
    horsLigne: false,
    geste: _envoyerCode,
  ),
  (
    nom: 'saisie_refus_inconnu',
    route: Routes.connexionEleveCode,
    lecteur: _pret,
    regler: (FauxServiceEnfantPilote s) =>
        s.refus = MotifRefusAppairage.inconnu,
    horsLigne: false,
    geste: _envoyerCode,
  ),
  (
    nom: 'saisie_hors_ligne',
    route: Routes.connexionEleveCode,
    lecteur: _pret,
    regler: _rien,
    horsLigne: true,
    geste: _taperCode,
  ),
];

_Etat _etat(String nom) => _etats.firstWhere((_Etat e) => e.nom == nom);

Future<void> _monter(
  WidgetTester tester,
  _Etat etat, {
  ThemeMode mode = ThemeMode.light,
}) async {
  final FauxServiceEnfantPilote service = FauxServiceEnfantPilote();
  etat.regler(service);
  FauxLecteurQr? lecteur;
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession()),
        serviceEnfantProvider.overrideWithValue(service),
        stockageSecuriseProvider.overrideWithValue(FauxStockageSecurise()),
        profilsLocauxProvider.overrideWithValue(FauxProfilsLocaux()),
        lecteurQrDisponibleProvider.overrideWithValue(true),
        fabriqueLecteurQrProvider.overrideWithValue(
          () => lecteur = etat.lecteur(),
        ),
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
  routeur.go(etat.route);
  await stabiliser(tester);
  final Future<void> Function(WidgetTester, FauxLecteurQr?)? geste = etat.geste;
  if (geste != null) {
    await geste(tester, lecteur);
  }
  // Le curseur clignotant du champ ne doit pas changer la capture.
  FocusManager.instance.primaryFocus?.unfocus();
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

void main() {
  group('Capture : scanner et saisie du code', skip: sautSansCapture, () {
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
            'PNG ${await capturer(tester, '${etat.nom}_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('1440x900 @1, ${etat.nom}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monter(tester, etat, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, '${etat.nom}_1440x900@1_${mode.name}')}',
          );
        });
      }
    }

    testWidgets(
      'planche : scanner contre le plein cadre sombre M3',
      skip: _maquetteM3 == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteM3!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
        );
        await _monter(tester, _etat('scanner_lecture'));
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'scanner_lecture_contre_M3', _maquetteM3!)}',
        );
      },
    );

    testWidgets(
      'planche : saisie du code contre le champ E3',
      skip: _maquetteE3 == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteE3!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
        );
        await _monter(tester, _etat('saisie_code'), mode: ThemeMode.dark);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'saisie_code_contre_E3', _maquetteE3!)}',
        );
      },
    );
  });
}
