// MUSHAF-DIR-1 et MA-CORAN-X2-1 (05/10/2026) : la preuve que le TEXTE
// CORANIQUE n'a pas bouge.
//
// L'etape ne touche que les messages francais et les etats sans texte du
// lecteur (sens d'ecriture, defilement sous les commandes). Ce test releve,
// pour une page LUE, chaque paragraphe de versets rendu (versets du rendu page et
// du verset agrandi) : la chaine exacte, la police, la taille, l'interligne,
// l'alignement, le sens, la taille du paragraphe, le nombre et la largeur
// de ses lignes, et l'arbre des widgets qui le portent. Le releve est compare
// a l'empreinte enregistree sur l'ancien code (base
// origin/ccr-1b1bfa0b-m1kvkk @ 8cb178b9), dans
// `empreinte_texte_coran.txt` : un seul caractere, un seul pixel de mesure
// ou un seul widget de difference fait echouer le test.
//
// Regenerer (seulement sur l'ancien code) : EMPREINTE_CORAN=ecrire.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';

const String _fichier = 'test/features/tc_mushaf/empreinte_texte_coran.txt';

/// Le releve des paragraphes de versets sous [racines].
String _releve(WidgetTester tester, String scenario, Finder racines) {
  final StringBuffer sortie = StringBuffer('== $scenario\n');
  // Les paragraphes des versets : rendu page (flux continu ou lignes) et
  // verset agrandi, rosaces comprises. L'en-tete de sourate n'est pas
  // releve : CORAN-320-1 (autre session) le refait ; cette etape n'y touche
  // pas (voir le diff).
  final Finder porteurs = find.descendant(
    of: racines,
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is ParagrapheVersets || w is LigneComposee || w is BlocVerset,
    ),
  );
  final Finder paragraphes = find.descendant(
    of: porteurs,
    matching: find.byType(RichText),
  );
  int n = 0;
  for (final Element element in paragraphes.evaluate()) {
    final RichText texte = element.widget as RichText;
    final String brut = texte.text.toPlainText();
    final RenderParagraph rendu = element.renderObject! as RenderParagraph;
    final TextStyle? style = texte.text.style;
    // Les boites du texte entier : une par ligne et par sens, donc les
    // coupures de ligne exactes.
    final List<TextBox> lignes = rendu.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: brut.length),
    );
    sortie
      ..writeln('-- paragraphe ${n++}')
      ..writeln('texte: $brut')
      ..writeln(
        'police: ${style?.fontFamily} ${style?.fontFamilyFallback} '
        'taille: ${style?.fontSize?.toStringAsFixed(3)} '
        'interligne: ${style?.height?.toStringAsFixed(3)} '
        'graisse: ${style?.fontWeight}',
      )
      ..writeln(
        'alignement: ${texte.textAlign} sens: ${texte.textDirection} '
        'rendu-sens: ${rendu.textDirection} '
        'echelle: ${texte.textScaler}',
      )
      ..writeln(
        'taille: ${rendu.size.width.toStringAsFixed(2)} x '
        '${rendu.size.height.toStringAsFixed(2)} lignes: ${lignes.length}',
      )
      ..writeln(
        'boites: ${lignes.map((TextBox b) => '[${b.left.toStringAsFixed(1)},${b.top.toStringAsFixed(1)},${b.right.toStringAsFixed(1)},${b.bottom.toStringAsFixed(1)}]').join(' ')}',
      );
  }
  // L'arbre des widgets du texte : les types, dans l'ordre, sous chaque
  // paragraphe de versets (rendu page) ou bloc de verset (verset agrandi).
  for (final Type porteur in <Type>[
    ParagrapheVersets,
    LigneComposee,
    BlocVerset,
  ]) {
    final Finder blocs = find.descendant(
      of: racines,
      matching: find.byType(porteur),
    );
    for (final Element bloc in blocs.evaluate()) {
      final List<String> types = <String>[];
      void visiter(Element e, int profondeur) {
        types.add('${'  ' * profondeur}${e.widget.runtimeType}');
        e.visitChildElements((Element enfant) => visiter(enfant, profondeur + 1));
      }

      visiter(bloc, 0);
      sortie
        ..writeln('-- arbre $porteur')
        ..writeln(types.join('\n'));
    }
  }
  expect(n, greaterThan(0), reason: '$scenario : aucun verset rendu');
  return sortie.toString();
}

