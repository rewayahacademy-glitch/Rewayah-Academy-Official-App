// TB-11a (plan V2 §5 tableau des profils, UX-21) : le tuteur observateur et
// le controleur lisent la presentation de l'enseignant (support, page,
// affichage, notes) dans la VRAIE salle `/salle` (`SallePage`), en lecture
// seule.
//
// 1. K-07 : chaque lien nouveau de /demo/salle (observateur x situation)
//    s'ouvre par le VRAI routeur et monte la vraie salle de l'observateur.
// 2. Par role (tuteur, controleur), au rendu : la surface partagee
//    (`ZoneSupport`, `SurfacePageFixe`) est montee, dans l'ecran, avec la
//    page et l'affichage de la situation ; AUCUNE commande d'ecriture, de
//    page ou de rangement : aucun widget touchable dans la presentation,
//    exactement les memes commandes qu'en l'absence de presentation, aucun
//    widget de pagination, de zoom, d'affichage, d'outil ou de bibliotheque.
// 3. Les notices restent celles du role : la mention « Cours enregistre,
//    visite de controle possible » n'est jamais montree au controleur ;
//    le tuteur garde la sienne et son rappel.
// 4. SALLE-200-1/2 avec presentation : 320 et 390, texte x1 et x2, la
//    salle tient, « Quitter » reste a l'ecran, le titre n'est pas coupe.
// 5. CT-3 sur tablette (900 et 1100 px) : la liste de presence du controleur
//    se lit (contraste de chaque texte sur le fond REELLEMENT peint sous lui)
//    et tient dans l'ecran sans defiler, avec ou sans presentation.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/barre_precedent_suivant.dart';
import 'package:rewayah_academy/core/widgets/ligne_presence.dart';
import 'package:rewayah_academy/core/widgets/page_immersive.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/salle_controleur_demo.dart';
import 'package:rewayah_academy/features/demo/salle_observateur_demo.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/outils_enseignement.dart';
import 'package:rewayah_academy/features/salle_seance/presentation_observee.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../capture/outil_capture.dart' hide stabiliser;
import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import '../../theme/support/contraste.dart';

const Key _presentation = ValueKey<String>('presentation-lue');

const List<SituationTb> _avecPresentation = <SituationTb>[
  SituationTb.ped01,
  SituationTb.ped02,
  SituationTb.ped03,
  SituationTb.ped04,
];

