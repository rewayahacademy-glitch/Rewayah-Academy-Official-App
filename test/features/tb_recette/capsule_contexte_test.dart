// TB-3 (UI-01, CTX-01, CTX-02) : la capsule compacte pendant le partage et
// le contexte de la seance (plan V2 §4.3, §19.6, §20 ; UX-10 a UX-12).
//
// Les parcours partent de la VRAIE coquille (`routeurProvider`), ouvrent
// /demo/salle, tapent le lien de la situation (K-07), puis tapent l'avatar,
// l'oeil, « Reduire » comme une personne. Les cas de rendu (enregistrement
// inactif ou inconnu, 150 %, RTL, 320 px a 200 %) montent la page que sert
// la meme route.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart'
    show TitreEnseignant;
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/capsule_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';

import '../../capture/outil_capture.dart'
    show chargerPolicesDuDepot, fixerVueCapture, hoteCapture;
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';

const Size _telephone = Size(390, 844);
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

final Finder _capsule = find.byKey(CapsuleSeance.cle);
final Finder _avatar = find.byKey(CapsuleSeance.cleAvatar);
final Finder _oeil = find.byKey(CapsuleSeance.cleOeil);
final Finder _contexte = find.byKey(SectionContexte.cle);
final Finder _reduire = find.byKey(SectionContexte.cleReduire);

/// La vignette video posee sur la surface (coin, pile ou colonne).
Finder get _vignetteSurSupport => find.descendant(
  of: find.byType(ZoneSupport),
  matching: find.byKey(const ValueKey<String>('vignette-video')),
);

const String _nom = 'Sayyid Ibrahim';

