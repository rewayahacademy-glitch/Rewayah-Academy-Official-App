// L'effet liquide de la barre flottante (decisions du directeur du
// 10/11/2026) : au repos, rien ne change ; au changement de destination, la
// goutte s'etire dans le sens du mouvement puis se reforme ; de la pilule au
// cercle, elle passe par l'espace qui les separe (le pont) ; miroir en arabe ;
// « reduire les animations » : changement immediat.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/avatar_compte.dart';
import 'package:rewayah_academy/core/widgets/indicateur_liquide.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

Widget _barre({TextDirection sens = TextDirection.ltr, bool reduit = false}) {
  int actif = 0;
  final List<Destination> d = destinationsPour(
    role: AppRole.guardian,
    mode: InterfaceMode.standard,
  );
  return hote(
    StatefulBuilder(
      builder: (BuildContext contexte, StateSetter majeur) => MediaQuery(
        data: MediaQuery.of(contexte).copyWith(disableAnimations: reduit),
        child: Directionality(
          textDirection: sens,
          child: NavShell(
            destinations: d,
            indexActif: actif,
            onAller: (String c) => majeur(
              () => actif = d.indexWhere((Destination x) => x.chemin == c),
            ),
            child: const PageShell(child: SizedBox(key: Key('contenu'))),
          ),
        ),
      ),
    ),
    surcharges: <Override>[sansPersonneConnectee()],
  );
}

