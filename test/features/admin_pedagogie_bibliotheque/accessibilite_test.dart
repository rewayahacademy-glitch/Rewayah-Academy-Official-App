// CAP29-H (complement) : theme sombre, navigation clavier, semantique pour
// lecteur d'ecran, sur la bibliotheque d'administration.
//
// Ce que le test prouve : les cinq ecrans se montent en theme sombre sans
// debordement ni mot coupe ; Tab atteint l'action principale de l'attribution
// et Entree l'active (la phrase du blocage apparait, le bouton n'est pas
// grise) ; chaque bouton et chaque champ du contenu a un nom pour le lecteur
// d'ecran ; les ouvertures de ligne du catalogue nomment le support ; l'etat
// d'un critere de publication se lit en mots.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/bibliotheque_admin_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/monter_admin_demo.dart';

final Map<String, String> _ecrans = <String, String>{
  'catalogue': Routes.adminPedagogieBibliotheque,
  'fiche': Routes.adminPedagogieSupport('demo-support-002'),
  'import': Routes.adminPedagogieBibliothequeNouveau,
  'publication': Routes.adminPedagogieSupportPublication('demo-support-002'),
  'attribution': Routes.adminPedagogieSupportAttribution('demo-support-003'),
};

Future<void> _monter(
  WidgetTester tester,
  String route, {
  ThemeMode theme = ThemeMode.light,
  Size taille = const Size(1440, 900),
}) => monterAdminDemo(
  tester,
  route: route,
  bibliotheque: BibliothequeAdminDemo(),
  taille: taille,
  plus: <Override>[modeThemeProvider.overrideWithValue(theme)],
);

/// Les noeuds de semantique qui sont des boutons ou des champs, sans nom.
List<String> _sansNom(WidgetTester tester) {
  final List<String> fautifs = <String>[];
  void visiter(SemanticsNode n) {
    final SemanticsData d = n.getSemanticsData();
    final bool actif =
        d.flagsCollection.isButton || d.flagsCollection.isTextField;
    final bool visible = !d.flagsCollection.isHidden;
    if (actif &&
        visible &&
        d.label.trim().isEmpty &&
        d.value.trim().isEmpty &&
        d.tooltip.trim().isEmpty) {
      fautifs.add('${n.id} ${n.rect}');
    }
    n.visitChildren((SemanticsNode c) {
      visiter(c);
      return true;
    });
  }

  visiter(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return fautifs;
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('theme sombre', () {
    for (final MapEntry<String, String> e in _ecrans.entries) {
      testWidgets('${e.key} : sombre, 390 px', (tester) async {
        await _monter(
          tester,
          e.value,
          theme: ThemeMode.dark,
          taille: const Size(390, 844),
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });

  group('clavier', () {
    testWidgets('Tab atteint « Attribuer », Entree le declenche', (
      tester,
    ) async {
      await _monter(tester, _ecrans['attribution']!);
      bool atteint = false;
      for (int i = 0; i < 120 && !atteint; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final BuildContext? c = FocusManager.instance.primaryFocus?.context;
        if (c == null) continue;
        atteint = _atteintParAncetre(c);
      }
      expect(atteint, isTrue, reason: 'Tab doit atteindre « Attribuer »');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 300));
      // Jamais grise : la phrase du blocage apparait.
      expect(
        find.text(t.admin.bibliotheque.attribution.attribuerAucune),
        findsOneWidget,
      );
    });

    testWidgets('chaque ecran a un focus clavier visitable', (tester) async {
      for (final MapEntry<String, String> e in _ecrans.entries) {
        await _monter(tester, e.value);
        final Set<FocusNode> vus = <FocusNode>{};
        for (int i = 0; i < 30; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final FocusNode? f = FocusManager.instance.primaryFocus;
          if (f != null) vus.add(f);
        }
        expect(vus.length, greaterThan(3), reason: e.key);
      }
    });
  });

  group('lecteur d\'ecran', () {
    for (final MapEntry<String, String> e in _ecrans.entries) {
      testWidgets('${e.key} : boutons et champs nommes', (tester) async {
        final SemanticsHandle h = tester.ensureSemantics();
        await _monter(tester, e.value, taille: const Size(390, 844));
        expect(_sansNom(tester), isEmpty);
        h.dispose();
      });
    }

    testWidgets('catalogue : la ligne lit le titre du support', (tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _monter(tester, _ecrans['catalogue']!);
      // Le titre du support est lu (la ligne s'ouvre au toucher et au clavier).
      expect(
        find.bySemanticsLabel(RegExp('^Introduction au Tajwid')),
        findsWidgets,
      );
      h.dispose();
    });

    testWidgets('publication : l\'etat d\'un critere se lit en mots', (
      tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _monter(tester, _ecrans['publication']!);
      final a = t.admin.bibliotheque.publication.etats;
      expect(find.bySemanticsLabel(RegExp(a.bloque)), findsWidgets);
      h.dispose();
    });
  });
}

/// Vrai quand le focus est dans le sous-arbre du bouton « Attribuer ».
bool _atteintParAncetre(BuildContext focus) {
  bool trouve = false;
  focus.visitAncestorElements((Element a) {
    if (a.widget.key == const ValueKey<String>('attribution-attribuer')) {
      trouve = true;
      return false;
    }
    return true;
  });
  return trouve;
}
