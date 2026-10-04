// Captures de recette du lot O, sous-paquet 2 (salle d'observation) :
// 390x844 et 1440x900, clair et sombre, tablette 1024x768, paysage 844x390,
// les etats, et les planches maquette V8 M4 (clair), M3 (sombre), D1 (bureau)
// | rendu.
//
// Saute sans CAPTURE_DIR (la CI ne l'execute jamais). Planches :
// CAPTURE_MAQUETTE_M4, CAPTURE_MAQUETTE_M3 (390 logiques) et
// CAPTURE_MAQUETTE_D1 (1280 logiques, echelle de la planche 02 relevee par V8).
// Donnees : doubles isoles de `test/teaching_core/g/faux` et
// `test/fixtures/tuteur`, jamais un service reel ; les « videos » sont des
// aplats de test, jamais une photo.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/tc_observation_ui/ouverture_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';
import 'package:rewayah_academy/features/tc_observation_ui/verification_prealable.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../e/faux/faux_classe.dart'
    show FauxMoteurClasse, FauxServiceVideoClasse, accesDe;
import 'faux/faux_observation.dart';
import 'support/hote_tc_g.dart';

final String? _maquetteM4 = Platform.environment['CAPTURE_MAQUETTE_M4'];
final String? _maquetteM3 = Platform.environment['CAPTURE_MAQUETTE_M3'];
final String? _maquetteD1 = Platform.environment['CAPTURE_MAQUETTE_D1'];

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

final String _porte = cheminObservation(
  's1',
  classeId: 'c1',
  eleveId: 'enfant-1',
);

/// Une « video » de test : un aplat nomme, jamais une image reelle.
Widget _videoDouble(Color couleur) => ColoredBox(
  color: couleur,
  child: const Center(
    child: Icon(Icons.person, size: 56, color: Color(0x66FFFFFF)),
  ),
);

ResultatEntreeObservation _entree({
  Duration restant = const Duration(seconds: 102),
  int utilisees = 1,
  int max = 2,
}) => ResultatEntreeObservation(
  autorise: true,
  visite: uneVisite(),
  budget: unBudget(
    restant: restant,
    visitesUtilisees: utilisees,
    visitesMax: max,
    total: const Duration(seconds: 240),
  ),
);