void main() {
  group(
    'UI-01 / UX-10 : pendant le partage, la capsule remplace la vignette',
    () {
      for (final RoleSeance role in RoleSeance.values) {
        testWidgets(role.name, (WidgetTester tester) async {
          await _ouvrir(tester, role, SituationTb.ui01);
          expect(_capsule, findsOneWidget);
          expect(_vignetteSurSupport, findsNothing);
          // Ni nom, ni reseau, ni video dans la capsule (les initiales du
          // cercle seulement).
          for (final String interdit in <String>[
            _nom,
            t.salle.seance.contexte.reseau,
            t.salle.seance.enLigne,
          ]) {
            expect(
              find.descendant(of: _capsule, matching: find.text(interdit)),
              findsNothing,
            );
          }
          expect(
            find.descendant(
              of: _capsule,
              matching: find.byKey(const ValueKey<String>('vignette-video')),
            ),
            findsNothing,
          );
          // Pas d'oeil sans donnee de controle (TB-BR-24) ; aucun temoin
          // d'enregistrement, meme en demonstration (A-01, 17/10/2026).
          expect(_oeil, findsNothing);
          expect(
            find.descendant(
              of: _capsule,
              matching: find.byType(PointEnregistrement),
            ),
            findsNothing,
          );
          // Rien n'est deplie au depart.
          expect(_contexte, findsNothing);
        });
      }
    },
  );

  group('Hors partage, la vignette actuelle reste', () {
    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.eleve,
      RoleSeance.guidee,
    ]) {
      testWidgets('${role.name} : tableau libre (PED-01), aucune capsule', (
        WidgetTester tester,
      ) async {
        await _ouvrir(tester, role, SituationTb.ped01);
        expect(_capsule, findsNothing);
        expect(
          find.byKey(const ValueKey<String>('vignette-video')),
          findsOneWidget,
        );
      });
    }
    testWidgets('etat anterieur sans support presente : vignette, aucune '
        'capsule', (WidgetTester tester) async {
      await _monter(
        tester,
        const DemoSallePage(role: RoleSeance.eleve, etat: EtatDemoSalle.repos),
      );
      expect(_capsule, findsNothing);
      expect(_vignetteSurSupport, findsOneWidget);
    });
  });

  group(
    'CTX-01 / UX-11 : l\'avatar deplie le contexte, « Reduire » revient',
    () {
      for (final RoleSeance role in RoleSeance.values) {
        for (final Size taille in <Size>[_telephone, _bureau]) {
          testWidgets('${role.name} ${taille.width.toInt()}', (
            WidgetTester tester,
          ) async {
            await _ouvrir(tester, role, SituationTb.ui01, taille: taille);
            await tester.tap(_avatar);
            await stabiliser(tester);
            expect(_contexte, findsOneWidget);
            // Le contexte normal : le nom et le reseau, sans enregistrement.
            expect(
              find.descendant(of: _contexte, matching: find.text(_nom)),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: _contexte,
                matching: find.text(t.salle.seance.contexte.reseau),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: _contexte,
                matching: find.byType(PointEnregistrement),
              ),
              findsNothing,
            );
            // Aucun controle fabrique : pas de donnee, pas de section.
            expect(find.byKey(SectionContexte.cleControle), findsNothing);
            expect(
              find.text(t.salle.seance.contexte.controleActif),
              findsNothing,
            );
            if (role == RoleSeance.enseignant) {
              // Le panneau de personnes existant, une seule gestion.
              expect(
                find.descendant(
                  of: find.byKey(const ValueKey<String>('panneau-eleves')),
                  matching: _contexte,
                ),
                findsOneWidget,
              );
            } else {
              expect(find.text(t.salle.seance.contexte.titre), findsOneWidget);
            }
            await tester.ensureVisible(_reduire);
            await tester.pump();
            await tester.tap(_reduire);
            await stabiliser(tester);
            expect(_contexte, findsNothing);
            expect(_capsule, findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    },
  );

  testWidgets('Reseau : le detail est atteignable depuis le contexte de '
      'l\'enseignant (TB-2 l\'a sorti du dock)', (WidgetTester tester) async {
    await _ouvrir(tester, RoleSeance.enseignant, SituationTb.ctx01);
    final Finder detail = find.byKey(
      const ValueKey<String>('contexte-detail-reseau'),
    );
    expect(detail, findsOneWidget);
    await tester.ensureVisible(detail);
    await tester.pump();
    await tester.tap(detail);
    await stabiliser(tester);
    // La feuille du reseau s'ouvre, titre « Reseau ».
    expect(find.text(t.salle.seance.reseau), findsWidgets);
    expect(find.text(t.salle.seance.enLigne), findsWidgets);
  });

  testWidgets('Reseau : l\'eleve n\'a pas le detail du reseau', (
    WidgetTester tester,
  ) async {
    await _ouvrir(tester, RoleSeance.eleve, SituationTb.ctx01);
    expect(_contexte, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('contexte-detail-reseau')),
      findsNothing,
    );
  });

  group('CTX-02 : l\'oeil ouvre le meme panneau, a la section controle', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        await _ouvrir(tester, role, SituationTb.ctx02);
        // La situation s'ouvre a la section controle ; on la reduit, puis
        // l'oeil la rouvre.
        expect(find.byKey(SectionContexte.cleControle), findsOneWidget);
        await tester.ensureVisible(_reduire);
        await tester.pump();
        await tester.tap(_reduire);
        await stabiliser(tester);
        expect(_contexte, findsNothing);
        expect(_oeil, findsOneWidget);
        await tester.tap(_oeil);
        await stabiliser(tester);
        final Finder controle = find.byKey(SectionContexte.cleControle);
        expect(controle, findsOneWidget);
        // Amenee dans la partie visible de l'ecran.
        final Rect r = tester.getRect(controle);
        expect(r.top, lessThan(_telephone.height));
        expect(r.bottom, greaterThan(0));
        // « Controle possible », jamais « Controle actif » fabrique ; un
        // controle possible ne dit pas que quelqu'un observe.
        expect(
          find.text(t.salle.seance.contexte.controlePossible),
          findsOneWidget,
        );
        expect(
          find.text(t.salle.seance.contexte.controlePossibleDetail),
          findsOneWidget,
        );
        expect(find.text(t.salle.seance.contexte.controleActif), findsNothing);
        // L'oeil n'a rien declenche : aucune notice de visite chez
        // quiconque (CTRL-SALLE-1, aucun controleur dans cette salle).
        expect(find.text(t.salle.seance.votreParentObserve), findsNothing);
        expect(find.text(t.salle.seance.tonParentObserve), findsNothing);
      });
    }
  });

  group('CTX-02 : l\'oeil fait defiler la liste du panneau jusqu\'a la '
      'section controle, et elle seule (320 px, texte x2)', () {
    setUpAll(chargerPolicesDuDepot);
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        const Size petit = Size(320, 660);
        await _monter(
          tester,
          DemoSallePage(role: role, situation: SituationTb.ctx02),
          taille: petit,
          texte: 2,
        );
        final Finder liste = find.byKey(
          ValueKey<String>(
            role == RoleSeance.enseignant
                ? 'panneau-eleves'
                : 'panneau-contexte',
          ),
        );
        final Finder controle = find.byKey(SectionContexte.cleControle);
        ScrollableState defilement(Finder f) => tester.state<ScrollableState>(
          find.descendant(of: f, matching: find.byType(Scrollable)).first,
        );
        final Finder panneau = find.byType(PanneauSeance);

        // Le panneau garde sa tete a l'ecran : aucun Scrollable ancetre de la
        // liste n'a defile (le panneau entier defile a 320 px x2).
        void teteVisible() {
          final Finder entier = find.byKey(
            const ValueKey<String>('panneau-seance-defile'),
          );
          if (entier.evaluate().isNotEmpty) {
            expect(
              tester
                  .state<ScrollableState>(
                    find
                        .descendant(
                          of: entier,
                          matching: find.byType(Scrollable),
                        )
                        .first,
                  )
                  .position
                  .pixels,
              0,
              reason: 'le panneau entier a defile : sa tete sort de l\'ecran',
            );
          }
          expect(tester.getRect(panneau.first).top, greaterThanOrEqualTo(0));
        }

        // Ouverte par la situation (a la section controle).
        expect(controle, findsOneWidget);
        expect(defilement(liste).position.pixels, greaterThan(0));
        teteVisible();

        Future<void> reduire() async {
          // Comme une personne : la liste defile jusqu'au bout, « Reduire »
          // s'arrete au-dessus de la barre de l'appel (texte x2 : la barre
          // se pose par-dessus le contenu).
          // La liste de l'enseignant (panneau Eleves) est paresseuse : le
          // contexte est sa premiere rangee, « Reduire » y est amene.
          if (role == RoleSeance.enseignant) {
            await tester.ensureVisible(_reduire);
          } else {
            final ScrollPosition p = defilement(liste).position;
            p.jumpTo(p.maxScrollExtent);
          }
          await tester.pump();
          await tester.tap(_reduire);
          await stabiliser(tester);
          expect(_contexte, findsNothing);
          // Tout ce qui reste ouvert revient en haut : le cas suivant part
          // d'une liste non defilee.
          for (final Element e in find.byType(Scrollable).evaluate()) {
            final ScrollableState etat =
                (e as StatefulElement).state as ScrollableState;
            if (etat.position.hasPixels && etat.position.pixels != 0) {
              etat.position.jumpTo(0);
            }
          }
          await tester.pump();
        }

        // L'avatar ouvre le contexte en haut : la section du controle est
        // hors de la partie visible de la liste (sans defilement, elle n'y
        // serait pas).
        await reduire();
        // TB-RC (revue TB-R M2, TB_RAPPORT §d n. 1) : a 320 x2, la tete
        // bornee defile en fondu ; on l'amene comme une personne.
        await tester.ensureVisible(_avatar);
        await tester.pump();
        await tester.tap(_avatar);
        await stabiliser(tester);
        expect(_contexte, findsOneWidget);
        expect(defilement(liste).position.pixels, 0);
        // Sans la ligne d'enregistrement (A-01), le panneau guide est assez
        // court pour que la section tienne a l'ecran sans defilement.
        if (role != RoleSeance.guidee) {
          expect(
            tester.getRect(controle).top,
            greaterThanOrEqualTo(tester.getRect(liste).bottom - 1),
            reason: 'precondition : la section doit etre hors de vue',
          );
        }

        // L'oeil : la meme liste defile jusqu'a la section, rien d'autre.
        await reduire();
        await tester.ensureVisible(_oeil);
        await tester.pump();
        await tester.tap(_oeil);
        await stabiliser(tester);
        expect(_contexte, findsOneWidget);
        expect(defilement(liste).position.pixels, greaterThan(0));
        final Rect vue = tester.getRect(liste);
        final Rect r = tester.getRect(controle);
        expect(r.top, greaterThanOrEqualTo(vue.top - 1));
        expect(r.top, lessThan(vue.bottom));
        teteVisible();
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('Echap reduit le contexte et rend le focus a l\'avatar', (
    WidgetTester tester,
  ) async {
    await _ouvrir(
      tester,
      RoleSeance.enseignant,
      SituationTb.ui01,
      taille: _bureau,
    );
    await tester.tap(_avatar);
    await stabiliser(tester);
    expect(_contexte, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await stabiliser(tester);
    expect(_contexte, findsNothing);
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    expect(focus?.debugLabel, 'capsule-avatar');
  });

  group('A-01 : aucun point d\'enregistrement, quel que soit l\'etat', () {
    test('la vue : jamais de point', () {
      for (final EtatEnregistrement e in EtatEnregistrement.values) {
        final VueSeance v = DonneesSeanceDemo.vueTb(
          RoleSeance.eleve,
          SituationTb.ui01,
          enregistrement: e,
        );
        expect(v.voitPointEnregistrement, isFalse, reason: e.name);
      }
    });
    for (final RoleSeance role in RoleSeance.values) {
      for (final EtatEnregistrement e in EtatEnregistrement.values) {
        testWidgets('${role.name} ${e.name} : capsule sans point, contexte '
            'sans enregistrement', (WidgetTester tester) async {
          await _monter(
            tester,
            DemoSallePage(
              role: role,
              situation: SituationTb.ctx01,
              enregistrement: e,
            ),
          );
          expect(_capsule, findsOneWidget);
          expect(
            find.descendant(
              of: _capsule,
              matching: find.byType(PointEnregistrement),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: _contexte,
              matching: find.byType(PointEnregistrement),
            ),
            findsNothing,
          );
          expect(find.bySemanticsLabel('Enregistrement actif'), findsNothing);
        });
      }
    }
    testWidgets('par la route : &enr=inconnu, aucun point', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        '${adresseDemoSalleTb(RoleSeance.eleve, SituationTb.ui01)}&enr=inconnu',
      );
      await stabiliser(tester);
      expect(_capsule, findsOneWidget);
    });
  });

  group('§20 : noms accessibles, cibles de 48', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        final SemanticsHandle lecteur = tester.ensureSemantics();
        await _ouvrir(tester, role, SituationTb.ctx02);
        expect(
          find.bySemanticsLabel('Afficher les informations de $_nom'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Contrôle possible. Afficher les informations'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Contrôle actif. Afficher les informations'),
          findsNothing,
        );
        expect(find.bySemanticsLabel('Enregistrement actif'), findsNothing);
        // « Reduire » visible, nom lu selon le panneau.
        await tester.ensureVisible(_reduire);
        await tester.pump();
        expect(
          find.bySemanticsLabel(
            role == RoleSeance.enseignant
                ? 'Réduire les participants'
                : 'Réduire les informations',
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _reduire, matching: find.text('Réduire')),
          findsOneWidget,
        );
        for (final Finder cible in <Finder>[_avatar, _oeil, _reduire]) {
          final Size s = tester.getSize(cible);
          expect(s.width, greaterThanOrEqualTo(48), reason: '$cible');
          expect(s.height, greaterThanOrEqualTo(48), reason: '$cible');
        }
        lecteur.dispose();
      });
    }
    testWidgets('Sayyida : le titre suit le profil', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle lecteur = tester.ensureSemantics();
      await _monter(
        tester,
        const DemoSallePage(
          role: RoleSeance.eleve,
          situation: SituationTb.ui01,
          titre: TitreEnseignant.sayyida,
        ),
      );
      expect(
        find.bySemanticsLabel(
          'Afficher les informations de '
          '${DonneesSeanceDemo.enseignantPour(TitreEnseignant.sayyida)}',
        ),
        findsOneWidget,
      );
      lecteur.dispose();
    });
  });

  group(
    'A6 = a, pile a 150 % : le support en haut, fixe ; la vignette apres',
    () {
      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
      ]) {
        testWidgets('${role.name}, etat sans partage presente : la vignette '
            'suit le texte', (WidgetTester tester) async {
          await _monter(
            tester,
            DemoSallePage(role: role, etat: EtatDemoSalle.repos),
            texte: 1.5,
          );
          final Finder pile = find.byKey(
            const ValueKey<String>('vignette-support-pile'),
          );
          expect(pile, findsOneWidget);
          final Finder chapitre = find.descendant(
            of: find.byType(ZoneSupport),
            matching: find.textContaining('Chapitre'),
          );
          expect(chapitre, findsWidgets);
          final Rect carte = tester.getRect(
            find.byKey(const ValueKey<String>('zone-support')),
          );
          final Rect titre = tester.getRect(chapitre.first);
          // Le texte est en tete de la carte, la vignette ne le precede pas.
          expect(titre.top, lessThan(tester.getRect(pile).top));
          expect(titre.top - carte.top, lessThan(64));
        });
        testWidgets('${role.name}, pendant le partage : aucune vignette sur le '
            'support, la capsule est dans l\'en-tete', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            DemoSallePage(role: role, situation: SituationTb.ui01),
            texte: 1.5,
          );
          expect(_vignetteSurSupport, findsNothing);
          expect(
            find.byKey(const ValueKey<String>('vignette-support-pile')),
            findsNothing,
          );
          final Rect carte = tester.getRect(
            find.byKey(const ValueKey<String>('zone-support')),
          );
          expect(tester.getRect(_capsule).bottom, lessThanOrEqualTo(carte.top));
        });
      }
    },
  );

  testWidgets('MA : la notice d\'observation de l\'enfant reste visible avec '
      'la capsule', (WidgetTester tester) async {
    await _monter(
      tester,
      const DemoSallePage(
        role: RoleSeance.guidee,
        situation: SituationTb.ui01,
        etat: EtatDemoSalle.visite,
      ),
    );
    expect(_capsule, findsOneWidget);
    expect(find.text(t.salle.seance.tonParentObserve), findsOneWidget);
  });

  group('RTL, 320 px, texte x2 : rien ne deborde, aucun mot coupe', () {
    // Les polices du depot : la mesure des mots est celle de l'appareil.
    setUpAll(chargerPolicesDuDepot);
    for (final RoleSeance role in RoleSeance.values) {
      for (final (Size, double, TextDirection) cas
          in <(Size, double, TextDirection)>[
            (const Size(320, 660), 1, TextDirection.ltr),
            (const Size(320, 660), 2, TextDirection.ltr),
            (const Size(320, 660), 2, TextDirection.rtl),
            (_telephone, 2, TextDirection.rtl),
            (_bureau, 2, TextDirection.ltr),
          ]) {
        testWidgets('${role.name} ${cas.$1.width.toInt()} x${cas.$2.toInt()} '
            '${cas.$3.name}', (WidgetTester tester) async {
          await _monter(
            tester,
            DemoSallePage(role: role, situation: SituationTb.ctx02),
            taille: cas.$1,
            texte: cas.$2,
            sens: cas.$3,
          );
          expect(tester.takeException(), isNull, reason: 'debordement');
          for (final Finder f in <Finder>[_avatar, _oeil]) {
            final Rect r = tester.getRect(f);
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(cas.$1.width));
            expect(r.width, greaterThanOrEqualTo(48));
          }
          verifierAucunMotCoupe(tester, _contexte);
          verifierAucunMotCoupe(tester, _capsule);
          if (role != RoleSeance.enseignant) {
            // Le titre du panneau : ni coupe, ni points de suspension.
            verifierAucunMotCoupe(tester, find.byType(PanneauSeance));
          }
        });
      }
    }
  });
}
