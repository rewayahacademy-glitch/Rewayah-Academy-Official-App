// SOMBRE-SANS-ECLAIR (directeur, 11/11/2026) : « une fois le theme sombre
// active, chaque changement de page montre le clair quelques millisecondes ».
//
// Cause mesuree sur la version web compilee (captures du lot) : le theme
// choisi etait relu APRES la premiere image (lecture asynchrone du stockage),
// le controleur partant de « Systeme ». Systeme clair et choix « Sombre » :
// chaque chargement de page peignait ses premieres images en clair.
//
// Le cas que LG-FLASH ne couvrait pas : systeme CLAIR, preference SOMBRE.
// Ce test echoue sans le correctif : la premiere image suit le systeme.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/connexion/ordre_entree.dart'
    show clefCompteConnu;
import 'package:rewayah_academy/features/demo/racine_demonstrable.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart' show FausseSourceSession;
import '../teaching_core/a/faux/faux_groupes.dart' show PortHorlogeMuet;

const Key _cadre = ValueKey<String>('cadre-sombre');

/// Systeme clair, preference « Sombre » deja enregistree sur l'appareil, et
/// pour le compte de demonstration du tuteur (PREFERENCES-PAR-COMPTE : le
/// theme suit le compte qui se connecte).
List<Override> _sombreEnregistre() {
  final StockagePreferencesMemoire stockage = StockagePreferencesMemoire(
    <String, String>{
      clefPreferenceTheme: 'sombre',
      clefDuCompte(clefPreferenceTheme, 'demo-tuteur'): 'sombre',
    },
  );
  return <Override>[
    stockagePreferencesProvider.overrideWithValue(stockage),
    lecturePreferencesImmediateProvider.overrideWithValue(stockage),
    portHorlogeSeanceProvider.overrideWithValue(const PortHorlogeMuet()),
  ];
}

/// Le constat d'une frame : pixels transparents et luminance moyenne de la
/// zone de contenu (a droite de la colonne de navigation).
Future<({int transparents, double luminance})> _mesurer(
  WidgetTester tester,
) async {
  final RenderRepaintBoundary limite = tester.renderObject(find.byKey(_cadre));
  final ByteData octets = (await tester.runAsync<ByteData?>(() async {
    final ui.Image image = await limite.toImage();
    final ByteData? brut = await image.toByteData();
    image.dispose();
    return brut;
  }))!;
  const int largeur = 1280;
  int transparents = 0;
  double somme = 0;
  int n = 0;
  for (int y = 40; y < 800; y += 20) {
    for (int x = 300; x < largeur; x += 20) {
      final int i = (y * largeur + x) * 4;
      final int r = octets.getUint8(i);
      final int v = octets.getUint8(i + 1);
      final int b = octets.getUint8(i + 2);
      final int a = octets.getUint8(i + 3);
      if (a < 255) transparents++;
      // Un pixel transparent est, dans le navigateur, le fond creme de la
      // page HTML : il compte comme clair.
      somme += a < 255 ? 244 : 0.2126 * r + 0.7152 * v + 0.0722 * b;
      n++;
    }
  }
  return (transparents: transparents, luminance: somme / n);
}

void main() {
  setUp(() => ecrireMemoireAppareil(clefCompteConnu, '1'));
  tearDown(() => effacerMemoireAppareil(clefCompteConnu));

  test('le controleur demarre directement sur la preference enregistree, '
      'jamais sur Systeme puis elle', () async {
    final ProviderContainer conteneur = ProviderContainer(
      overrides: _sombreEnregistre(),
    );
    addTearDown(conteneur.dispose);
    final List<ThemeMode> vus = <ThemeMode>[];
    conteneur.listen<ThemeMode>(
      modeThemeProvider,
      (ThemeMode? _, ThemeMode apres) => vus.add(apres),
      fireImmediately: true,
    );
    // La restauration asynchrone (persistanceApparenceProvider) passe aussi.
    conteneur.read(persistanceApparenceProvider);
    for (int i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(vus, <ThemeMode>[ThemeMode.dark]);
  });

  test('sans lecture immediate (base locale), le theme part de Systeme', () {
    final ProviderContainer conteneur = ProviderContainer(
      overrides: <Override>[
        stockagePreferencesProvider.overrideWithValue(
          StockagePreferencesMemoire(<String, String>{
            clefPreferenceTheme: 'sombre',
          }),
        ),
        lecturePreferencesImmediateProvider.overrideWithValue(null),
      ],
    );
    addTearDown(conteneur.dispose);
    expect(conteneur.read(modeThemeProvider), ThemeMode.system);
  });

  testWidgets('systeme clair, choix sombre : la premiere image est sombre, et '
      'aucune image de navigation n est claire', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _cadre,
        child: RacineDemonstrable(
          environnement: 'staging',
          surchargesDemoAnnexes: _sombreEnregistre(),
          surchargesReelles: <Override>[
            ...surchargesRouteur(FausseSourceSession()),
            lecturePreferencesImmediateProvider.overrideWithValue(
              StockagePreferencesMemoire(<String, String>{
                clefPreferenceTheme: 'sombre',
              }),
            ),
          ],
        ),
      ),
    );
    // Premiere image : le theme de l'application est deja le sombre.
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp).first).themeMode,
      ThemeMode.dark,
    );
    await stabiliser(tester);
    final Finder entree = find.byKey(
      const ValueKey<String>('entree-demonstration'),
    );
    await tester.ensureVisible(entree);
    await tester.tap(entree);
    await stabiliser(tester);
    await stabiliser(tester);
    expect(find.byType(AccueilFamillePage), findsOneWidget);

    final List<String> constats = <String>[];
    for (final String onglet in <String>['Foyer', 'Historique', 'Accueil']) {
      await tester.tap(find.text(onglet).first);
      for (int frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final ({int transparents, double luminance}) m = await _mesurer(tester);
        if (m.transparents > 0 || m.luminance > 128) {
          constats.add(
            '$onglet, image $frame : ${m.transparents} pixels transparents, '
            'luminance ${m.luminance.toStringAsFixed(0)}',
          );
        }
      }
      await stabiliser(tester);
    }
    expect(constats, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
