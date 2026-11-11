// Lot SUPPORTS-ETAGERE (directeur, 11/11/2026 ; CAHIER-SALLE §7) :
// l'etagere des supports, la fiche, « Afficher » et « Partager ».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/couverture_ressource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/couverture_support.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/salle_enseignant/etagere_supports.dart';

import '../../capture/outil_capture.dart';
import '../../support/garde_interface.dart';

/// Le Coran et deux demonstrations « a valider » (CAHIER-SALLE §7) ; les
/// rappels comptent ce qui est demande.
class _Rappels {
  int presenter = 0;
  int reprendre = 0;
  final List<int> pagesPartagees = <int>[];
}

List<SupportBibliotheque> _supportsDemo(
  _Rappels r, {
  bool reprise = false,
  bool peutPresenter = true,
}) => <SupportBibliotheque>[
  SupportBibliotheque(
    id: 'coran',
    titre: t.salle.supports.coran,
    detail: reprise
        ? t.cahierC1.onReprendPage(page: 42)
        : t.salle.supports.coranDetail,
    couverture: CouvertureRessource.coran(t.salle.supports.coran),
    onPresenter: peutPresenter ? () => r.presenter++ : null,
    pageReprise: reprise ? 42 : null,
    onReprendre: reprise && peutPresenter ? () => r.reprendre++ : null,
    lecteur: LecteurSupport(
      pages: 604,
      pageDepart: 1,
      page: (BuildContext _, int n) =>
          SizedBox(height: 200, child: Text('page $n')),
      partagerPage: peutPresenter ? r.pagesPartagees.add : null,
    ),
  ),
  SupportBibliotheque(
    id: 'lettres',
    titre: t.salle.etagere.demo.lettres,
    detail: t.salle.etagere.demo.lettresDetail,
    couverture: const CouvertureRessource(
      indexTeinte: 0,
      motif: MotifCouverture.lignes,
      monogramme: 'L',
      type: TypeRessource.texteStructure,
    ),
    aValider: true,
    repere: t.salle.etagere.etape(numero: 1),
  ),
  SupportBibliotheque(
    id: 'voyelles',
    titre: t.salle.etagere.demo.voyelles,
    detail: t.salle.etagere.demo.voyellesDetail,
    couverture: const CouvertureRessource(
      indexTeinte: 1,
      motif: MotifCouverture.arcs,
      monogramme: 'V',
      type: TypeRessource.texteStructure,
    ),
    aValider: true,
  ),
];

