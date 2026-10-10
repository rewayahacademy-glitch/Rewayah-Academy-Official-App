// TB-6 (PED-01 a PED-04 ; plan V2 §2, §3, §9, §12) : la surface a page
// fixe, ses trois affichages et le tableau libre.
//
// Page en `BoxFit.contain` (jamais etiree, ratio des donnees) ; Support :
// notes cachees, jamais demontees ; Avec notes ; Tableau : feuille claire au
// meme rectangle que la page. Masquer puis reafficher garde le calque. Page
// jamais inversee en sombre. Tableau libre : la phrase du §12 chez
// l'enseignant, rien de technique chez l'eleve.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart'
    show TraitVectoriel;
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../capture/outil_capture.dart' hide stabiliser;
import '../../router/support_routeur.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _feuille = find.byKey(SurfacePageFixe.cleFeuille);
final Finder _calque = find.byKey(SurfacePageFixe.cleCalque);
final Finder _consigne = find.byKey(SurfacePageFixe.cleConsigne);

final double _ratio = DonneesSeanceDemo.supportPageFixe.ratio;

Future<void> _monter(
  WidgetTester tester,
  RoleSeance role,
  SituationTb situation, {
  Size taille = _bureau,
  ThemeMode mode = ThemeMode.light,
  double texte = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: role, situation: situation),
      themeMode: mode,
      echelleTexte: texte,
    ),
  );
  await _attendre(tester);
}

Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

bool _calqueVisible(WidgetTester tester) =>
    tester.widget<Visibility>(find.byKey(SurfacePageFixe.cleCalque)).visible;

/// Les identifiants des traits que la couche d'annotation de la surface
/// recoit, donc peint quand le calque est visible.
List<String> _traitsPeints(WidgetTester tester) => <String>[
  for (final TraitVectoriel trait
      in tester
          .widget<CoucheAnnotation>(find.byKey(SurfacePageFixe.cleCouche))
          .traits)
    trait.id,
];

Finder _affichage(String libelle) => find.descendant(
  of: find.byKey(CommandesPedagogiques.cleAffichages),
  matching: find.text(libelle),
);

