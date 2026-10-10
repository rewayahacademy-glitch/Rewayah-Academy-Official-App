// TB-4 (CMD-01) : le declencheur « Commandes » et le panneau pedagogique de
// l'enseignant (plan V2 §4.2, §6, §18.3, §20 ; decision TB-Q1 = a, deux
// onglets « Support » et « Outils »).
//
// Les parcours partent de la VRAIE coquille (`routeurProvider`), ouvrent
// /demo/salle, tapent le lien de la situation puis le declencheur, comme une
// personne (K-07). Les cas de rendu (RTL, 320 px a 200 %) et les rappels
// comptes montent la page ou la salle que sert la meme route.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/capsule_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart'
    show chargerPolicesDuDepot, fixerVueCapture, hoteCapture;
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';

const Size _telephone = Size(390, 844);
const Size _tablette = Size(768, 1024);
const Size _bureau = Size(1440, 900);

/// Ouvre la salle de la situation depuis la liste de /demo/salle.
Future<GoRouter> _ouvrir(
  WidgetTester tester,
  RoleSeance role,
  SituationTb situation, {
  Size taille = _telephone,
}) async {
  final GoRouter routeur = await monterRouteur(
    tester,
    Routes.demoSalle,
    taille: taille,
  );
  final Finder lien = find.byKey(
    ValueKey<String>('lien-${role.name}-tb-${situation.name}'),
  );
  await tester.ensureVisible(lien);
  await tester.pump();
  await tester.tap(lien);
  await stabiliser(tester);
  expect(lieu(routeur), adresseDemoSalleTb(role, situation));
  expect(tester.takeException(), isNull);
  return routeur;
}

Future<void> _monter(
  WidgetTester tester,
  Widget page, {
  Size taille = _telephone,
  double texte = 1,
  TextDirection sens = TextDirection.ltr,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      Directionality(textDirection: sens, child: page),
      echelleTexte: texte,
    ),
  );
  await stabiliser(tester);
}

/// Un geste, puis le cadre du retour du focus et l'animation.
Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);
final Finder _contenu = find.byKey(CommandesPedagogiques.cle);
final Finder _bibliotheque = find.byKey(CommandesPedagogiques.cleBibliotheque);
final Finder _affichages = find.byKey(CommandesPedagogiques.cleAffichages);
final Finder _onglets = find.byKey(CommandesPedagogiques.cleOnglets);
final Finder _pagination = find.byKey(
  const ValueKey<String>('pagination-support'),
);

Finder _dans(Finder parent, String texte) =>
    find.descendant(of: parent, matching: find.text(texte));

/// L'affichage selectionne dans le choix groupe.
AffichagePartage _affichageChoisi(WidgetTester tester) => tester
    .widget<ControleSegmente<AffichagePartage>>(
      find.descendant(
        of: _affichages,
        matching: find.byType(ControleSegmente<AffichagePartage>),
      ),
    )
    .valeur;

