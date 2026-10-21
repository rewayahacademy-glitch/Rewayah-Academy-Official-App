// Captures de recette du lot D, sous-paquet 3 (appareils du foyer, appareils
// d'un profil eleve, appareil partage : choix du profil et code personnel),
// sur le VRAI routeur : 390x844 et 1440x900, clair et sombre, chaque etat
// utile ; planches maquette | rendu contre les references du manifeste
// (section 2) : « Profil » #33 et « Foyer Member » #30 (contenu), cartes
// « genre » #11 et champ E3 #14.
//
// Saute sans CAPTURE_DIR. Planches : CAPTURE_MAQUETTE_PROFIL,
// CAPTURE_MAQUETTE_FOYER, CAPTURE_MAQUETTE_GENRE, CAPTURE_MAQUETTE_E3.
// Mode d'emploi : `test/capture/LISEZ-MOI.md`.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/code_local.dart';
import 'package:rewayah_academy/core/appairage/lecteur_qr.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/pin_pad.dart';
import 'package:rewayah_academy/features/appareils/liste_appareils_eleve.dart';
import 'package:rewayah_academy/features/eleve_connexion/eleve_connexion_page.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';
import 'faux_appareils.dart';

final String? _maquetteProfil = Platform.environment['CAPTURE_MAQUETTE_PROFIL'];
final String? _maquetteFoyer = Platform.environment['CAPTURE_MAQUETTE_FOYER'];
final String? _maquetteGenre = Platform.environment['CAPTURE_MAQUETTE_GENRE'];
final String? _maquetteE3 = Platform.environment['CAPTURE_MAQUETTE_E3'];

FauxAppairagePilote _foyer() => FauxAppairagePilote()
  ..elevesRendus = <EleveDuFoyer>[
    eleveDeTest(),
    eleveDeTest(id: 'e2', prenom: 'Yusuf'),
    eleveDeTest(id: 'e3', prenom: 'Salam'),
  ]
  ..appareilsRendus = <AppareilAppaire>[
    appareilDeTest(
      appaireA: DateTime(2026, 9, 1, 10),
      derniereUtilisation: DateTime(2026, 9, 18, 14, 20),
    ),
    appareilDeTest(
      id: 'd2',
      plateforme: 'web',
      appaireA: DateTime(2026, 9, 20, 9, 5),
    ),
    appareilDeTest(
      id: 'd3',
      profilId: 'e2',
      plateforme: 'ios',
      appaireA: DateTime(2026, 9, 5, 18),
      derniereUtilisation: DateTime(2026, 9, 21, 17, 45),
    ),
  ];

/// Un etat tuteur : faux, adresse, reseau, geste final.
typedef _EtatTuteur = ({
  String nom,
  String adresse,
  FauxAppairagePilote Function() service,
  bool horsLigne,
  Future<void> Function(WidgetTester tester)? geste,
});

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await stabiliser(tester);
}

final List<_EtatTuteur> _etatsTuteur = <_EtatTuteur>[
  (
    nom: 'foyer_contenu',
    adresse: Routes.tuteurFoyerAppareils,
    service: _foyer,
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'foyer_vide',
    adresse: Routes.tuteurFoyerAppareils,
    service: FauxAppairagePilote.new,
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'foyer_chargement',
    adresse: Routes.tuteurFoyerAppareils,
    service: () => _foyer()..attenteLecture = Completer<void>(),
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'foyer_erreur',
    adresse: Routes.tuteurFoyerAppareils,
    service: () => _foyer()..erreurLecture = StateError('panne'),
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'foyer_hors_ligne',
    adresse: Routes.tuteurFoyerAppareils,
    service: () => _foyer()..attenteLecture = Completer<void>(),
    horsLigne: true,
    geste: null,
  ),
  (
    nom: 'eleve_contenu',
    adresse: Routes.ficheEleveSousPage('e1', 'appareils'),
    service: _foyer,
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'eleve_vide',
    adresse: Routes.ficheEleveSousPage('e3', 'appareils'),
    service: _foyer,
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'eleve_chargement',
    adresse: Routes.ficheEleveSousPage('e1', 'appareils'),
    service: () => _foyer()..attenteLecture = Completer<void>(),
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'eleve_erreur',
    adresse: Routes.ficheEleveSousPage('e1', 'appareils'),
    service: () => _foyer()..erreurLecture = StateError('panne'),
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'eleve_hors_ligne',
    adresse: Routes.ficheEleveSousPage('e1', 'appareils'),
    service: _foyer,
    horsLigne: true,
    geste: null,
  ),
  (
    nom: 'eleve_introuvable',
    adresse: Routes.ficheEleveSousPage('inconnu', 'appareils'),
    service: _foyer,
    horsLigne: false,
    geste: null,
  ),
  (
    nom: 'eleve_confirmation_retrait',
    adresse: Routes.ficheEleveSousPage('e1', 'appareils'),
    service: _foyer,
    horsLigne: false,
    geste: (WidgetTester tester) =>
        _taper(tester, find.byKey(ListeAppareilsEleve.retirerKey('d1'))),
  ),
  (
    nom: 'eleve_retire',
    adresse: Routes.ficheEleveSousPage('e1', 'appareils'),
    service: _foyer,
    horsLigne: false,
    geste: (WidgetTester tester) async {
      await _taper(tester, find.byKey(ListeAppareilsEleve.retirerKey('d1')));
      await _taper(tester, find.text(t.appareils.retrait.confirmer));
    },
  ),
  (
    nom: 'eleve_retrait_echec',
    adresse: Routes.ficheEleveSousPage('e1', 'appareils'),
    service: () => _foyer()..erreurRetrait = StateError('refus'),
    horsLigne: false,
    geste: (WidgetTester tester) async {
      await _taper(tester, find.byKey(ListeAppareilsEleve.retirerKey('d1')));
      await _taper(tester, find.text(t.appareils.retrait.confirmer));
    },
  ),
];