void main() {
  group('rectanglePage (BoxFit.contain, plan V2 §9.1)', () {
    for (final Size boite in <Size>[
      const Size(358, 500),
      const Size(700, 900),
      const Size(1000, 600),
      const Size(300, 900),
    ]) {
      test('ratio garde, centre, dans la boite $boite', () {
        final Rect r = rectanglePage(ratio: _ratio, boite: boite);
        expect(r.width / r.height, moreOrLessEquals(_ratio, epsilon: 1e-9));
        expect((Offset.zero & boite).contains(r.topLeft), isTrue);
        expect(r.right, lessThanOrEqualTo(boite.width + 1e-9));
        expect(r.bottom, lessThanOrEqualTo(boite.height + 1e-9));
        // Contain : un cote touche la boite, l'autre est centre.
        final bool largeur = (r.width - boite.width).abs() < 1e-6;
        final bool hauteur = (r.height - boite.height).abs() < 1e-6;
        expect(largeur || hauteur, isTrue);
        expect(r.center.dx, moreOrLessEquals(boite.width / 2, epsilon: 1e-6));
        expect(r.center.dy, moreOrLessEquals(boite.height / 2, epsilon: 1e-6));
      });
    }
  });

  group('Trois affichages (PED-02 a PED-04)', () {
    for (final Size taille in <Size>[_telephone, _bureau]) {
      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.enseignant,
        RoleSeance.eleve,
      ]) {
        final String cas = '${role.name} ${taille.width.toInt()}';
        testWidgets(
          'PED-03 Avec notes : page au ratio, calque visible ($cas)',
          (WidgetTester tester) async {
            await _monter(tester, role, SituationTb.ped03, taille: taille);
            expect(tester.takeException(), isNull);
            expect(_page, findsOneWidget);
            expect(_feuille, findsNothing);
            final Size s = tester.getSize(_page);
            expect(s.width / s.height, moreOrLessEquals(_ratio, epsilon: 0.01));
            expect(_calqueVisible(tester), isTrue);
            expect(_consigne, findsNothing);
          },
        );

        testWidgets('PED-02 Support : notes cachees, jamais demontees ($cas)', (
          WidgetTester tester,
        ) async {
          await _monter(tester, role, SituationTb.ped02, taille: taille);
          expect(_page, findsOneWidget);
          expect(_calque, findsOneWidget);
          expect(_calqueVisible(tester), isFalse);
        });

        testWidgets('PED-04 Tableau : feuille claire au rectangle de la page '
            '($cas)', (WidgetTester tester) async {
          await _monter(tester, role, SituationTb.ped03, taille: taille);
          final Rect page = tester.getRect(_page);
          await _monter(tester, role, SituationTb.ped04, taille: taille);
          expect(_page, findsNothing);
          expect(_feuille, findsOneWidget);
          expect(_calqueVisible(tester), isTrue);
          // Meme repere : la feuille occupe exactement le rectangle de la page.
          // Position comprise (revue du 09/10) : les quatre bords.
          final Rect feuille = tester.getRect(_feuille);
          expect(feuille.left, moreOrLessEquals(page.left, epsilon: 0.5));
          expect(feuille.top, moreOrLessEquals(page.top, epsilon: 0.5));
          expect(feuille.right, moreOrLessEquals(page.right, epsilon: 0.5));
          expect(feuille.bottom, moreOrLessEquals(page.bottom, epsilon: 0.5));
        });
      }
    }
  });

  group('Masquer puis reafficher garde le calque', () {
    testWidgets('Avec notes -> Tableau -> Support -> Avec notes', (
      WidgetTester tester,
    ) async {
      // Revue TB-6 : une situation qui PORTE un trait (le cercle de TB-7a,
      // PED-03), pour prouver « garde les traits », pas seulement le calque.
      await _monter(tester, RoleSeance.enseignant, SituationTb.ped03);
      if (_affichage(t.salle.seance.commandes.affichageTableau)
          .evaluate()
          .isEmpty) {
        await tester.tap(find.byKey(DeclencheurCommandes.cle));
        await _attendre(tester);
      }
      final List<String> traits = _traitsPeints(tester);
      expect(traits, contains(DonneesSeanceDemo.traitDemonstration.id));
      expect(_calqueVisible(tester), isTrue);
      final Element calque = tester.element(_calque);
      final Rect avant = tester.getRect(_calque);
      for (final (String libelle, bool page, bool visible)
          in <(String, bool, bool)>[
            (t.salle.seance.commandes.affichageTableau, false, true),
            (t.salle.seance.commandes.affichageSupport, true, false),
            (t.salle.seance.commandes.affichageAvecNotes, true, true),
          ]) {
        await tester.ensureVisible(_affichage(libelle));
        await tester.pump();
        await tester.tap(_affichage(libelle));
        await _attendre(tester);
        expect(_page, page ? findsOneWidget : findsNothing, reason: libelle);
        expect(_calqueVisible(tester), visible, reason: libelle);
        // Le meme calque, au meme endroit : rien n'est demonte ni deplace.
        expect(identical(tester.element(_calque), calque), isTrue);
        expect(tester.getRect(_calque), avant, reason: libelle);
        // Les memes traits, a chaque etape : caches en Support, jamais
        // effaces, peints de nouveau au retour.
        expect(_traitsPeints(tester), traits, reason: libelle);
      }
      // Au retour sur Avec notes, le cercle est peint : le calque est
      // visible et la couche le recoit.
      expect(_calqueVisible(tester), isTrue);
      expect(
        _traitsPeints(tester),
        contains(DonneesSeanceDemo.traitDemonstration.id),
      );
    });
  });

  group('La page suit la langue du document, pas l\'interface', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (String nom, Size taille, double texte)
        in <(String, Size, double)>[
          ('1440 x1', _bureau, 1),
          ('390 x1', _telephone, 1),
          ('320 x2', const Size(320, 700), 2),
        ]) {
      testWidgets('arabe (RTL), page francaise calee a gauche ($nom)', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          RoleSeance.enseignant,
          SituationTb.ped03,
          taille: taille,
          texte: texte,
        );
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(DemoSallePage))),
          TextDirection.rtl,
        );
        final Rect page = tester.getRect(_page);
        final SupportPageFixe support = DonneesSeanceDemo.supportPageFixe;
        for (final String ecrit in <String>[support.titre, support.mention!]) {
          final Rect r = tester.getRect(
            find.descendant(of: _page, matching: find.text(ecrit)),
          );
          // Au debut GAUCHE de la page : l'ecart a gauche est la marge, au
          // plus l'ecart a droite (le titre, le plus long, peut remplir la
          // largeur une fois reduit ; la mention, plus courte, laisse alors
          // tout le vide a droite).
          expect(
            r.left - page.left,
            lessThanOrEqualTo(page.right - r.right + 0.5),
            reason: ecrit,
          );
          expect(
            r.left - page.left,
            lessThanOrEqualTo(AppSpacing.lg + 1),
            reason: ecrit,
          );
        }
      });
    }

    test('sensDuDocument : premier caractere fort', () {
      expect(
        sensDuDocument(<String?>['Les bonnes manières']),
        TextDirection.ltr,
      );
      expect(sensDuDocument(<String?>[null, '1. الآداب']), TextDirection.rtl);
      expect(
        sensDuDocument(<String?>['12', 'سورة', 'Titre']),
        TextDirection.rtl,
      );
      expect(sensDuDocument(<String?>[]), TextDirection.ltr);
    });
  });

  group('Tableau libre (PED-01, plan V2 §12)', () {
    testWidgets('enseignant : la phrase du §12 sur la feuille', (
      WidgetTester tester,
    ) async {
      await _monter(tester, RoleSeance.enseignant, SituationTb.ped01);
      expect(tester.takeException(), isNull);
      expect(_feuille, findsOneWidget);
      expect(_page, findsNothing);
      expect(_consigne, findsOneWidget);
      expect(
        find.text('Choisissez un support ou écrivez au tableau.'),
        findsOneWidget,
      );
    });

    testWidgets('enseignant 390 x2 : la phrase lisible, rien ne la couvre', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        RoleSeance.enseignant,
        SituationTb.ped01,
        taille: _telephone,
        texte: 2,
      );
      expect(tester.takeException(), isNull);
      final Rect consigne = tester.getRect(_consigne);
      // La largeur de la surface, pas celle de la petite feuille (68 px).
      expect(consigne.width, greaterThan(200));
      expect(find.byType(VignetteVideo), findsNothing);
    });

    testWidgets('enseignant 390 x1 : la vignette en coin ne couvre pas la '
        'phrase', (WidgetTester tester) async {
      await _monter(
        tester,
        RoleSeance.enseignant,
        SituationTb.ped01,
        taille: _telephone,
      );
      final Rect consigne = tester.getRect(_consigne);
      // Le test mesure quelque chose : la vignette est bien posee.
      expect(find.byType(VignetteVideo), findsWidgets);
      for (final Element e in find.byType(VignetteVideo).evaluate()) {
        final Rect r = tester.getRect(find.byWidget(e.widget));
        expect(r.overlaps(consigne), isFalse);
      }
    });

    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.eleve,
      RoleSeance.guidee,
    ]) {
      testWidgets('${role.name} : le tableau, sans consigne technique', (
        WidgetTester tester,
      ) async {
        await _monter(tester, role, SituationTb.ped01, taille: _telephone);
        expect(tester.takeException(), isNull);
        expect(_feuille, findsOneWidget);
        expect(_consigne, findsNothing);
        expect(find.text(t.salle.seance.surface.aucunSupport), findsNothing);
      });
    }
  });

  group('Jamais inversee en sombre', () {
    for (final SituationTb s in <SituationTb>[
      SituationTb.ped03,
      SituationTb.ped04,
      SituationTb.ped01,
    ]) {
      testWidgets(s.name, (WidgetTester tester) async {
        await _monter(tester, RoleSeance.enseignant, s, mode: ThemeMode.dark);
        final Finder fond = s == SituationTb.ped03 ? _page : _feuille;
        expect(Theme.of(tester.element(fond)).brightness, Brightness.light);
        // L'ecran, lui, est bien en sombre.
        expect(
          Theme.of(tester.element(find.byType(DemoSallePage))).brightness,
          Brightness.dark,
        );
      });
    }
  });

  group('Texte a 200 % : la page garde son ratio', () {
    for (final Size taille in <Size>[const Size(320, 700), _bureau]) {
      testWidgets('${taille.width.toInt()}', (WidgetTester tester) async {
        await _monter(
          tester,
          RoleSeance.eleve,
          SituationTb.ped03,
          taille: taille,
          texte: 2,
        );
        expect(tester.takeException(), isNull);
        final Size s = tester.getSize(_page);
        expect(s.width / s.height, moreOrLessEquals(_ratio, epsilon: 0.01));
      });
    }
  });

  group('K-07 : depuis la vraie coquille', () {
    testWidgets('bureau : Tableau puis Avec notes', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.demoSalle,
        taille: _bureau,
      );
      final Finder lien = find.byKey(
        ValueKey<String>(
          'lien-${RoleSeance.enseignant.name}-tb-${SituationTb.cmd01.name}',
        ),
      );
      await tester.ensureVisible(lien);
      await tester.pump();
      await tester.tap(lien);
      await stabiliser(tester);
      expect(
        lieu(routeur),
        adresseDemoSalleTb(RoleSeance.enseignant, SituationTb.cmd01),
      );
      expect(_page, findsOneWidget);
      final Finder tableau = _affichage(
        t.salle.seance.commandes.affichageTableau,
      );
      await tester.ensureVisible(tableau);
      await tester.pump();
      await tester.tap(tableau);
      await _attendre(tester);
      expect(_feuille, findsOneWidget);
      expect(_page, findsNothing);
      final Finder notes = _affichage(
        t.salle.seance.commandes.affichageAvecNotes,
      );
      await tester.ensureVisible(notes);
      await tester.pump();
      await tester.tap(notes);
      await _attendre(tester);
      expect(_page, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