/// Une page du corpus de reference (une page LUE, avec du texte).
int _pageLue(CorpusReference reference) => reference.pages
    .firstWhere((PageCorpus p) => p.versets.isNotEmpty && p.numero > 1)
    .numero;

List<Override> _surcharges(CorpusReference reference) => <Override>[
  portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
  portLayoutMushafProvider.overrideWithValue(const LayoutLignesIndisponible()),
  portNavigationCoranProvider.overrideWithValue(
    FauxNavigationCoran(
      personnelle: PositionLecture(
        page: _pageLue(reference),
        sourate: 1,
        verset: 1,
      ),
    ),
  ),
];

Future<void> _poser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _hote(Widget enfant, ProviderContainer racine, double echelle) =>
    UncontrolledProviderScope(
      container: racine,
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.enfant, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(echelle)),
            child: child!,
          ),
          home: enfant,
        ),
      ),
    );

void main() {
  late CorpusReference reference;
  final Map<String, String> releves = <String, String>{};

  setUpAll(() async {
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

  // Le lecteur du Mode Accessibilite (celui que l'etape touche autour).
  for (final (String nom, Size taille, double echelle, bool grande)
      in <(String, Size, double, bool)>[
        ('ma_page_390_x1', const Size(390, 844), 1, false),
        ('ma_page_320_x2', const Size(320, 700), 2, false),
        ('ma_page_1440_x1', const Size(1440, 900), 1, false),
        ('ma_verset_agrandi_390_x2', const Size(390, 844), 2, true),
        ('ma_verset_agrandi_320_x2', const Size(320, 700), 2, true),
      ]) {
    testWidgets('texte coranique inchange : $nom', (WidgetTester tester) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ProviderContainer racine = ProviderContainer();
      addTearDown(racine.dispose);
      racine.read(preferencesLocalesProvider.notifier).lectureGrande(grande);
      await tester.pumpWidget(
        _hote(
          EcranAccessibiliteDemo(
            eleve: EleveDemoAccessibilite.idriss,
            destinationInitiale: EcranAccessibiliteDemo.indexCoran,
            surchargesCoran: _surcharges(reference),
          ),
          racine,
          echelle,
        ),
      );
      await _poser(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('coran-ma-principale')),
      );
      await _poser(tester);
      releves[nom] = _releve(
        tester,
        nom,
        find.byType(grande ? ColonneVersetsReflow : TexteDePage),
      );
      expect(tester.takeException(), isNull);
    });
  }

  // Le lecteur standard (`MushafPage`), telephone et ecran large.
  for (final (String nom, Size taille, double echelle)
      in <(String, Size, double)>[
        ('standard_390_x1', const Size(390, 844), 1),
        ('standard_320_x2', const Size(320, 700), 2),
        ('standard_1440_x1', const Size(1440, 900), 1),
      ]) {
    testWidgets('texte coranique inchange : $nom', (WidgetTester tester) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ProviderContainer racine = ProviderContainer(
        overrides: _surcharges(reference),
      );
      addTearDown(racine.dispose);
      await tester.pumpWidget(_hote(const MushafPage(), racine, echelle));
      await _poser(tester);
      releves[nom] = _releve(tester, nom, find.byType(TexteDePage));
      // A 320 x2, les commandes de `MushafPage` debordent deja sur l'ancien
      // code (hors du texte, hors de cette etape) : seul le releve compte.
      final Object? erreur = tester.takeException();
      if (nom != 'standard_320_x2') expect(erreur, isNull);
    });
  }

  test("l'empreinte est celle de l'ancien code", () {
    final String actuel = (releves.keys.toList()..sort())
        .map((String k) => releves[k]!)
        .join();
    final File empreinte = File(_fichier);
    if (Platform.environment['EMPREINTE_CORAN'] == 'ecrire') {
      empreinte.writeAsStringSync(actuel);
      return;
    }
    expect(
      actuel,
      empreinte.readAsStringSync(),
      reason: 'Le texte coranique rendu a change',
    );
  });
}