Widget _app(
  List<Override> surcharges,
  ThemeMode mode,
  void Function(GoRouter) garder,
) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: RepaintBoundary(
      key: cadreCapture,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          final GoRouter routeur = ref.read(routeurProvider);
          garder(routeur);
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
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
);

Future<void> _monterTuteur(
  WidgetTester tester,
  _EtatTuteur etat, {
  ThemeMode mode = ThemeMode.light,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    _app(
      <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: etat.service(),
        ),
        if (etat.horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
      mode,
      (GoRouter r) => routeur = r,
    ),
  );
  await stabiliser(tester);
  routeur.go(etat.adresse);
  await stabiliser(tester);
  final Future<void> Function(WidgetTester)? geste = etat.geste;
  if (geste != null) {
    await geste(tester);
  }
}

/// Un etat de l'appareil eleve : ouverture pilotee, profil touche, code
/// compose.
typedef _EtatEleve = ({
  String nom,
  Object? refus,
  bool sansCode,
  String? profil,
  List<String> codes,
});

final List<_EtatEleve> _etatsEleve = <_EtatEleve>[
  (
    nom: 'appareil_choix',
    refus: null,
    sansCode: false,
    profil: null,
    codes: <String>[],
  ),
  (
    nom: 'appareil_pin',
    refus: null,
    sansCode: false,
    profil: 'e1',
    codes: <String>[],
  ),
  (
    nom: 'appareil_pin_faux',
    refus: null,
    sansCode: false,
    profil: 'e1',
    codes: <String>['0000'],
  ),
  (
    nom: 'appareil_creation',
    refus: null,
    sansCode: true,
    profil: 'e1',
    codes: <String>[],
  ),
  (
    nom: 'appareil_codes_differents',
    refus: null,
    sansCode: true,
    profil: 'e1',
    codes: <String>['1111', '2222'],
  ),
  (
    nom: 'appareil_ouverture',
    refus: null,
    sansCode: false,
    profil: 'e1',
    codes: <String>['1357'],
  ),
  (
    nom: 'appareil_hors_ligne',
    refus: const AppairageRefuse(MotifRefusAppairage.horsLigne),
    sansCode: false,
    profil: 'e1',
    codes: <String>['1357'],
  ),
  (
    nom: 'appareil_retire',
    refus: const AppairageRefuse(MotifRefusAppairage.revoque),
    sansCode: false,
    profil: 'e1',
    codes: <String>['1357'],
  ),
];

