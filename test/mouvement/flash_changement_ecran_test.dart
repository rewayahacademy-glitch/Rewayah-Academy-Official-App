// LG-FLASH (17/10/2026) : « quand on change d'ecran, un autre contenu
// s'affiche d'un coup et disparait », « en mode sombre, a chaque clic, le
// theme clair s'affiche quelques millisecondes ».
//
// Deux causes, mesurees sur la version web compilee (captures du lot) :
//
// 1. Le fondu d'onglet du tuteur (`FonduOnglet`) part d'une opacite nulle,
//    et, sur tablette et ordinateur, rien d'opaque n'etait peint sous le
//    contenu : la toile de Flutter restait transparente et laissait voir le
//    fond creme de `web/index.html`. Ici, un pixel transparent sous la
//    navigation est ce fond creme.
// 2. La page empilee (`pageGlissee`) faisait un fondu enchaine : la nouvelle
//    page apparaissait par transparence par-dessus l'ancienne, les deux
//    textes superposes le temps de la transition.
//
// Le test pompe frame par frame (16 ms) et verifie, a chaque frame : aucun
// pixel transparent ni clair dominant dans la zone de contenu, et jamais deux
// pages visibles a la fois.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/demo/racine_demonstrable.dart';
import 'package:rewayah_academy/features/suivi_famille/suivi_famille_page.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart' show FausseSourceSession;
import '../teaching_core/a/faux/faux_groupes.dart' show PortHorlogeMuet;

const Key _cadre = ValueKey<String>('cadre-flash');

List<Override> _communes() => <Override>[
  stockagePreferencesProvider.overrideWithValue(StockagePreferencesMemoire()),
  portHorlogeSeanceProvider.overrideWithValue(const PortHorlogeMuet()),
];

/// Monte la demonstration tuteur sur ordinateur, theme du systeme sombre
/// (`themeMode` nul : la preference « Systeme » par defaut).
Future<void> _monterDemoSombre(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _cadre,
      child: RacineDemonstrable(
        environnement: 'staging',
        surchargesDemoAnnexes: _communes(),
        surchargesReelles: surchargesRouteur(FausseSourceSession()),
      ),
    ),
  );
  await stabiliser(tester);
  final Finder entree = find.byKey(
    const ValueKey<String>('entree-demonstration'),
  );
  await tester.ensureVisible(entree);
  await tester.tap(entree);
  await stabiliser(tester);
  expect(find.byType(AccueilFamillePage), findsOneWidget);
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

/// L'opacite effective d'un widget : produit des fondus qui le portent.
double _opacite(WidgetTester tester, Finder cible) {
  if (cible.evaluate().isEmpty) return 0;
  double produit = 1;
  cible.evaluate().first.visitAncestorElements((Element e) {
    final Widget w = e.widget;
    if (w is FadeTransition) produit *= w.opacity.value;
    if (w is Opacity) produit *= w.opacity;
    return true;
  });
  return produit;
}

void main() {
  testWidgets('mode sombre : changer d onglet ne montre jamais une frame '
      'transparente ou claire', (WidgetTester tester) async {
    await _monterDemoSombre(tester);
    final MaterialApp avant = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    final List<String> constats = <String>[];
    for (final String onglet in <String>['Foyer', 'Historique', 'Accueil']) {
      await tester.tap(find.text(onglet).first);
      for (int frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final ({int transparents, double luminance}) m = await _mesurer(tester);
        if (m.transparents > 0 || m.luminance > 128) {
          constats.add(
            '$onglet, frame $frame : ${m.transparents} pixels transparents, '
            'luminance ${m.luminance.toStringAsFixed(0)}',
          );
        }
      }
      await stabiliser(tester);
    }
    expect(constats, isEmpty);
    // Le theme n'est pas recalcule par un clic : la racine garde le meme
    // `MaterialApp`, donc le meme theme sombre.
    expect(
      identical(tester.widget<MaterialApp>(find.byType(MaterialApp)), avant),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('page empilee : l ancienne et la nouvelle page ne sont jamais '
      'visibles ensemble, ni a l aller ni au retour', (
    WidgetTester tester,
  ) async {
    await _monterDemoSombre(tester);
    final Finder ancienne = find.byType(AccueilFamillePage);
    final Finder nouvelle = find.byType(SuiviDemandesEntree);
    final List<String> constats = <String>[];
    Future<void> suivre(String sens) async {
      for (int frame = 0; frame < 24; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double a = _opacite(tester, ancienne);
        final double b = _opacite(tester, nouvelle);
        if (a > 0.02 && b > 0.02) {
          constats.add(
            '$sens, frame $frame : ancienne ${a.toStringAsFixed(2)}, '
            'nouvelle ${b.toStringAsFixed(2)}',
          );
        }
        final ({int transparents, double luminance}) m = await _mesurer(tester);
        if (m.transparents > 0) {
          constats.add('$sens, frame $frame : ${m.transparents} transparents');
        }
      }
      await stabiliser(tester);
    }

    await tester.tap(find.textContaining('Voir le suivi des demandes'));
    await suivre('aller');
    expect(nouvelle, findsOneWidget);
    // Le retour par la destination active : il reprend la branche a sa
    // racine, donc retire la page empilee.
    await tester.tap(find.text('Accueil').first);
    await suivre('retour');
    expect(constats, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