/// Monte la porte, geste de la classe et explication deja lue : la salle
/// s'ouvre directement (logigramme V7), comme pour un parent qui revient.
Future<FauxMoteurClasse> _monterSalle(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  ResultatEntreeObservation? reponse,
  bool participants = true,
  bool jetonRefuse = false,
  double echelleTexte = 1,
  bool sansImage = false,
  TextDirection? sens,
}) async {
  final FauxPortPolitique politique = FauxPortPolitique();
  addTearDown(politique.fermer);
  final FauxMoteurClasse moteur = FauxMoteurClasse();
  // TUILE-TUTEUR-1 : sans image, les vignettes prennent la tuile partagee.
  if (!sansImage) {
    moteur
      ..videos['prof-1'] = _videoDouble(const Color(0xFF6F6A86))
      ..videos['enfant-1'] = _videoDouble(const Color(0xFF8C84A8));
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesTcG(
        role: AppRole.guardian,
        visites: FauxPortVisite(reponse: reponse ?? _entree()),
        politique: politique,
        moteur: moteur,
        video: jetonRefuse
            ? FauxServiceVideoClasse(motifARefuser: MotifRefusSalle.acces)
            : FauxServiceVideoClasse(acces0: accesDe('guardian_observer')),
        stockage: StockagePreferencesMemoire(<String, String>{
          clefExplicationVue('p1'): 'oui',
        }),
        autres: <Override>[
          portClassesFoyerProvider.overrideWithValue(
            FauxClassesFoyer(
              classes: <ClasseFoyer>[
                ClasseFoyer(
                  eleveId: 'enfant-1',
                  classe: classeFictive(groupeId: 'c1'),
                ),
              ],
            ),
          ),
        ],
      ),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext contexte, Widget? enfant) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelleTexte)),
                child: sens == null
                    ? enfant!
                    : Directionality(textDirection: sens, child: enfant!),
              ),
              routerConfig: GoRouter(
                initialLocation: _porte,
                initialExtra: const DemandeEntreeObservation(),
                routes: <RouteBase>[
                  GoRoute(
                    path: '${Routes.tuteurClasses}/:classeId',
                    builder: (BuildContext _, GoRouterState _) =>
                        const Text('CLASSE'),
                  ),
                  ...routesTcG(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (participants) {
    moteur.publier(<ParticipantSalle>[
      const ParticipantSalle(
        identite: 'prof-1',
        nom: 'Amina',
        role: 'teacher',
        estLocal: false,
        micro: true,
        camera: true,
        parle: false,
        qualite: QualiteLien.bonne,
      ),
      const ParticipantSalle(
        identite: 'enfant-1',
        nom: 'Mariam',
        role: 'student',
        estLocal: false,
        micro: true,
        camera: true,
        parle: true,
        qualite: QualiteLien.bonne,
      ),
    ]);
  }
  await stabiliser(tester);
  return moteur;
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

Future<void> _capturer(WidgetTester tester, String nom) async =>
    debugPrint('PNG ${await capturer(tester, nom)}');

Future<void> _presser(WidgetTester tester, String texte) async {
  await tester.tap(find.text(texte));
  await stabiliser(tester);
}

void main() {
  group('Capture : salle d\'observation', skip: sautSansCapture, () {
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
      testWidgets('salle 390x844 @3, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monterSalle(tester, mode: mode);
        await _capturer(tester, 'o2_salle_390x844@3_${mode.name}');
      });

      testWidgets('salle 1440x900 @1, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monterSalle(tester, mode: mode);
        await _capturer(tester, 'o2_salle_1440x900@1_${mode.name}');
      });

      testWidgets('confirmation de sortie 390x844 @3, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monterSalle(tester, mode: mode);
        await _presser(tester, t.tc.observation.visite.quitter);
        await _capturer(tester, 'o2_quitter_390x844@3_${mode.name}');
      });
    }

    testWidgets('confirmation de sortie 1440x900 @1', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await _monterSalle(tester);
      await _presser(tester, t.tc.observation.visite.quitter);
      await _capturer(tester, 'o2_quitter_1440x900@1_light');
    });

    testWidgets('tablette 1024x768 @1', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1024, 768), 1);
      await _monterSalle(tester);
      await _capturer(tester, 'o2_salle_1024x768@1_light');
    });

    testWidgets('telephone en paysage 844x390 @3', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(844, 390), 3);
      await _monterSalle(tester);
      await _capturer(tester, 'o2_salle_844x390@3_paysage_light');
    });

    testWidgets('agrandi 390x844 @3', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monterSalle(tester);
      await _presser(tester, t.tc.observation.visite.agrandir);
      await _capturer(tester, 'o2_agrandi_390x844@3_light');
    });

    testWidgets('agrandi 1440x900 @1', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await _monterSalle(tester);
      await _presser(tester, t.tc.observation.visite.agrandir);
      await _capturer(tester, 'o2_agrandi_1440x900@1_light');
    });

    testWidgets('reconnexion 390x844 @3', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      final FauxMoteurClasse moteur = await _monterSalle(tester);
      moteur.poser(EtatSalle.reconnexion);
      await stabiliser(tester);
      await _capturer(tester, 'o2_reconnexion_390x844@3_light');
    });

    testWidgets('fin proche (20 s) 390x844 @3', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monterSalle(
        tester,
        reponse: _entree(restant: const Duration(seconds: 20)),
      );
      await _capturer(tester, 'o2_fin_proche_390x844@3_light');
    });

    testWidgets('derniere visite, aucune restante 390x844 @3', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monterSalle(tester, reponse: _entree(utilisees: 2));
      await _capturer(tester, 'o2_derniere_visite_390x844@3_light');
    });

    testWidgets('personne encore dans la salle 390x844 @3', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monterSalle(tester, participants: false);
      await _capturer(tester, 'o2_salle_vide_390x844@3_light');
    });

    // TUILE-TUTEUR-1 : vignettes sans image (cercle, nom centre dessous).
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('sans image 390x844 @3, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monterSalle(tester, mode: mode, sansImage: true);
        await _capturer(tester, 'o2_sans_image_390x844@3_${mode.name}');
      });
    }

    testWidgets('sans image 1440x900 @1', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await _monterSalle(tester, sansImage: true);
      await _capturer(tester, 'o2_sans_image_1440x900@1_light');
    });

    testWidgets('sans image, texte a 200 % 320x844 @2', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(320, 844), 2, zoneSure: _zoneSure);
      await _monterSalle(tester, sansImage: true, echelleTexte: 2);
      // TUILE-TUTEUR-1b : a 200 %, les vignettes sont sous le pli ; la
      // capture les amene a l'ecran, sinon elle ne prouve rien du lot.
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('vignette-enfant')),
      );
      await stabiliser(tester);
      await _capturer(tester, 'o2_sans_image_texte200_320x844@2_light');
    });

    // TUILE-TUTEUR-1b : droite a gauche.
    testWidgets('sans image 390x844 @3, rtl', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monterSalle(tester, sansImage: true, sens: TextDirection.rtl);
      await _capturer(tester, 'o2_sans_image_390x844@3_rtl_light');
    });

    // OBS-COUPE-1b : la barre sur les telephones etroits, texte a 100 %,
    // agrandi ou non, son recu ou interrompu.
    for (final (Size, double) vue in const <(Size, double)>[
      (Size(320, 844), 2),
      (Size(360, 800), 3),
      (Size(375, 812), 3),
    ]) {
      final String format =
          '${vue.$1.width.toInt()}x${vue.$1.height.toInt()}@${vue.$2.toInt()}';
      testWidgets('barre $format', (WidgetTester tester) async {
        fixerVueCapture(tester, vue.$1, vue.$2, zoneSure: _zoneSure);
        await _monterSalle(tester);
        await _capturer(tester, 'o2_salle_${format}_light');
      });

      testWidgets('barre reduire $format', (WidgetTester tester) async {
        fixerVueCapture(tester, vue.$1, vue.$2, zoneSure: _zoneSure);
        await _monterSalle(tester);
        await _presser(tester, t.tc.observation.visite.agrandir);
        await _capturer(tester, 'o2_agrandi_${format}_light');
      });

      testWidgets('barre son interrompu $format', (WidgetTester tester) async {
        fixerVueCapture(tester, vue.$1, vue.$2, zoneSure: _zoneSure);
        final FauxMoteurClasse moteur = await _monterSalle(tester);
        moteur.poser(EtatSalle.reconnexion);
        await stabiliser(tester);
        await _capturer(tester, 'o2_son_interrompu_${format}_light');
      });
    }

    testWidgets('video indisponible 390x844 @3', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monterSalle(tester, jetonRefuse: true, participants: false);
      await _capturer(tester, 'o2_video_indisponible_390x844@3_light');
    });

    testWidgets('texte a 200 % 390x844 @2', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 2, zoneSure: _zoneSure);
      await _monterSalle(tester, echelleTexte: 2);
      await _capturer(tester, 'o2_texte200_390x844@2_light');
    });

    // PAGESHELL-200-1 : barre entiere dans la zone sure au premier affichage.
    testWidgets('texte a 200 % 320x844 @2', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(320, 844), 2, zoneSure: _zoneSure);
      await _monterSalle(tester, echelleTexte: 2);
      await _capturer(tester, 'o2_texte200_320x844@2_light');
    });

    testWidgets('texte a 200 % 390x844 @2, rtl', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 2, zoneSure: _zoneSure);
      await _monterSalle(tester, echelleTexte: 2, sens: TextDirection.rtl);
      await _capturer(tester, 'o2_texte200_390x844@2_light_rtl');
    });

    testWidgets(
      'planche : salle mobile claire contre la maquette V8 M4',
      skip: _maquetteM4 == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteM4!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
          zoneSure: const EdgeInsets.only(top: 24),
        );
        await _monterSalle(tester);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'o2_salle_mobile_contre_maquette_M4', _maquetteM4!)}',
        );
      },
    );

    testWidgets(
      'planche : salle mobile sombre contre la maquette V8 M3',
      skip: _maquetteM3 == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteM3!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
          zoneSure: const EdgeInsets.only(top: 24),
        );
        await _monterSalle(tester, mode: ThemeMode.dark);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'o2_salle_mobile_sombre_contre_maquette_M3', _maquetteM3!)}',
        );
      },
    );

    testWidgets(
      'planche : salle bureau contre la maquette V8 D1',
      skip: _maquetteD1 == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteD1!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 1280,
        );
        await _monterSalle(tester);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'o2_salle_bureau_contre_maquette_D1', _maquetteD1!)}',
        );
      },
    );
  });
}
