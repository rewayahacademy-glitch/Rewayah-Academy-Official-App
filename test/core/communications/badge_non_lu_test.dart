// COM-F : UnreadUrgencyBadge (spec sections 19 et 24). Le badge dit chaque
// information par un MOT et une ICONE, jamais par la couleur seule ; le
// lecteur d'ecran entend la phrase entiere ; rien n'est rendu quand il n'y a
// rien a dire ; il tient a 320 px en texte x2, en clair et en sombre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/communications/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import '../../support/hote_theme.dart';

const IndicateurAttention _complet = IndicateurAttention(
  nonLus: 3,
  niveau: NiveauAttention.urgent,
  mention: true,
);

Future<void> _monter(
  WidgetTester tester,
  IndicateurAttention indicateur, {
  bool compact = false,
  double echelle = 1,
  Brightness luminosite = Brightness.light,
}) async {
  await tester.pumpWidget(
    hoteTheme(
      BadgeNonLu(indicateur: indicateur, compact: compact),
      echelleTexte: echelle,
      luminosite: luminosite,
    ),
  );
  await tester.pump();
}

void main() {
  final b = t.com.socle.composants.badge;

  testWidgets('rien a signaler : aucune pastille, pas de « 0 »', (
    WidgetTester tester,
  ) async {
    await _monter(tester, IndicateurAttention.aucun);
    expect(find.byType(StatusPill), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('chaque information a son mot ET son icone (pas la couleur '
      'seule)', (WidgetTester tester) async {
    await _monter(tester, _complet);
    expect(find.text(b.urgent), findsOneWidget);
    expect(find.text(b.nonLus(nombre: 3)), findsOneWidget);
    expect(find.text(b.mention), findsOneWidget);

    final Finder pastilles = find.byType(StatusPill);
    expect(pastilles, findsNWidgets(3));
    for (final Element e in pastilles.evaluate()) {
      final StatusPill p = e.widget as StatusPill;
      expect(p.libelle.trim(), isNotEmpty);
      // Le marqueur est une icone, a la place du disque de couleur.
      expect(p.marqueur, isNotNull);
      expect(
        find.descendant(of: find.byWidget(p), matching: find.byType(Icon)),
        findsOneWidget,
        reason: p.libelle,
      );
    }
  });

  testWidgets('l urgence se lit avant le compte', (WidgetTester tester) async {
    await _monter(tester, _complet);
    final double niveau = tester
        .getTopLeft(find.byKey(BadgeNonLu.cleNiveau))
        .dx;
    final double compte = tester
        .getTopLeft(find.byKey(BadgeNonLu.cleNonLus))
        .dx;
    expect(niveau, lessThan(compte));
  });

  testWidgets('le lecteur d ecran entend la phrase entiere', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle sem = tester.ensureSemantics();
    await _monter(tester, _complet);
    final String phrase =
        '${b.urgent}, ${b.nonLusSemantique(nombre: 3)}, ${b.mentionSemantique}';
    expect(BadgeNonLu.phraseSemantique(_complet), phrase);
    expect(find.bySemanticsLabel(phrase), findsOneWidget);
    sem.dispose();
  });

  testWidgets('compact : une pastille, la plus pressante ; la phrase reste '
      'entiere', (WidgetTester tester) async {
    final SemanticsHandle sem = tester.ensureSemantics();
    await _monter(tester, _complet, compact: true);
    expect(find.byType(StatusPill), findsOneWidget);
    expect(find.text(b.urgent), findsOneWidget);
    expect(
      find.bySemanticsLabel(BadgeNonLu.phraseSemantique(_complet)!),
      findsOneWidget,
    );
    sem.dispose();
  });

  testWidgets('un seul non-lu : singulier, a l ecran et a la voix', (
    WidgetTester tester,
  ) async {
    const IndicateurAttention un = IndicateurAttention(nonLus: 1);
    await _monter(tester, un);
    expect(find.text(b.nonLuUn), findsOneWidget);
    expect(BadgeNonLu.phraseSemantique(un), b.nonLuUnSemantique);
    // Information + non-lus : le compte suffit, pas de pastille de niveau.
    expect(find.byKey(BadgeNonLu.cleNiveau), findsNothing);
  });

  testWidgets('« A lire » sans compte, « Action requise » toujours dite', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const IndicateurAttention(niveau: NiveauAttention.aLire),
    );
    expect(find.text(b.aLire), findsOneWidget);

    await _monter(
      tester,
      const IndicateurAttention(
        nonLus: 2,
        niveau: NiveauAttention.actionRequise,
      ),
    );
    expect(find.text(b.actionRequise), findsOneWidget);
    expect(find.text(b.nonLus(nombre: 2)), findsOneWidget);
  });

  for (final Brightness luminosite in Brightness.values) {
    testWidgets('320 px, texte x2, ${luminosite.name} : aucun debordement', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 640));
      await _monter(tester, _complet, echelle: 2, luminosite: luminosite);
      expect(tester.takeException(), isNull);
      for (final String mot in <String>[
        b.urgent,
        b.nonLus(nombre: 3),
        b.mention,
      ]) {
        expect(find.text(mot), findsOneWidget);
        final Rect r = tester.getRect(find.text(mot));
        expect(r.right, lessThanOrEqualTo(320), reason: mot);
        expect(r.left, greaterThanOrEqualTo(0), reason: mot);
      }
    });
  }
}