Future<void> _monter(
  WidgetTester tester,
  Widget etagere, {
  Size taille = const Size(360, 900),
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: etagere),
      ),
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('l etagere montre une couverture par support, posee sur une '
      'planche, la mention « A valider » sur les demonstrations', (
    WidgetTester tester,
  ) async {
    final _Rappels r = _Rappels();
    await _monter(tester, EtagereSupports(supports: _supportsDemo(r)));
    expect(find.byType(CouvertureSupport), findsNWidgets(3));
    expect(find.text(t.salle.etagere.aValider), findsNWidgets(2));
    // LISTES-1 : la recherche reste fermee sous huit supports, la loupe
    // l'ouvre.
    expect(
      find.byKey(const ValueKey<String>('bibliotheque-recherche')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey<String>('bibliotheque-loupe')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('bibliotheque-recherche')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la fiche du Coran : « Partager » seul bouton plein, '
      '« Afficher » en contour, chacun explique', (WidgetTester tester) async {
    final _Rappels r = _Rappels();
    await _monter(tester, EtagereSupports(supports: _supportsDemo(r)));
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-deplier-coran')),
    );
    await tester.pumpAndSettle();
    final ActionPrincipale partager = tester.widget<ActionPrincipale>(
      find.byKey(const ValueKey<String>('bibliotheque-presenter-coran')),
    );
    expect(partager.niveau, NiveauAction.principale);
    final ActionPrincipale afficher = tester.widget<ActionPrincipale>(
      find.byKey(const ValueKey<String>('bibliotheque-afficher-coran')),
    );
    expect(afficher.niveau, NiveauAction.secondaire);
    expect(find.text(t.salle.etagere.partagerDetail), findsOneWidget);
    expect(find.text(t.salle.etagere.afficherDetail), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-presenter-coran')),
    );
    expect(r.presenter, 1);
  });

  testWidgets('avec une reprise, « Partager page 42 » reprend la ou la '
      'classe s est arretee ; un autre endroit devient un lien', (
    WidgetTester tester,
  ) async {
    final _Rappels r = _Rappels();
    await _monter(
      tester,
      EtagereSupports(supports: _supportsDemo(r, reprise: true)),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-deplier-coran')),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.salle.etagere.reprise(page: 42)), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-reprendre-coran')),
    );
    expect(r.reprendre, 1);
    expect(r.presenter, 0);
    verifierUnSeulBoutonPlein(tester);
  });

  testWidgets('« Afficher » : la page pour l enseignant seul, les fleches, '
      'puis « Partager page N »', (WidgetTester tester) async {
    final _Rappels r = _Rappels();
    await _monter(
      tester,
      EtagereSupports(supports: _supportsDemo(r, reprise: true)),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-deplier-coran')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-afficher-coran')),
    );
    await tester.pumpAndSettle();
    // La lecture part de la reprise ; rien n'est partage en l'ouvrant.
    expect(find.text('page 42'), findsOneWidget);
    expect(find.text(t.salle.etagere.seulVous), findsOneWidget);
    expect(r.pagesPartagees, isEmpty);
    await tester.tap(find.bySemanticsLabel(t.salle.etagere.pageSuivante));
    await tester.pumpAndSettle();
    expect(find.text('page 43'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-partager-page-coran')),
    );
    expect(r.pagesPartagees, <int>[43]);
  });

  testWidgets('sans le droit de presenter : ni « Partager » ni « Partager '
      'page N », une phrase le dit ; « Afficher » reste', (
    WidgetTester tester,
  ) async {
    final _Rappels r = _Rappels();
    await _monter(
      tester,
      EtagereSupports(supports: _supportsDemo(r, peutPresenter: false)),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-deplier-coran')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('bibliotheque-presenter-coran')),
      findsNothing,
    );
    expect(find.text(t.salle.etagere.nonPartageable), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-afficher-coran')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('bibliotheque-partager-page-coran')),
      findsNothing,
    );
  });

  testWidgets('un support « a valider » sans lecture ni partage : aucun '
      'bouton, la fiche dit pourquoi', (WidgetTester tester) async {
    final _Rappels r = _Rappels();
    await _monter(tester, EtagereSupports(supports: _supportsDemo(r)));
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-deplier-lettres')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ActionPrincipale), findsNothing);
    expect(find.text(t.salle.etagere.aValiderDetail), findsOneWidget);
    expect(find.text(t.salle.etagere.nonOuvrable), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('bibliotheque-revenir-etagere')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CouvertureSupport), findsNWidgets(3));
  });

  testWidgets('etats : chargement (Skeleton), vide, erreur avec Reessayer, '
      'hors ligne', (WidgetTester tester) async {
    await _monter(
      tester,
      const EtagereSupports(
        supports: <SupportBibliotheque>[],
        etat: EtatEtagere.chargement,
      ),
    );
    expect(find.byType(Skeleton), findsWidgets);
    await _monter(
      tester,
      const EtagereSupports(supports: <SupportBibliotheque>[]),
    );
    expect(find.text(t.salle.etagere.vide), findsOneWidget);
    int relu = 0;
    await _monter(
      tester,
      EtagereSupports(
        supports: const <SupportBibliotheque>[],
        etat: EtatEtagere.erreur,
        onReessayer: () => relu++,
      ),
    );
    expect(find.text(t.salle.etagere.erreurTitre), findsOneWidget);
    await tester.tap(find.text(t.commun.reessayer));
    expect(relu, 1);
    await _monter(
      tester,
      const EtagereSupports(
        supports: <SupportBibliotheque>[],
        etat: EtatEtagere.horsLigne,
      ),
    );
    expect(find.text(t.salle.etagere.horsLigne), findsOneWidget);
  });

  for (final ThemeMode theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('320 points, texte x2, ${theme.name} : rien ne deborde, '
        'etagere et fiche', (WidgetTester tester) async {
      final _Rappels r = _Rappels();
      await _monter(
        tester,
        EtagereSupports(
          supports: _supportsDemo(r, reprise: true),
          onFermer: () {},
        ),
        taille: const Size(320, 800),
        texte: 2,
        theme: theme,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byKey(const ValueKey<String>('bibliotheque-deplier-coran')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      verifierUnSeulBoutonPlein(tester);
    });
  }
}