Future<void> _monterEleve(
  WidgetTester tester,
  _EtatEleve etat, {
  ThemeMode mode = ThemeMode.light,
  bool unSeul = false,
}) async {
  final FauxStockageSecurise coffre = FauxStockageSecurise()
    ..jetons['e1'] = 'jeton-e1'
    ..jetons['e2'] = 'jeton-e2';
  if (!etat.sansCode) {
    coffre.empreintes['e1'] = CodeLocal.sceller('1357');
  }
  final FauxProfilsLocaux profils = FauxProfilsLocaux()
    ..profils = <ProfilLocal>[
      const ProfilLocal(id: 'e1', prenom: 'Amina', identifiantImmuable: ''),
      if (!unSeul)
        const ProfilLocal(id: 'e2', prenom: 'Yusuf', identifiantImmuable: ''),
    ];
  late GoRouter routeur;
  await tester.pumpWidget(
    _app(
      <Override>[
        ...surchargesRouteur(FausseSourceSession()),
        serviceEnfantProvider.overrideWithValue(
          FauxEnfantOuverture()..refusOuverture = etat.refus,
        ),
        stockageSecuriseProvider.overrideWithValue(coffre),
        profilsLocauxProvider.overrideWithValue(profils),
        lecteurQrDisponibleProvider.overrideWithValue(false),
      ],
      mode,
      (GoRouter r) => routeur = r,
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.connexionEleve);
  await stabiliser(tester);
  final String? profil = etat.profil;
  if (profil != null) {
    await _taper(tester, find.byKey(EleveConnexionPage.carteKey(profil)));
  }
  for (final String code in etat.codes) {
    for (final String chiffre in code.split('')) {
      await tester.tap(
        find.descendant(of: find.byType(PinPad), matching: find.text(chiffre)),
      );
      await tester.pump();
    }
    await stabiliser(tester);
  }
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

Future<void> _vueMaquette(WidgetTester tester, String chemin) async {
  final (int l, int h) = await _taillePx(tester, chemin);
  fixerVueMaquette(tester, largeurPx: l, hauteurPx: h, largeurLogique: 390);
}

void main() {
  group('Capture : appareils et appareil partage', skip: sautSansCapture, () {
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
      for (final _EtatTuteur etat in _etatsTuteur) {
        testWidgets('390x844 @3, ${etat.nom}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _monterTuteur(tester, etat, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'appareils_${etat.nom}_390x844@3_${mode.name}')}',
          );
        });
        testWidgets('1440x900 @1, ${etat.nom}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monterTuteur(tester, etat, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'appareils_${etat.nom}_1440x900@1_${mode.name}')}',
          );
        });
      }
      for (final _EtatEleve etat in _etatsEleve) {
        testWidgets('390x844 @3, ${etat.nom}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(
            tester,
            const Size(390, 844),
            3,
            zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
          );
          await _monterEleve(tester, etat, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, '${etat.nom}_390x844@3_${mode.name}')}',
          );
        });
        testWidgets('1440x900 @1, ${etat.nom}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monterEleve(tester, etat, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, '${etat.nom}_1440x900@1_${mode.name}')}',
          );
        });
      }
      testWidgets('390x844 @3, appareil_vide, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(
          tester,
          const Size(390, 844),
          3,
          zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
        );
        await _monterEleve(tester, _etatsEleve.last, mode: mode, unSeul: true);
        debugPrint(
          'PNG ${await capturer(tester, 'appareil_vide_390x844@3_${mode.name}')}',
        );
      });
      testWidgets('1440x900 @1, appareil_vide, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monterEleve(tester, _etatsEleve.last, mode: mode, unSeul: true);
        debugPrint(
          'PNG ${await capturer(tester, 'appareil_vide_1440x900@1_${mode.name}')}',
        );
      });
    }

    testWidgets(
      'planche : appareils d un eleve contre « Profil » (#33, sombre)',
      skip: _maquetteProfil == null,
      (WidgetTester tester) async {
        await _vueMaquette(tester, _maquetteProfil!);
        await _monterTuteur(tester, _etatsTuteur[5], mode: ThemeMode.dark);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'appareils_eleve_contre_profil', _maquetteProfil!)}',
        );
      },
    );

    testWidgets(
      'planche : appareils du foyer contre « Foyer Member » (#30, sombre)',
      skip: _maquetteFoyer == null,
      (WidgetTester tester) async {
        await _vueMaquette(tester, _maquetteFoyer!);
        await _monterTuteur(tester, _etatsTuteur[0], mode: ThemeMode.dark);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'appareils_foyer_contre_foyer_member', _maquetteFoyer!)}',
        );
      },
    );

    testWidgets(
      'planche : choix du profil contre les cartes « genre » (#11, sombre)',
      skip: _maquetteGenre == null,
      (WidgetTester tester) async {
        await _vueMaquette(tester, _maquetteGenre!);
        await _monterEleve(tester, _etatsEleve[0], mode: ThemeMode.dark);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'appareil_choix_contre_genre', _maquetteGenre!)}',
        );
      },
    );

    testWidgets(
      'planche : code personnel contre le champ E3 (#14, sombre)',
      skip: _maquetteE3 == null,
      (WidgetTester tester) async {
        await _vueMaquette(tester, _maquetteE3!);
        await _monterEleve(tester, _etatsEleve[1], mode: ThemeMode.dark);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'appareil_pin_contre_E3', _maquetteE3!)}',
        );
      },
    );
  });
}
