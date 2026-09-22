import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/features/tc_mushaf/selection_verset.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import 'faux/faux_corpus_coran.dart';
import 'goldens/corpus_reference.dart';
import 'support/hote_tc_c.dart';

/// La selection d'un verset : une lentille posee par la classe, absente
/// partout ailleurs.
void main() {
  late CorpusReference reference;

  setUpAll(() => reference = CorpusReference.charger());

  List<Override> surcharges() => <Override>[
    portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
    portLayoutMushafProvider.overrideWithValue(
      const LayoutLignesIndisponible(),
    ),
    portNavigationCoranProvider.overrideWithValue(FauxNavigationCoran()),
  ];

  Future<void> poser(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.pump();
    }
  }

  ContentRange? selection(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(BlocVerset).first))
          .read(selectionVersetProvider);

  /// Tape sur un glyphe du premier verset, la ou le paragraphe le dessine.
  /// Viser un point geometrique (centre, bord) tombe dans l'interligne ou sur
  /// la rosace, un `WidgetSpan` sans reconnaisseur : on demande sa boite au
  /// `RenderParagraph`.
  Future<void> taperLeTexte(WidgetTester tester, Finder bloc) async {
    final Finder texte = find.descendant(
      of: bloc,
      matching: find.byWidgetPredicate(
        (Widget w) => w is Text && w.textSpan != null,
      ),
    );
    final RenderParagraph paragraphe = tester.renderObject<RenderParagraph>(
      find.descendant(of: texte.first, matching: find.byType(RichText)).first,
    );
    final List<TextBox> boites = paragraphe.getBoxesForSelection(
      const TextSelection(baseOffset: 1, extentOffset: 2),
    );
    expect(boites, isNotEmpty, reason: 'le premier verset a des glyphes');
    await tester.tapAt(paragraphe.localToGlobal(boites.first.toRect().center));
  }

  testWidgets('sous la portee, un tap selectionne, un second deselectionne', (
    WidgetTester tester,
  ) async {
    await poserFenetre(tester, const Size(390, 844));
    await tester.pumpWidget(
      hoteCoran(
        const Scaffold(body: PorteeSelectionVerset(child: VueVersetAgrandi())),
        surcharges: surcharges(),
      ),
    );
    await poser(tester);

    expect(selection(tester), isNull);
    await taperLeTexte(tester, find.byType(BlocVerset).first);
    await tester.pump();
    final ContentRange? plage = selection(tester);
    expect(plage, isNotNull);
    expect(plage!.debut, plage.fin);

    await taperLeTexte(tester, find.byType(BlocVerset).first);
    await tester.pump();
    expect(selection(tester), isNull);
  });

  testWidgets('hors portee, un tap ne fait rien : le lecteur d avant', (
    WidgetTester tester,
  ) async {
    await poserFenetre(tester, const Size(390, 844));
    await tester.pumpWidget(
      hoteCoran(
        const Scaffold(body: VueVersetAgrandi()),
        surcharges: surcharges(),
      ),
    );
    await poser(tester);

    await taperLeTexte(tester, find.byType(BlocVerset).first);
    await tester.pump();
    expect(selection(tester), isNull);
  });

  testWidgets('la page du mushaf selectionne aussi, sous la portee', (
    WidgetTester tester,
  ) async {
    await poserFenetre(tester, const Size(390, 844));
    await tester.pumpWidget(
      hoteCoran(
        const Scaffold(body: PorteeSelectionVerset(child: VuePageMushaf())),
        surcharges: surcharges(),
      ),
    );
    await poser(tester);

    // Le feuilleteur construit aussi les pages voisines, hors ecran : on vise
    // un paragraphe reellement touchable.
    final Finder visible = find.byType(ParagrapheVersets).hitTestable().first;
    await taperLeTexte(tester, visible);
    await tester.pump();
    final ContentRange? plage = ProviderScope.containerOf(
      tester.element(visible),
    ).read(selectionVersetProvider);
    expect(plage, isNotNull);
  });
}