/// Monte la salle de [o] dans [s] (la page que sert
/// `/demo/salle?obs=…&tb=…`).
Future<void> _monter(
  WidgetTester tester,
  ObservateurDemo o,
  SituationTb s, {
  Size taille = const Size(390, 844),
  double texte = 1,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(observateur: o, situation: s),
      echelleTexte: texte,
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
}

/// Les widgets touchables montes (tout bouton passe par `Pressable`).
int _touchables() => find.byType(Pressable).evaluate().length;

/// Le libelle de sortie du role (zone haute du controleur, commandes du
/// tuteur).
Finder _quitter(ObservateurDemo o) => o == ObservateurDemo.controleur
    ? find.bySemanticsLabel(RegExp(t.salle.quitter))
    : find.bySemanticsLabel(RegExp(t.salle.quitterLeCours));

/// La couleur peinte sous [e] : la premiere surface opaque de ses ancetres.
Color _fondSous(Element e) {
  Color? fond;
  e.visitAncestorElements((Element a) {
    final Widget w = a.widget;
    final Color? c = switch (w) {
      DecoratedBox(decoration: final BoxDecoration d) => d.color,
      ColoredBox(:final Color color) => color,
      Material(:final Color? color, :final MaterialType type)
          when type != MaterialType.transparency =>
        color,
      Scaffold(:final Color? backgroundColor) => backgroundColor,
      _ => null,
    };
    if (c != null && c.a == 1) {
      fond = c;
      return false;
    }
    return true;
  });
  return fond!;
}

/// L'encre reellement posee sur un paragraphe rendu.
Color _encre(RenderParagraph p) {
  Color? encre;
  p.text.visitChildren((InlineSpan s) {
    final Color? c = s.style?.color;
    if (c != null) {
      encre = c;
      return false;
    }
    return true;
  });
  return encre!;
}

void main() {
  group('K-07 : chaque lien observateur s\'ouvre par le vrai routeur', () {
    for (final ObservateurDemo o in ObservateurDemo.values) {
      for (final SituationTb s in situationsObservateur) {
        testWidgets('${o.name} ${s.name}', (WidgetTester tester) async {
          final GoRouter routeur = await monterRouteur(
            tester,
            Routes.demoSalle,
            taille: const Size(1440, 900),
          );
          final Finder lien = find.byKey(
            ValueKey<String>('lien-obs-${o.name}-tb-${s.name}'),
          );
          await tester.ensureVisible(lien);
          await tester.pump();
          await tester.tap(lien);
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          expect(lieu(routeur), adresseDemoSalleObservateur(o, s));
          expect(
            find.byKey(ValueKey<String>('obs-${o.name}-tb-${s.name}')),
            findsOneWidget,
          );
          // La presentation lue n'existe que s'il y a quelque chose de
          // presente (SAL-00 : la scene, comme avant).
          expect(
            find.byKey(_presentation),
            s == SituationTb.sal00 ? findsNothing : findsOneWidget,
          );
          expect(_quitter(o), findsWidgets);
        });
      }
    }

    testWidgets('une situation sans objet pour l\'observateur ramene a la '
        'liste', (WidgetTester tester) async {
      await monterRouteur(
        tester,
        Uri(
          path: Routes.demoSalle,
          queryParameters: <String, String>{'obs': 'tuteur', 'tb': 'cmd01'},
        ).toString(),
        taille: const Size(1440, 900),
      );
      expect(find.byKey(_presentation), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('lien-obs-tuteur-tb-sal00')),
        findsOneWidget,
      );
    });
  });

  group('Lecture seule, par role', () {
    for (final ObservateurDemo o in ObservateurDemo.values) {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final SituationTb s in _avecPresentation) {
          testWidgets('${o.name} ${s.name} $nom : la presentation, aucune '
              'commande', (WidgetTester tester) async {
            // Le meme role sans presentation : ses commandes de reference.
            await _monter(tester, o, SituationTb.sal00, taille: taille);
            final int reference = _touchables();
            expect(reference, greaterThan(0), reason: 'Quitter au moins');
            expect(find.byKey(_presentation), findsNothing);

            await _monter(tester, o, s, taille: taille);
            expect(tester.takeException(), isNull);

            // La surface partagee est montee, dans l'ecran.
            final Finder zone = find.descendant(
              of: find.byKey(_presentation),
              matching: find.byType(ZoneSupport),
            );
            expect(zone, findsOneWidget);
            final Rect r = tester.getRect(zone);
            expect(r.left, greaterThanOrEqualTo(-0.5));
            expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
            expect(r.height, greaterThan(100), reason: 'surface de $r');
            final Finder surface = find.descendant(
              of: zone,
              matching: find.byType(SurfacePageFixe),
            );
            expect(surface, findsOneWidget);

            // Page, affichage et notes de la situation.
            final bool page = s == SituationTb.ped02 || s == SituationTb.ped03;
            expect(
              find.byKey(SurfacePageFixe.clePage),
              page ? findsOneWidget : findsNothing,
            );
            expect(
              find.byKey(SurfacePageFixe.cleFeuille),
              page ? findsNothing : findsOneWidget,
            );
            expect(
              tester
                  .widget<Visibility>(find.byKey(SurfacePageFixe.cleCalque))
                  .visible,
              s != SituationTb.ped02,
              reason: 'notes cachees en Support seulement',
            );
            final Finder indicateur = find.byType(IndicateurPage);
            if (s == SituationTb.ped01) {
              expect(indicateur, findsNothing);
            } else {
              final IndicateurPage i = tester.widget(indicateur);
              expect(i.page, 3);
              expect(i.pages, DonneesSeanceDemo.supportPageFixe.total);
              expect(
                find.text(DonneesSeanceDemo.supportPageFixe.titre),
                findsWidgets,
              );
            }
            // Ni consigne de l'enseignant, ni vignette posee sur la page.
            expect(find.byKey(SurfacePageFixe.cleConsigne), findsNothing);
            expect(
              find.descendant(
                of: find.byKey(_presentation),
                matching: find.byType(VignetteVideo),
              ),
              findsNothing,
            );

            // AUCUNE commande : rien de touchable dans la presentation, et
            // exactement les commandes du role sans presentation.
            expect(
              find.descendant(
                of: find.byKey(_presentation),
                matching: find.byType(Pressable),
              ),
              findsNothing,
            );
            expect(_touchables(), reference);
            for (final Type interdit in <Type>[
              PaginationSupport,
              BarrePrecedentSuivant,
              ZoomLocal,
              DeclencheurCommandes,
              CommandesPedagogiques,
              OutilsEnseignement,
              BarreStylet,
              CoucheAnnotation,
              BibliothequeSeance,
            ]) {
              expect(find.byType(interdit), findsNothing, reason: '$interdit');
            }
            for (final String mot in <String>[
              t.salle.seance.commandes.declencheur,
              t.salle.seance.commandes.affichageAvecNotes,
              t.salle.seance.commandes.bibliotheque,
              t.salle.seance.commandes.focus,
            ]) {
              expect(find.text(mot), findsNothing, reason: mot);
            }
            verifierUnSeulBoutonPlein(tester);
            expect(_quitter(o), findsWidgets);
          });
        }
      }
    }
  });

  group('Notices du role', () {
    for (final SituationTb s in <SituationTb>[
      SituationTb.ped01,
      SituationTb.ped03,
    ]) {
      testWidgets('controleur ${s.name} : pas de mention de visite, son '
          'rappel', (WidgetTester tester) async {
        await _monter(tester, ObservateurDemo.controleur, s);
        expect(find.byKey(_presentation), findsOneWidget);
        expect(find.byType(PermanentNotice), findsNothing);
        expect(find.text(t.salle.bandeauPermanent), findsNothing);
        expect(find.textContaining(t.salle.bandeauControleTitre), findsWidgets);
      });

      testWidgets('tuteur ${s.name} : la mention et son rappel', (
        WidgetTester tester,
      ) async {
        await _monter(tester, ObservateurDemo.tuteur, s);
        expect(find.byKey(_presentation), findsOneWidget);
        expect(find.byType(PermanentNotice), findsOneWidget);
        expect(
          find.textContaining(t.salle.observationMuetteTitre),
          findsWidgets,
        );
      });
    }
  });

  group('SALLE-200-1/2 avec presentation : la salle tient', () {
    for (final ObservateurDemo o in ObservateurDemo.values) {
      for (final double largeur in <double>[320, 390]) {
        for (final double texte in <double>[1, 2]) {
          testWidgets('${o.name} ped03, $largeur px, texte x$texte', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              o,
              SituationTb.ped03,
              taille: Size(largeur, 844),
              texte: texte,
            );
            expect(tester.takeException(), isNull);
            final Rect contenu = tester.getRect(
              find.byKey(PageImmersive.contenuKey),
            );
            expect(contenu.height, greaterThanOrEqualTo(844 / 2));
            final Finder quitter = _quitter(o);
            expect(quitter, findsWidgets);
            final Rect zone = tester.getRect(quitter.first);
            expect(zone.left, greaterThanOrEqualTo(-0.5));
            expect(zone.right, lessThanOrEqualTo(largeur + 0.5));
            expect(zone.bottom, lessThanOrEqualTo(844.5));
            // Le titre du support (la ligne au-dessus de la surface, la page
            // neutre le repete), dans l'ecran et non rogne.
            final Finder titre = find.descendant(
              of: find.descendant(
                of: find.byKey(_presentation),
                matching: find.byType(Wrap),
              ),
              matching: find.text(DonneesSeanceDemo.supportPageFixe.titre),
            );
            expect(titre, findsOneWidget);
            final Rect rt = tester.getRect(titre);
            expect(rt.left, greaterThanOrEqualTo(-0.5));
            expect(rt.right, lessThanOrEqualTo(largeur + 0.5));
            final RenderParagraph p = tester.renderObject(titre);
            expect(p.didExceedMaxLines, isFalse);
            // SUPERPOS-1 : a texte x1, la scene tient sous la presentation,
            // aucune tuile ne passe sous le rappel du role (le bandeau).
            if (texte == 1) {
              final Rect tuile = tester.getRect(
                find.byKey(const ValueKey<String>('demo-enseignant')),
              );
              final Rect rappel = tester.getRect(
                find
                    .textContaining(
                      o == ObservateurDemo.controleur
                          ? t.salle.bandeauControle
                          : t.salle.observationMuette,
                    )
                    .first,
              );
              expect(
                tuile.bottom,
                lessThanOrEqualTo(rappel.top),
                reason: 'tuile $tuile sous le rappel $rappel',
              );
            }
            verifierSansChevauchement(tester, <Finder>[
              find.byType(IndicateurPage),
              find.byType(ZoneSupport),
            ]);
          });
        }
      }
    }
  });

  group('CT-3 sur tablette : la presence du controleur se lit', () {
    for (final Size taille in <Size>[
      const Size(900, 1200),
      const Size(1100, 700),
    ]) {
      for (final SituationTb s in <SituationTb>[
        SituationTb.sal00,
        SituationTb.ped01,
        SituationTb.ped03,
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          testWidgets('controleur ${s.name}, ${taille.width.toInt()} px, '
              '${mode.name}', (WidgetTester tester) async {
            await _monter(
              tester,
              ObservateurDemo.controleur,
              s,
              taille: taille,
              mode: mode,
            );
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(_presentation),
              s == SituationTb.sal00 ? findsNothing : findsOneWidget,
            );
            final Finder entete = find.byWidgetPredicate(
              (Widget w) => w is SectionHeader && w.titre == t.presence.titre,
            );
            expect(entete, findsOneWidget);
            final Finder lignes = find.byType(LignePresence);
            expect(lignes, findsWidgets);
            // Chaque texte de la liste, au rendu : son encre sur le fond peint
            // sous lui, au seuil AA.
            final Finder textes = find.descendant(
              of: find
                  .ancestor(of: entete, matching: find.byType(Column))
                  .first,
              matching: find.byType(RichText),
            );
            expect(textes.evaluate().length, greaterThanOrEqualTo(3));
            for (final Element e in textes.evaluate()) {
              final RenderParagraph p = e.renderObject! as RenderParagraph;
              final double r = contraste(_encre(p), _fondSous(e));
              expect(
                r,
                greaterThanOrEqualTo(seuilTexte),
                reason: '« ${p.text.toPlainText()} » a $r:1',
              );
            }
            // La liste tient dans l'ecran sans un geste : l'en-tete et la
            // derniere ligne sont dans la fenetre.
            for (final Rect r in <Rect>[
              tester.getRect(entete),
              tester.getRect(lignes.last),
            ]) {
              expect(r.top, greaterThanOrEqualTo(-0.5));
              expect(r.bottom, lessThanOrEqualTo(taille.height + 0.5));
              expect(r.left, greaterThanOrEqualTo(-0.5));
              expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
            }
            if (s != SituationTb.sal00) {
              final Rect zone = tester.getRect(find.byType(ZoneSupport));
              expect(
                tester.getRect(entete).left,
                greaterThanOrEqualTo(zone.right - 0.5),
                reason: 'colonne laterale, pas sous la scene',
              );
            }
          });
        }
      }
    }
  });

  group('DepuisSalle.presentationObservee', () {
    VueSalle salle(String role) => VueSalle.depuis(
      materielPret: true,
      acces: accesControleurDemo(role: role),
      etatMoteur: EtatSalle.connecte,
      participants: const <ParticipantSalle>[],
      qualite: QualiteLien.bonne,
    );

    test('null hors des deux observateurs, ou sans presentation', () {
      final PresentationObservee p = presentationObserveeDemo(
        SituationTb.ped03,
      )!;
      for (final String role in <String>['teacher', 'student']) {
        expect(
          DepuisSalle.presentationObservee(salle: salle(role), presentation: p),
          isNull,
          reason: role,
        );
      }
      expect(
        DepuisSalle.presentationObservee(
          salle: salle('guardian_observer'),
          presentation: null,
        ),
        isNull,
      );
      expect(
        DepuisSalle.presentationObservee(
          salle: salle('masked_controller'),
          presentation: const PresentationObservee(),
        ),
        isNull,
      );
    });

    test('la vue de lecture ferme tout ce que la surface ajouterait', () {
      for (final String role in <String>[
        'guardian_observer',
        'masked_controller',
      ]) {
        final VueSeance v = DepuisSalle.presentationObservee(
          salle: salle(role),
          presentation: presentationObserveeDemo(SituationTb.ped02),
        )!;
        expect(v.voitConsigneTableauLibre, isFalse);
        expect(v.voitVignetteSurSupport, isFalse);
        expect(v.texteMention, isNull);
        expect(v.visiteVisible, isFalse);
        expect(v.panneau, PanneauOuvert.aucun);
        expect(v.vueSurface, VueSurface.supportSeul);
        expect(surfaceAMontrer(v), VueSurface.supportSeul);
      }
    });
  });
}
