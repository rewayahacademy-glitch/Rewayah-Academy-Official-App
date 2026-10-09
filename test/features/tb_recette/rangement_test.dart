// TB-9 (plan V2 §2, §3 « Ranger reellement », §12, §19.2 ; UX-18, UX-19,
// UX-22) : ranger dans la bibliotheque, reprendre, effacer les notes.
//
// Mesures sur le rendu : la page et la feuille montees, les traits passes
// au calque (identifiants), la copie du rangement montee dans l'overlay et
// ses rectangles, la feuille de confirmation, jamais le texte du code.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/envol_vers_cible.dart';
import 'package:rewayah_academy/core/mouvement/mouvement.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/confirm_destructive.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../capture/outil_capture.dart' hide stabiliser;
import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const Size _etroit = Size(320, 700);

final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);
final Finder _menu = find.byKey(CommandesPedagogiques.cleMenu);
final Finder _bibliotheque = find.byKey(CommandesPedagogiques.cleBibliotheque);
final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _feuille = find.byKey(SurfacePageFixe.cleFeuille);
final Finder _copie = find.byKey(EnvolVersCible.cle);
final Finder _range = find.byKey(CommandesPedagogiques.cleRange);
final Finder _presenter = find.byKey(BibliothequeSeance.clePresenter);
final Finder _catalogue = find.byType(SurfaceBibliotheque);