void _vue(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

BuildContext _ici(WidgetTester tester) =>
    tester.element(find.bySemanticsLabel(t.nav.tuteur.accueil));

void main() {
  group('pontMetaballe', () {
    test('trop loin : aucun pont', () {
      final Path p = pontMetaballe(Offset.zero, 10, const Offset(200, 0), 10);
      expect(p.getBounds().isEmpty, isTrue);
    });

    test('proches : un pont entre les deux disques', () {
      final Rect b = pontMetaballe(
        Offset.zero,
        10,
        const Offset(30, 0),
        10,
      ).getBounds();
      expect(b.isEmpty, isFalse);
      expect(b.left, greaterThanOrEqualTo(-10));
      expect(b.right, lessThanOrEqualTo(40));
    });
  });

  testWidgets('au repos : aucune goutte, l onglet ouvert garde son fond', (
    WidgetTester tester,
  ) async {
    _vue(tester);
    await tester.pumpWidget(_barre());
    await tester.pumpAndSettle();
    expect(IndicateurLiquide.goutteDe(_ici(tester)), isNull);
  });

  testWidgets('d un onglet a l autre : la goutte s etire, puis se reforme', (
    WidgetTester tester,
  ) async {
    _vue(tester);
    await tester.pumpWidget(_barre());
    await tester.pumpAndSettle();
    final double depart = tester
        .getSize(find.bySemanticsLabel(t.nav.tuteur.accueil))
        .width;
    await tester.tap(find.bySemanticsLabel(t.nav.tuteur.historique));
    await tester.pump();
    await tester.pump();
    double plusLarge = 0;
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final Rect? g = IndicateurLiquide.goutteDe(_ici(tester));
      if (g != null && g.width > plusLarge) plusLarge = g.width;
    }
    final double arrivee = tester
        .getSize(find.bySemanticsLabel(t.nav.tuteur.historique))
        .width;
    // Etiree : plus large que le depart et que l'arrivee.
    expect(plusLarge, greaterThan(depart));
    expect(plusLarge, greaterThan(arrivee));
    await tester.pumpAndSettle();
    expect(IndicateurLiquide.goutteDe(_ici(tester)), isNull);
    expect(tester.takeException(), isNull);
  });

  // LIQUIDE-MATIERE (corrections du directeur du 11/11/2026) : de la pilule
  // au cercle, aucune goutte de couleur ne voyage ; le cercle est tire hors
  // de la pilule : une seule forme, puis un cou qui s'amincit et se rompt
  // d'un coup ; le cercle et le bout de la pilule rebondissent.
  for (final TextDirection sens in TextDirection.values) {
    testWidgets('${sens.name} : vers le cercle, un cou concave qui '
        's amincit puis se rompt, jamais de couleur entre les deux', (
      WidgetTester tester,
    ) async {
      _vue(tester);
      await tester.pumpWidget(_barre(sens: sens));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(t.nav.tuteur.compte));
      await tester.pump();
      await tester.pump();
      final List<({double ecart, double cou})> suite =
          <({double ecart, double cou})>[];
      final Set<double> echelles = <double>{};
      final Set<double> etirements = <double>{};
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final BuildContext ici = _ici(tester);
        // La couleur de selection n'entre jamais dans le cou.
        final Rect? g = IndicateurLiquide.goutteDe(ici);
        final List<Rect> z = IndicateurLiquide.zonesDe(ici);
        if (g != null && z.length == 2) {
          expect(g.overlaps(z[0]) && g.overlaps(z[1]), isFalse);
        }
        final ({double ecart, double cou})? d = IndicateurLiquide.detachementDe(
          ici,
        );
        if (d != null) suite.add(d);
        for (final Transform tr in tester.widgetList<Transform>(
          find.ancestor(
            of: find.byType(AvatarCompte),
            matching: find.byType(Transform),
          ),
        )) {
          echelles.add(tr.transform.getMaxScaleOnAxis());
        }
        for (final Transform tr in tester.widgetList<Transform>(
          find.ancestor(
            of: find.bySemanticsLabel(t.nav.tuteur.accueil),
            matching: find.byType(Transform),
          ),
        )) {
          etirements.add(tr.transform.storage[0]);
        }
      }
      expect(suite, isNotEmpty);
      // Une seule forme : les deux silhouettes se fondent, le cou est plein.
      final int fondu = suite.indexWhere(
        (({double ecart, double cou}) d) => d.ecart < 0 && d.cou >= 0.5,
      );
      expect(fondu, isNonNegative);
      // Puis le cou s'amincit en s'etirant...
      final List<({double ecart, double cou})> apres = suite.sublist(fondu);
      final int fin = apres.indexWhere(
        (({double ecart, double cou}) d) => d.ecart > 0 && d.cou > 0,
      );
      expect(fin, isNonNegative);
      expect(
        apres.any(
          (({double ecart, double cou}) d) => d.cou > 0 && d.cou < 0.25,
        ),
        isTrue,
      );
      // ... et se rompt d'un coup : plus de cou, le detachement continue.
      final int rompu = apres.indexWhere(
        (({double ecart, double cou}) d) => d.ecart > 0 && d.cou == 0,
        fin,
      );
      expect(rompu, isNonNegative);
      expect(
        apres
            .sublist(rompu)
            .every((({double ecart, double cou}) d) => d.cou == 0),
        isTrue,
      );
      // Les deux bords rebondissent : le cercle et le bout de la pilule.
      expect(echelles.any((double x) => x > 1.001), isTrue);
      expect(etirements.any((double x) => x > 1.0001), isTrue);
      await tester.pumpAndSettle();
      expect(IndicateurLiquide.detachementDe(_ici(tester)), isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('au repos, ni contour ni pont : la pilule et le cercle sont une '
      'meme matiere', (WidgetTester tester) async {
    _vue(tester);
    await tester.pumpWidget(_barre());
    await tester.pumpAndSettle();
    expect(IndicateurLiquide.detachementDe(_ici(tester)), isNull);
    final Iterable<DecoratedBox> boites = tester.widgetList<DecoratedBox>(
      find.ancestor(
        of: find.bySemanticsLabel(t.nav.tuteur.accueil),
        matching: find.byType(DecoratedBox),
      ),
    );
    for (final DecoratedBox b in boites) {
      final Decoration d = b.decoration;
      if (d is BoxDecoration) expect(d.border, isNull);
    }
  });

  testWidgets('retour vers un onglet : la couleur y vient en fondu, apres le '
      'pont', (WidgetTester tester) async {
    _vue(tester);
    await tester.pumpWidget(_barre());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(t.nav.tuteur.compte));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(t.nav.tuteur.accueil));
    await tester.pump();
    await tester.pump();
    final Animation<double>? fondu = IndicateurLiquide.fonduDestination(
      _ici(tester),
    );
    expect(fondu, isNotNull);
    // Le cercle d'abord, absorbe : la couleur attend.
    expect(fondu!.value, lessThan(0.01));
    // Il s'approche : un cou se forme, puis les deux se fondent.
    final List<({double ecart, double cou})> suite =
        <({double ecart, double cou})>[];
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final ({double ecart, double cou})? d = IndicateurLiquide.detachementDe(
        _ici(tester),
      );
      if (d != null) suite.add(d);
    }
    expect(
      suite.any((({double ecart, double cou}) d) => d.ecart > 0 && d.cou > 0),
      isTrue,
    );
    expect(suite.any((({double ecart, double cou}) d) => d.ecart < 0), isTrue);
    await tester.pumpAndSettle();
    expect(fondu.value, 1);
    expect(IndicateurLiquide.detachementDe(_ici(tester)), isNull);
  });

  testWidgets('reduire les animations : changement immediat, aucune goutte', (
    WidgetTester tester,
  ) async {
    _vue(tester);
    await tester.pumpWidget(_barre(reduit: true));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(t.nav.tuteur.historique));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(IndicateurLiquide.goutteDe(_ici(tester)), isNull);
    // Ni pont de matiere : la destination change seule.
    await tester.tap(find.bySemanticsLabel(t.nav.tuteur.compte));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(IndicateurLiquide.detachementDe(_ici(tester)), isNull);
  });
}