String? _focus() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  group('K-07 : le declencheur ouvre le panneau depuis la vraie coquille', () {
    for (final (String nom, Size taille, FormePanneau forme)
        in <(String, Size, FormePanneau)>[
          ('telephone : feuille', _telephone, FormePanneau.feuille),
          ('tablette : volet', _tablette, FormePanneau.volet),
          ('bureau : panneau droit', _bureau, FormePanneau.colonne),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await _ouvrir(
          tester,
          RoleSeance.enseignant,
          SituationTb.ped03,
          taille: taille,
        );
        // Ferme : un seul declencheur, aucun outil permanent (§4.2).
        expect(_declencheur, findsOneWidget);
        expect(_contenu, findsNothing);
        expect(
          find.byKey(const ValueKey<String>('outils-rangee')),
          findsNothing,
        );
        expect(_pagination, findsNothing);
        await tester.tap(_declencheur);
        await _attendre(tester);
        expect(tester.takeException(), isNull);
        expect(_contenu, findsOneWidget);
        final Finder cadre = find.ancestor(
          of: _contenu,
          matching: find.byKey(
            ValueKey<String>('panneau-seance-${forme.name}'),
          ),
        );
        expect(cadre, findsOneWidget);
        expect(
          find.descendant(
            of: cadre,
            matching: find.text(t.salle.seance.commandes.titre),
          ),
          findsOneWidget,
        );
        // Deux onglets (TB-Q1 = a) ; aucun onglet Visio.
        expect(
          _dans(_onglets, t.salle.seance.commandes.ongletSupport),
          findsOneWidget,
        );
        expect(
          _dans(_onglets, t.salle.seance.commandes.ongletOutils),
          findsOneWidget,
        );
        // La Bibliotheque en tete, puis le support, les affichages, la
        // page, la Lecture, l'Affichage (Focus).
        final List<double> ordre = <double>[
          for (final Finder f in <Finder>[
            _onglets,
            _bibliotheque,
            find.byKey(CommandesPedagogiques.cleSupport),
            _affichages,
            _pagination,
            find.byKey(CommandesPedagogiques.cleLecture),
            find.byKey(CommandesPedagogiques.cleFocus),
          ])
            tester.getTopLeft(f).dy,
        ];
        for (int i = 1; i < ordre.length; i++) {
          expect(ordre[i], greaterThan(ordre[i - 1]), reason: 'rang $i');
        }
        // Page {numero} sur {total} (§20), en entier.
        expect(
          _dans(_pagination, t.salle.seance.pageSemantique(page: 1, pages: 12)),
          findsOneWidget,
        );
        if (forme != FormePanneau.feuille) {
          // Panneau droit : au bord de fin de l'ecran.
          final Rect r = tester.getRect(cadre);
          expect(r.center.dx, greaterThan(taille.width / 2));
          if (forme == FormePanneau.colonne) {
            // Bureau : a cote du support, jamais par-dessus.
            expect(
              r.left,
              greaterThan(
                tester
                    .getRect(find.byKey(const ValueKey<String>('zone-support')))
                    .right,
              ),
            );
          }
        }
        // « Reduire » ferme (plan V2 §20) et rend le focus au declencheur.
        await tester.tap(find.byKey(PanneauSeance.cleReduire));
        await _attendre(tester);
        expect(_contenu, findsNothing);
        expect(_focus(), 'declencheur-commandes');
      });
    }
  });

  group('Echap ferme le panneau et rend le focus au declencheur', () {
    for (final Size taille in <Size>[_telephone, _tablette, _bureau]) {
      testWidgets('${taille.width.toInt()}', (WidgetTester tester) async {
        await _ouvrir(
          tester,
          RoleSeance.enseignant,
          SituationTb.ped03,
          taille: taille,
        );
        await tester.tap(_declencheur);
        await _attendre(tester);
        expect(_contenu, findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await _attendre(tester);
        expect(_contenu, findsNothing);
        expect(_declencheur, findsOneWidget);
        expect(_focus(), 'declencheur-commandes');
        // Echap ne coupe jamais l'appel : la salle reste.
        expect(find.byType(SalleSeance), findsOneWidget);
      });
    }
  });

  group('Un clic par affichage (TB3)', () {
    testWidgets('depuis CMD-01 : Tableau, Support, Avec notes', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, RoleSeance.enseignant, SituationTb.cmd01);
      expect(_contenu, findsOneWidget);
      expect(_affichageChoisi(tester), AffichagePartage.avecNotes);
      for (final (String libelle, AffichagePartage attendu)
          in <(String, AffichagePartage)>[
            (
              t.salle.seance.commandes.affichageTableau,
              AffichagePartage.tableau,
            ),
            (
              t.salle.seance.commandes.affichageSupport,
              AffichagePartage.support,
            ),
            (
              t.salle.seance.commandes.affichageAvecNotes,
              AffichagePartage.avecNotes,
            ),
          ]) {
        await tester.tap(_dans(_affichages, libelle));
        await tester.pump();
        expect(_affichageChoisi(tester), attendu, reason: libelle);
      }
    });

    testWidgets('un toucher = un seul rappel, avec la bonne valeur', (
      WidgetTester tester,
    ) async {
      final List<AffichagePartage> journal = <AffichagePartage>[];
      final VueSeance vue = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.cmd01,
      );
      await _monter(
        tester,
        SalleSeance(
          vue: vue,
          actions: ActionsSeance(
            onCommandes: () {},
            onAffichage: journal.add,
            onQuitter: () {},
          ),
        ),
      );
      await tester.tap(
        _dans(_affichages, t.salle.seance.commandes.affichageTableau),
      );
      await tester.pump();
      expect(journal, <AffichagePartage>[AffichagePartage.tableau]);
    });

    testWidgets('sans support presente, aucun affichage ni page', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, RoleSeance.enseignant, SituationTb.ped01);
      await tester.tap(_declencheur);
      await _attendre(tester);
      expect(_contenu, findsOneWidget);
      expect(_bibliotheque, findsOneWidget);
      expect(_affichages, findsNothing);
      expect(_pagination, findsNothing);
      // TB-7b (plan V2 §12, « Aucun support » : « Bibliotheque, Ecrire
      // cote enseignant ») : le tableau libre prend des notes, l'onglet
      // Outils porte Ecrire.
      expect(_onglets, findsOneWidget);
      await tester.tap(_dans(_onglets, t.salle.seance.commandes.ongletOutils));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('outil-ecrire')),
        findsOneWidget,
      );
    });
  });

  group('Page : un clic, le texte suit (demonstration)', () {
    testWidgets('Page suivante puis Page precedente', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, RoleSeance.enseignant, SituationTb.cmd01);
      // A la premiere page, pas de fleche precedente (NAV-FLECHES-1).
      expect(find.byKey(const ValueKey<String>('nav-precedent')), findsNothing);
      // TB-RC (M7) : la ligne « La classe voit… » descend la pagination ;
      // comme une personne, on l'amene dans la vue.
      await tester.ensureVisible(_pagination);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('nav-suivant')));
      await tester.pump();
      expect(
        _dans(_pagination, t.salle.seance.pageSemantique(page: 2, pages: 12)),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey<String>('nav-precedent')));
      await tester.pump();
      expect(
        _dans(_pagination, t.salle.seance.pageSemantique(page: 1, pages: 12)),
        findsOneWidget,
      );
    });
  });

  group('Outils : Pointeur en tete, jamais permanents', () {
    testWidgets('onglet Outils', (WidgetTester tester) async {
      await _ouvrir(tester, RoleSeance.enseignant, SituationTb.cmd01);
      // Onglet Support : aucun outil.
      expect(
        find.byKey(const ValueKey<String>('outil-pointeur')),
        findsNothing,
      );
      await tester.tap(_dans(_onglets, t.salle.seance.commandes.ongletOutils));
      await tester.pump();
      final Finder pointeur = find.byKey(
        const ValueKey<String>('outil-pointeur'),
      );
      expect(pointeur, findsOneWidget);
      for (final String autre in <String>[
        'outil-ecrire',
        'outil-marquer',
        'outil-masquer',
      ]) {
        expect(
          tester.getTopLeft(pointeur).dx,
          lessThan(tester.getTopLeft(find.byKey(ValueKey<String>(autre))).dx),
          reason: autre,
        );
      }
      // TB-7b : les outils d'ecriture n'apparaissent que sous « Ecrire »
      // (plan V2 §4.2, « sous-barre seulement apres Ecrire »).
      for (final String absent in <String>[
        'Stylo',
        'Surligner',
        'Gomme',
        'Terminer',
      ]) {
        expect(find.text(absent), findsNothing, reason: absent);
      }
      // L'onglet Support revient.
      await tester.tap(_dans(_onglets, t.salle.seance.commandes.ongletSupport));
      await tester.pump();
      expect(_bibliotheque, findsOneWidget);
      expect(pointeur, findsNothing);
    });
  });

  group('Telephone : un seul panneau secondaire, la visio reste (§18.3)', () {
    testWidgets('le contexte remplace les Commandes', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, RoleSeance.enseignant, SituationTb.cmd01);
      expect(_contenu, findsOneWidget);
      await tester.tap(find.byKey(CapsuleSeance.cleAvatar));
      await _attendre(tester);
      expect(find.byKey(SectionContexte.cle), findsOneWidget);
      expect(_contenu, findsNothing);
      // Reduire le contexte : les Commandes ne reviennent pas d'elles-memes.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _attendre(tester);
      expect(find.byKey(SectionContexte.cle), findsNothing);
      expect(_contenu, findsNothing);
      // Commandes depuis le contexte ouvert : le contexte se replie.
      await tester.tap(find.byKey(CapsuleSeance.cleAvatar));
      await _attendre(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _attendre(tester);
      await tester.tap(_declencheur);
      await _attendre(tester);
      expect(_contenu, findsOneWidget);
      expect(find.byKey(SectionContexte.cle), findsNothing);
    });

    testWidgets('UX-07 : panneau ouvert, Quitter reste activable', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, RoleSeance.enseignant, SituationTb.cmd01);
      expect(_contenu, findsOneWidget);
      final Finder quitter = find.descendant(
        of: find.byKey(CommandesMasquables.commandesKey),
        matching: find.text(t.salle.quitter),
      );
      expect(quitter, findsOneWidget);
      // La feuille s'arrete au-dessus de la barre de l'appel.
      expect(
        tester
            .getRect(
              find.byKey(const ValueKey<String>('panneau-seance-feuille')),
            )
            .bottom,
        lessThanOrEqualTo(tester.getRect(quitter).top),
      );
      await tester.tap(quitter);
      await _attendre(tester);
      expect(find.text(t.salle.seance.quitterQuestion), findsOneWidget);
    });
  });

  group('Focus : un clic, la sortie reste atteignable', () {
    testWidgets('bureau', (WidgetTester tester) async {
      await _ouvrir(
        tester,
        RoleSeance.enseignant,
        SituationTb.cmd01,
        taille: _bureau,
      );
      final Finder focus = find.byKey(CommandesPedagogiques.cleFocus);
      expect(_dans(focus, t.salle.seance.commandes.focus), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('bouton-agrandir')),
        findsNothing,
      );
      await tester.ensureVisible(focus);
      await tester.pump();
      await tester.tap(focus);
      await _attendre(tester);
      // TB-5 (UX-14) : Focus replie les deux cotes, Commandes compris ; la
      // sortie reste dans la barre de l'appel (« Reduire ») et dans les
      // Commandes, que le declencheur rouvre seules (UX-15).
      expect(find.byType(PanneauEleves), findsNothing);
      expect(_contenu, findsNothing);
      expect(
        find.byKey(const ValueKey<String>('bouton-agrandir')),
        findsOneWidget,
      );
      await tester.tap(_declencheur);
      await _attendre(tester);
      expect(find.byType(PanneauEleves), findsNothing);
      expect(
        _dans(focus, t.salle.seance.commandes.quitterFocus),
        findsOneWidget,
      );
      await tester.ensureVisible(focus);
      await tester.pump();
      await tester.tap(focus);
      await _attendre(tester);
      // UX-16 : la composition d'avant revient (Participants, Commandes).
      expect(_dans(focus, t.salle.seance.commandes.focus), findsOneWidget);
      expect(find.byType(PanneauEleves), findsOneWidget);
    });
  });

  group('Rien de l\'enseignant chez l\'eleve (TB14, par role)', () {
    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.eleve,
      RoleSeance.guidee,
    ]) {
      for (final SituationTb situation in <SituationTb>[
        SituationTb.ped03,
        SituationTb.ped04,
        SituationTb.cmd01,
        SituationTb.ui01,
      ]) {
        for (final Size taille in <Size>[_telephone, _bureau]) {
          testWidgets(
            '${role.name} ${situation.name} ${taille.width.toInt()}',
            (WidgetTester tester) async {
              await _ouvrir(tester, role, situation, taille: taille);
              // TB-10 (plan V2 §19.3 point 4) : l'eleve a ses Commandes,
              // qui ne montrent que la lecture et le focus (sans
              // autorisation, pas d'Ecrire) ; rien de l'enseignant.
              expect(_declencheur, findsOneWidget);
              expect(_contenu, findsNothing);
              await tester.ensureVisible(_declencheur);
              await tester.tap(_declencheur);
              await _attendre(tester);
              expect(_contenu, findsOneWidget);
              expect(_pagination, findsNothing);
              expect(
                find.byKey(CommandesPedagogiques.cleOnglets),
                findsNothing,
              );
              expect(
                find.byKey(CommandesPedagogiques.cleEcritureEleve),
                findsNothing,
              );
              for (final String texte in <String>[
                t.salle.seance.commandes.bibliotheque,
                t.salle.seance.commandes.affichageAvecNotes,
                t.salle.seance.commandes.affichageTableau,
                t.salle.seance.outils.pointeur,
                t.salle.seance.outils.ecrire,
                t.salle.seance.supports,
                t.salle.seance.pageSemantique(page: 1, pages: 12),
              ]) {
                expect(find.text(texte), findsNothing, reason: texte);
              }
              // Echap reduit les Commandes de l'eleve, jamais l'appel.
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              await _attendre(tester);
              expect(_contenu, findsNothing);
              expect(find.byType(SalleSeance), findsOneWidget);
            },
          );
        }
      }
    }
  });

  group('Declencheur rendu seulement s\'il mene a quelque chose', () {
    testWidgets('aucune entree : aucun declencheur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SalleSeance(
          vue: DonneesSeanceDemo.vueTb(
            RoleSeance.enseignant,
            SituationTb.ped01,
          ),
          actions: ActionsSeance(onCommandes: () {}, onQuitter: () {}),
        ),
      );
      expect(_declencheur, findsNothing);
    });

    testWidgets('sans rappel Commandes : aucun declencheur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SalleSeance(
          vue: DonneesSeanceDemo.vueTb(
            RoleSeance.enseignant,
            SituationTb.ped03,
          ),
          actions: ActionsSeance(
            onSupports: () {},
            onAffichage: (AffichagePartage _) {},
            onQuitter: () {},
          ),
        ),
      );
      expect(_declencheur, findsNothing);
    });
  });

  group('RTL : chevrons et noms des pages', () {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets(sens.name, (WidgetTester tester) async {
        await _monter(
          tester,
          const DemoSallePage(
            role: RoleSeance.enseignant,
            situation: SituationTb.cmd01,
          ),
          sens: sens,
        );
        // TB-RC (M7) : la pagination est amenee dans la vue.
        await tester.ensureVisible(_pagination);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey<String>('nav-suivant')));
        await tester.pump();
        final Finder precedent = find.byKey(
          const ValueKey<String>('nav-precedent'),
        );
        final Finder suivant = find.byKey(
          const ValueKey<String>('nav-suivant'),
        );
        final bool rtl = sens == TextDirection.rtl;
        // « Page precedente » au debut de la ligne : a droite en arabe.
        expect(
          tester.getCenter(precedent).dx > tester.getCenter(suivant).dx,
          rtl,
        );
        // Le glyphe pointe vers la fin du sens de lecture pour « suivante ».
        bool retourne(Finder f) =>
            tester
                .widget<Transform>(
                  find
                      .descendant(of: f, matching: find.byType(Transform))
                      .first,
                )
                .transform
                .storage[0] <
            0;
        expect(retourne(suivant), rtl);
        expect(retourne(precedent), !rtl);
        // Les noms lus des fleches et le texte de la page.
        expect(
          find.bySemanticsLabel(t.salle.seance.pagePrecedente),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(t.salle.seance.pageSuivante),
          findsOneWidget,
        );
        expect(
          _dans(_pagination, t.salle.seance.pageSemantique(page: 2, pages: 12)),
          findsOneWidget,
        );
      });
    }

    testWidgets('bureau RTL : le panneau au bord de fin (a gauche)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const DemoSallePage(
          role: RoleSeance.enseignant,
          situation: SituationTb.cmd01,
        ),
        taille: _bureau,
        sens: TextDirection.rtl,
      );
      final Rect panneau = tester.getRect(
        find.ancestor(
          of: _contenu,
          matching: find.byKey(
            const ValueKey<String>('panneau-seance-colonne'),
          ),
        ),
      );
      final Rect support = tester.getRect(
        find.byKey(const ValueKey<String>('zone-support')),
      );
      expect(panneau.right, lessThan(support.left));
    });
  });

  group('200 %, 320 px : rien ne deborde, aucun mot coupe', () {
    setUpAll(chargerPolicesDuDepot);
    for (final (Size, double, TextDirection) cas
        in <(Size, double, TextDirection)>[
          (const Size(320, 700), 1, TextDirection.ltr),
          (const Size(320, 700), 2, TextDirection.ltr),
          (const Size(320, 700), 2, TextDirection.rtl),
          (_telephone, 2, TextDirection.ltr),
          (_tablette, 2, TextDirection.ltr),
          (_bureau, 2, TextDirection.ltr),
        ]) {
      testWidgets('${cas.$1.width.toInt()} x${cas.$2.toInt()} ${cas.$3.name}', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          const DemoSallePage(
            role: RoleSeance.enseignant,
            situation: SituationTb.cmd01,
          ),
          taille: cas.$1,
          texte: cas.$2,
          sens: cas.$3,
        );
        expect(tester.takeException(), isNull, reason: 'debordement');
        expect(_contenu, findsOneWidget);
        // Chaque entree se laisse atteindre en faisant defiler le panneau.
        for (final Finder f in <Finder>[
          _bibliotheque,
          _affichages,
          _pagination,
          find.byKey(CommandesPedagogiques.cleFocus),
        ]) {
          await tester.scrollUntilVisible(
            f,
            40,
            scrollable: find
                .descendant(of: _contenu, matching: find.byType(Scrollable))
                .first,
          );
          final Rect r = tester.getRect(f);
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(cas.$1.width));
        }
        expect(tester.takeException(), isNull);
        verifierAucunMotCoupe(tester, find.byType(PanneauSeance));
      });
    }
  });
}
