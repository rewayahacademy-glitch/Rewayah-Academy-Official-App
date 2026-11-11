// TRANSITIONS (directeur, 11/11/2026) : un seul catalogue de transitions,
// `lib/core/mouvement/app_transitions.dart`, applique a trois endroits (le
// theme, `pageGlissee`, `AppBottomSheet`). Ce test refuse toute transition
// definie ailleurs, et verifie le depart, l'arrivee, le miroir en arabe et le
// mouvement reduit de chaque type.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/mouvement/app_transitions.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';

/// Ce qui definit une transition de page, de feuille ou de dialogue.
final Map<RegExp, String> _interdits = <RegExp, String>{
  RegExp(r'\bCustomTransitionPage\b'): 'CustomTransitionPage',
  RegExp(r'\bPageRouteBuilder\b'): 'PageRouteBuilder',
  RegExp(r'\bCupertinoPageRoute\b'): 'CupertinoPageRoute',
  RegExp(r'\bNoTransitionPage\s*[<(]'): 'NoTransitionPage',
  RegExp(r'\bPageTransitionsBuilder\b'): 'PageTransitionsBuilder',
  RegExp(r'\btransitionsBuilder\s*:'): 'transitionsBuilder',
  RegExp(r'\bpageTransitionsTheme\s*:'): 'pageTransitionsTheme',
  RegExp(r'\bshowGeneralDialog\b'): 'showGeneralDialog',
  RegExp(r'\bshowModalBottomSheet\b'): 'showModalBottomSheet',
  RegExp(r'\bshowDialog\b'): 'showDialog',
};

/// Les seuls fichiers qui ont le droit de les nommer : le catalogue, son
/// application aux pages empilees, au theme et aux feuilles et dialogues.
const Map<String, Set<String>> _permis = <String, Set<String>>{
  'lib/core/mouvement/app_transitions.dart': <String>{'PageTransitionsBuilder'},
  'lib/core/mouvement/transitions.dart': <String>{
    'CustomTransitionPage',
    'transitionsBuilder',
  },
  'lib/core/theme/app_theme.dart': <String>{'pageTransitionsTheme'},
  'lib/core/widgets/app_bottom_sheet.dart': <String>{
    'showModalBottomSheet',
    'showDialog',
  },
};

/// Les outils de developpement, absents de la production.
bool _horsProduction(String chemin) =>
    chemin.startsWith('lib/features/demo/') ||
    chemin.startsWith('lib/features/_dev/') ||
    chemin.endsWith('.g.dart');

/// Le code sans ses commentaires de ligne (un commentaire peut nommer une
/// API pour l'expliquer).
String _sansCommentaires(String source) => source
    .split('\n')
    .map((String l) {
      final int i = l.indexOf('//');
      return i < 0 ? l : l.substring(0, i);
    })
    .join('\n');

Future<void> _monter(
  WidgetTester tester, {
  required Widget Function(BuildContext) construire,
  TextDirection sens = TextDirection.ltr,
  bool reduit = false,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: taille, disableAnimations: reduit),
      child: Directionality(
        textDirection: sens,
        child: Builder(builder: construire),
      ),
    ),
  );
}

/// Le decalage horizontal et l'opacite effectifs de la cible.
({double dx, double opacite}) _etat(WidgetTester tester, Finder cible) {
  double dx = 0;
  double opacite = 1;
  cible.evaluate().first.visitAncestorElements((Element e) {
    final Widget w = e.widget;
    if (w is Transform) dx += w.transform.getTranslation().x;
    if (w is FadeTransition) opacite *= w.opacity.value;
    return true;
  });
  return (dx: dx, opacite: opacite);
}