Future<void> _monter(
  WidgetTester tester, {
  Size taille = _bureau,
  double texte = 1,
  RoleSeance role = RoleSeance.enseignant,
  SituationTb situation = SituationTb.ped03,
}) async {
  fixerVueCapture(tester, taille, texte > 1 ? 2 : 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: role, situation: situation),
      echelleTexte: texte,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Les identifiants des traits passes au calque de la surface.
List<String> _traits(WidgetTester tester) => <String>[
  for (final trait
      in tester
          .widget<CoucheAnnotation>(find.byKey(SurfacePageFixe.cleCouche))
          .traits)
    trait.id,
];

/// La vue lue par la surface (page presentee, notes).
VueSeance _vue(WidgetTester tester) =>
    tester.widget<SurfacePageFixe>(find.byType(SurfacePageFixe)).vue;

/// Ouvre les Commandes puis le menu du titre.
Future<void> _ouvrirMenu(WidgetTester tester) async {
  if (_menu.evaluate().isEmpty) await _taper(tester, _declencheur);
  await _taper(tester, _menu);
}

/// Choisit « Ranger dans la bibliotheque » SANS attendre la fin du
/// mouvement : un seul cadre apres le toucher.
Future<void> _ranger(WidgetTester tester) async {
  await _ouvrirMenu(tester);
  await tester.tap(find.text(t.salle.seance.rangement.ranger).last);
  await tester.pump();
}

/// Bibliotheque > carte du support range (point de reprise) > Presenter.
Future<void> _reprendre(WidgetTester tester) async {
  if (_bibliotheque.evaluate().isEmpty) await _taper(tester, _declencheur);
  await _taper(tester, _bibliotheque);
  final Finder carte = find.descendant(
    of: _catalogue,
    matching: find.textContaining(
      t.salle.seance.rangement.reprise(page: 1, total: 1).split(' ').first,
    ),
  );
  expect(carte, findsWidgets);
  await _taper(tester, carte.first);
  await _taper(tester, _presenter);
}

const String _cercle = 'demo-trait-cercle';

void main() {
  // Les polices du depot, comme les captures : les lignes mesurees sont
  // celles que voit l'enseignant (a 320 x2 surtout).
  setUpAll(chargerPolicesDuDepot);

  for (final (Size taille, double texte) in <(Size, double)>[
    (_telephone, 1),
    (_bureau, 1),
    (_etroit, 2),
  ]) {
    final String cas = '${taille.width.toInt()} x${texte.toInt()}';

    testWidgets('UX-19 : ranger retire le support aussitot, sans '
        'confirmation ; le tableau libre revient, sans les notes du '
        'support ($cas)', (WidgetTester tester) async {
      await _monter(tester, taille: taille, texte: texte);
      expect(_page, findsOneWidget);
      expect(_traits(tester), <String>[_cercle]);
      await _ranger(tester);
      // L'etat a change au premier cadre, avant la fin du mouvement.
      expect(_copie, findsOneWidget);
      expect(_page, findsNothing);
      expect(_feuille, findsOneWidget);
      expect(_vue(tester).supportPresente, isNull);
      expect(_vue(tester).vueSurface, VueSurface.tableauLibre);
      // Les notes du support ne passent pas sur le tableau libre (TB5)...
      expect(_traits(tester), isEmpty);
      // ... et restent dans la seance, attachees a leur page.
      expect(<String>[
        for (final trait in _vue(tester).notesSurface) trait.id,
      ], contains(_cercle));
      // Aucune confirmation pour une action reversible.
      expect(find.byType(ConfirmDestructive), findsNothing);
      await tester.pumpAndSettle();
      expect(_copie, findsNothing);
      // Le retour discret de l'enseignant, dans les Commandes.
      expect(_range, findsOneWidget);
      expect(find.text(t.salle.seance.rangement.range), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('la copie part de la page et rejoint la Bibliotheque en '
      '180 a 250 ms', (WidgetTester tester) async {
    await _monter(tester);
    await _taper(tester, _declencheur);
    final Rect page = tester.getRect(_page);
    final Rect cible = tester.getRect(_bibliotheque);
    await _ouvrirMenu(tester);
    await tester.tap(find.text(t.salle.seance.rangement.ranger).last);
    await tester.pump();
    final Rect depart = tester.getRect(_copie);
    expect((depart.center - page.center).distance, lessThan(1));
    expect((depart.size.width - page.size.width).abs(), lessThan(1));
    expect(Mouvement.moyen.inMilliseconds, inInclusiveRange(180, 250));
    await tester.pump(Mouvement.moyen - const Duration(milliseconds: 20));
    final Rect presque = tester.getRect(_copie);
    // Presque arrivee : a moins d'un dixieme du trajet de la Bibliotheque,
    // reduite (au plus 1,2 fois sa hauteur), proportions gardees.
    final double trajet = (page.center - cible.center).distance;
    expect((presque.center - cible.center).distance, lessThan(trajet / 10));
    expect(presque.height, lessThanOrEqualTo(cible.height * 1.2));
    expect(
      presque.width / presque.height,
      closeTo(page.width / page.height, 0.02),
    );
    await tester.pump(const Duration(milliseconds: 40));
    expect(_copie, findsNothing);
  });

  testWidgets('UX-22 : mouvement reduit, aucune copie, meme etat', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _monter(tester);
    await _ranger(tester);
    expect(_copie, findsNothing);
    expect(_page, findsNothing);
    expect(_feuille, findsOneWidget);
    expect(_vue(tester).supportPresente, isNull);
    await tester.pump(Mouvement.moyen);
    expect(_copie, findsNothing);
  });

  testWidgets('UX-19 : Bibliotheque > carte rangee > Presenter restaure la '
      'page et les notes de la seance', (WidgetTester tester) async {
    await _monter(tester);
    await _ranger(tester);
    await tester.pumpAndSettle();
    await _taper(tester, _bibliotheque);
    // La section des ranges, en tete, et le point de reprise sur la carte.
    expect(
      find.descendant(
        of: _catalogue,
        matching: find.text(t.salle.seance.rangement.section),
      ),
      findsOneWidget,
    );
    final String reprise = t.salle.seance.rangement.reprise(
      page: 1,
      total: DonneesSeanceDemo.supportPageFixe.total,
    );
    final Finder point = find.descendant(
      of: _catalogue,
      matching: find.text(
        '$reprise ${t.salle.seance.rangement.notesConservees}',
      ),
    );
    expect(point, findsOneWidget);
    await _taper(tester, point);
    await _taper(tester, _presenter);
    expect(_page, findsOneWidget);
    final VueSeance vue = _vue(tester);
    expect(vue.supportPresente?.id, DonneesSeanceDemo.supportPageFixe.id);
    expect(vue.supportPresente?.page, 1);
    expect(vue.affichage, AffichagePartage.avecNotes);
    expect(_traits(tester), <String>[_cercle]);
    // Repris : il quitte les ranges, le retour discret s'efface.
    expect(vue.supportsRanges, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UX-19 : la page du rangement est le point de reprise', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _taper(tester, _declencheur);
    await _taper(tester, find.byKey(const ValueKey<String>('nav-suivant')));
    expect(_vue(tester).supportPresente?.page, 2);
    await _ranger(tester);
    await tester.pumpAndSettle();
    await _taper(tester, _bibliotheque);
    final Finder point = find.descendant(
      of: _catalogue,
      matching: find.text(
        t.salle.seance.rangement.reprise(
          page: 2,
          total: DonneesSeanceDemo.supportPageFixe.total,
        ),
      ),
    );
    // Les notes du support (page 1) sont conservees : la carte le dit
    // apres la page, jamais la page seule.
    expect(point, findsNothing);
    final Finder avecNotes = find.descendant(
      of: _catalogue,
      matching: find.textContaining(
        t.salle.seance.rangement.reprise(
          page: 2,
          total: DonneesSeanceDemo.supportPageFixe.total,
        ),
      ),
    );
    expect(avecNotes, findsOneWidget);
    await _taper(tester, avecNotes);
    await _taper(tester, _presenter);
    expect(_vue(tester).supportPresente?.page, 2);
    // Le cercle de la page 1 n'est pas peint sur la page 2 (§13)...
    expect(_traits(tester), isEmpty);
    // ... et revient a la page 1.
    await _taper(tester, _declencheur);
    await _taper(tester, find.byKey(const ValueKey<String>('nav-precedent')));
    expect(_traits(tester), <String>[_cercle]);
  });

  testWidgets('UX-18 : Tableau, puis Avec notes : meme page, memes traits, '
      'un clic', (WidgetTester tester) async {
    await _monter(tester);
    final int page = _vue(tester).supportPresente!.page;
    expect(_traits(tester), <String>[_cercle]);
    await _taper(tester, _declencheur);
    await _taper(
      tester,
      find.descendant(
        of: find.byKey(CommandesPedagogiques.cleAffichages),
        matching: find.text(t.salle.seance.commandes.affichageTableau),
      ),
    );
    expect(_page, findsNothing);
    expect(_traits(tester), <String>[_cercle]);
    // Fermer puis rouvrir les Commandes.
    await _taper(tester, find.text(t.salle.seance.commandes.reduire).last);
    await _taper(tester, _declencheur);
    await _taper(
      tester,
      find.descendant(
        of: find.byKey(CommandesPedagogiques.cleAffichages),
        matching: find.text(t.salle.seance.commandes.affichageAvecNotes),
      ),
    );
    expect(_page, findsOneWidget);
    expect(_vue(tester).supportPresente!.page, page);
    expect(_traits(tester), <String>[_cercle]);
  });

  for (final Size taille in <Size>[_telephone, _bureau]) {
    final String cas = '${taille.width.toInt()}';

    testWidgets('DLG-01 : effacer les notes de la page passe par '
        'ConfirmDestructive ; Annuler garde tout ($cas)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: taille, situation: SituationTb.dlg01);
      expect(_traits(tester), <String>[_cercle]);
      await _ouvrirMenu(tester);
      await _taper(tester, find.text(t.salle.seance.rangement.effacer).last);
      expect(find.byType(ConfirmDestructive), findsOneWidget);
      expect(find.text(t.salle.seance.rangement.questionPage), findsWidgets);
      expect(
        find.text(t.salle.seance.rangement.consequencePage),
        findsOneWidget,
      );
      await _taper(
        tester,
        find.widgetWithText(ActionPrincipale, t.commun.annuler),
      );
      expect(find.byType(ConfirmDestructive), findsNothing);
      expect(_traits(tester), <String>[_cercle]);
      await _ouvrirMenu(tester);
      await _taper(tester, find.text(t.salle.seance.rangement.effacer).last);
      await _taper(
        tester,
        find.widgetWithText(ActionPrincipale, t.salle.seance.rangement.effacer),
      );
      expect(_traits(tester), isEmpty);
      // Plus rien a effacer : l'entree disparait, ranger reste.
      await _ouvrirMenu(tester);
      expect(find.text(t.salle.seance.rangement.effacer), findsNothing);
      expect(find.text(t.salle.seance.rangement.ranger), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('§12 : effacer les notes du tableau libre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, situation: SituationTb.effacementTableau);
    expect(_traits(tester), <String>['demo-trait-tableau']);
    await _taper(tester, _declencheur);
    expect(find.text(t.salle.seance.rangement.tableauLibre), findsOneWidget);
    await _ouvrirMenu(tester);
    // Rien a ranger sans support.
    expect(find.text(t.salle.seance.rangement.ranger), findsNothing);
    await _taper(tester, find.text(t.salle.seance.rangement.effacer).last);
    expect(find.text(t.salle.seance.rangement.questionTableau), findsWidgets);
    await _taper(
      tester,
      find.widgetWithText(ActionPrincipale, t.salle.seance.rangement.effacer),
    );
    expect(_traits(tester), isEmpty);
    expect(find.text(t.salle.seance.rangement.tableauLibre), findsNothing);
    expect(_menu, findsNothing);
  });

  testWidgets('eleve : ni menu, ni « Support range », ni dialogue', (
    WidgetTester tester,
  ) async {
    await _monter(tester, role: RoleSeance.eleve);
    expect(_declencheur, findsNothing);
    expect(_menu, findsNothing);
    expect(find.text(t.salle.seance.rangement.range), findsNothing);
    expect(find.text(t.salle.seance.rangement.ranger), findsNothing);
    final VueSeance eleve =
        DonneesSeanceDemo.vueTb(RoleSeance.eleve, SituationTb.ped03).copyWith(
          supportsRanges: <SupportPageFixe>[DonneesSeanceDemo.supportPageFixe],
        );
    expect(eleve.voitRanger, isFalse);
    expect(eleve.voitEffacerNotes, isFalse);
  });

  testWidgets('K-07 : ranger puis reprendre depuis la vraie coquille', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterRouteur(
      tester,
      Routes.demoSalle,
      taille: _bureau,
    );
    final Finder lien = find.byKey(
      ValueKey<String>(
        'lien-${RoleSeance.enseignant.name}-tb-${SituationTb.ped03.name}',
      ),
    );
    await tester.ensureVisible(lien);
    await tester.pump();
    await tester.tap(lien);
    await tester.pumpAndSettle();
    expect(
      lieu(routeur),
      adresseDemoSalleTb(RoleSeance.enseignant, SituationTb.ped03),
    );
    await _ranger(tester);
    await tester.pumpAndSettle();
    expect(_page, findsNothing);
    expect(_feuille, findsOneWidget);
    await _reprendre(tester);
    expect(_page, findsOneWidget);
    expect(_traits(tester), <String>[_cercle]);
    expect(tester.takeException(), isNull);
  });
}