void main() {
  test('aucune transition definie hors du catalogue', () {
    final List<String> fautes = <String>[];
    for (final FileSystemEntity f in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final String chemin = f.path.replaceAll(r'\', '/');
      if (_horsProduction(chemin)) continue;
      final String code = _sansCommentaires(f.readAsStringSync());
      for (final MapEntry<RegExp, String> interdit in _interdits.entries) {
        if (!interdit.key.hasMatch(code)) continue;
        if (_permis[chemin]?.contains(interdit.value) ?? false) continue;
        fautes.add('$chemin : ${interdit.value}');
      }
    }
    expect(fautes, isEmpty, reason: fautes.join('\n'));
  });

  test('la sortie dure environ les deux tiers de l entree', () {
    expect(
      AppTransitions.sortieDe(AppMouvement.descente).inMilliseconds,
      inInclusiveRange(185, 190),
    );
  });

  group('descente (axe partage)', () {
    const Key cible = Key('cible');
    Widget descente(
      BuildContext c,
      Animation<double> a, [
      Animation<double> s = kAlwaysDismissedAnimation,
    ]) => AppTransitions.descente(c, a, s, const SizedBox(key: cible));

    testWidgets('depart : decalee vers le bord de lecture et invisible ; '
        'arrivee : en place et visible', (WidgetTester tester) async {
      await _monter(
        tester,
        construire: (BuildContext c) =>
            descente(c, const AlwaysStoppedAnimation<double>(0)),
      );
      final ({double dx, double opacite}) depart = _etat(
        tester,
        find.byKey(cible),
      );
      expect(depart.dx, AppMouvement.courseAxePartage);
      expect(depart.opacite, 0);
      await _monter(
        tester,
        construire: (BuildContext c) =>
            descente(c, const AlwaysStoppedAnimation<double>(1)),
      );
      final ({double dx, double opacite}) arrivee = _etat(
        tester,
        find.byKey(cible),
      );
      expect(arrivee.dx, 0);
      expect(arrivee.opacite, 1);
    });

    testWidgets('en arabe, le sens s inverse', (WidgetTester tester) async {
      await _monter(
        tester,
        sens: TextDirection.rtl,
        construire: (BuildContext c) =>
            descente(c, const AlwaysStoppedAnimation<double>(0)),
      );
      expect(
        _etat(tester, find.byKey(cible)).dx,
        -AppMouvement.courseAxePartage,
      );
    });

    testWidgets('sur ecran large, la course est courte', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1280, 800),
        construire: (BuildContext c) =>
            descente(c, const AlwaysStoppedAnimation<double>(0)),
      );
      expect(
        _etat(tester, find.byKey(cible)).dx,
        AppMouvement.courseAxePartageLarge,
      );
    });

    testWidgets('la page recouverte s efface et recule', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        construire: (BuildContext c) => descente(
          c,
          const AlwaysStoppedAnimation<double>(1),
          const AlwaysStoppedAnimation<double>(1),
        ),
      );
      final ({double dx, double opacite}) e = _etat(tester, find.byKey(cible));
      expect(e.dx, -AppMouvement.courseAxePartage);
      expect(e.opacite, 0);
    });

    testWidgets('mouvement reduit : aucune transition de page', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        reduit: true,
        construire: (BuildContext c) =>
            const DescenteTransitionsBuilder().buildTransitions<void>(
              MaterialPageRoute<void>(builder: (_) => const SizedBox()),
              c,
              const AlwaysStoppedAnimation<double>(0),
              kAlwaysDismissedAnimation,
              const SizedBox(key: cible),
            ),
      );
      final ({double dx, double opacite}) e = _etat(tester, find.byKey(cible));
      expect(e.dx, 0);
      expect(e.opacite, 1);
    });
  });

  testWidgets('fondu enchaine : jamais deux surfaces visibles a la fois', (
    WidgetTester tester,
  ) async {
    const Key cible = Key('onglet');
    Future<double> opacite(double animation, double secondaire) async {
      await _monter(
        tester,
        construire: (BuildContext _) => AppTransitions.fonduEnchaine(
          AlwaysStoppedAnimation<double>(animation),
          AlwaysStoppedAnimation<double>(secondaire),
          const SizedBox(key: cible),
        ),
      );
      return _etat(tester, find.byKey(cible)).opacite;
    }

    for (final double t in <double>[0, 0.1, 0.2, 0.3, 0.4, 0.6, 0.8, 1]) {
      final double entrante = await opacite(t, 0);
      final double sortante = await opacite(1, t);
      expect(entrante > 0 && sortante > 0, isFalse, reason: 't = $t');
    }
    expect(await opacite(1, 0), 1);
  });

  testWidgets('fenetre : zoom leger et fondu, de 0,94 a 1', (
    WidgetTester tester,
  ) async {
    const Key cible = Key('fenetre');
    await _monter(
      tester,
      construire: (BuildContext _) => AppTransitions.zoomFondu(
        const AlwaysStoppedAnimation<double>(0),
        const SizedBox(key: cible),
      ),
    );
    final ScaleTransition zoom = tester.widget<ScaleTransition>(
      find.ancestor(
        of: find.byKey(cible),
        matching: find.byType(ScaleTransition),
      ),
    );
    expect(zoom.scale.value, AppTransitions.echelleFenetre);
    expect(_etat(tester, find.byKey(cible)).opacite, 0);
  });
}
