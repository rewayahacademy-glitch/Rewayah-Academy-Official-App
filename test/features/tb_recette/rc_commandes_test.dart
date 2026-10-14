// TB-RC, lot L2-commandes : les constats de la revue croisee TB-R
// (05_recette/TB/REVUE_TB-R.md) et du rapport de recette (TB_RAPPORT §d)
// sur le panneau « Commandes ». Chaque test mesure le RENDU (rectangles,
// focus, textes poses, arbre semantique), pas un parametre.
//
// M4 (ordre de tabulation), M7 (ce que voit la classe, K-58), m1 (un seul
// nom du focus), m2 (Interface guidee : pictogramme et mot), m3 (largeur au
// texte agrandi), m4 et n. 21 (chevron seulement s'il reste du contenu),
// m8 (le fondu ne cache pas le focus et disparait en bas), m9 (focus apres
// Ranger), m13 (pas de « non selectionne » sur le declencheur), n. 2 et
// n. 10 (indice visible quand la feuille ou le volet est coupe), n. 9 (rien
// ne depasse de la pagination).

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/bouton_outil.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart'
    show chargerPolicesDuDepot, fixerVueCapture, hoteCapture;

const Size _telephone = Size(390, 844);
const Size _etroit = Size(320, 700);
const Size _tablette = Size(768, 1024);
const Size _bureau = Size(1440, 900);

final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);
final Finder _contenu = find.byKey(CommandesPedagogiques.cle);
final Finder _pagination = find.byKey(
  const ValueKey<String>('pagination-support'),
);

Future<void> _monter(
  WidgetTester tester, {
  Size taille = _bureau,
  double texte = 1,
  RoleSeance role = RoleSeance.enseignant,
  bool ouvrir = true,
}) async {
  fixerVueCapture(tester, taille, 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: role, situation: SituationTb.ped03),
      echelleTexte: texte,
    ),
  );
  await tester.pumpAndSettle();
  if (!ouvrir) return;
  await tester.ensureVisible(_declencheur);
  await tester.pumpAndSettle();
  await tester.tap(_declencheur);
  await tester.pumpAndSettle();
  expect(_contenu, findsOneWidget);
}

/// Le cadre du panneau qui porte les Commandes.
Finder _cadre() => find.ancestor(
  of: _contenu,
  matching: find.byWidgetPredicate(
    (Widget w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('panneau-seance-'),
  ),
);

/// Le contexte du focus courant, s'il est sous [parent].
bool _focusSous(Finder parent) {
  final BuildContext? c = FocusManager.instance.primaryFocus?.context;
  if (c == null) return false;
  final Element racine = parent.evaluate().single;
  bool dedans = false;
  (c as Element).visitAncestorElements((Element e) {
    if (identical(e, racine)) {
      dedans = true;
      return false;
    }
    return true;
  });
  return dedans || identical(c, racine);
}

/// Le haut du focus dans la colonne des Commandes (defilement compris).
double _dansColonne(WidgetTester tester) =>
    _rectFocus(tester).center.dy -
    tester
        .getTopLeft(
          find
              .descendant(
                of: find.byKey(CommandesPedagogiques.cleDefilement),
                matching: find.byType(Column),
              )
              .first,
        )
        .dy;

/// Le noeud de l'entree Bibliotheque (celui que pose le panneau).
FocusNode _noeudBibliotheque(WidgetTester tester) => tester
    .widget<Focus>(
      find
          .descendant(
            of: find.byKey(CommandesPedagogiques.cleBibliotheque),
            matching: find.byType(Focus),
          )
          .first,
    )
    .focusNode!;

Rect _rectFocus(WidgetTester tester) {
  final RenderBox boite =
      FocusManager.instance.primaryFocus!.context!.findRenderObject()!
          as RenderBox;
  return boite.localToGlobal(Offset.zero) & boite.size;
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('M4 : Tab parcourt les Commandes sans en sortir, dans l\'ordre', () {
    for (final (String nom, Size taille) in <(String, Size)>[
      ('bureau, colonne', _bureau),
      ('telephone, feuille', _telephone),
    ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await _monter(tester, taille: taille);
        final Finder cadre = _cadre();
        expect(cadre, findsOneWidget);
        // Depart : la Bibliotheque, premiere entree du contenu.
        final FocusNode depart = _noeudBibliotheque(tester);
        depart.requestFocus();
        await tester.pump();
        final List<FocusNode> premierTour = <FocusNode>[];
        double precedent = _dansColonne(tester);
        bool focusAtteint = false;
        for (int i = 0; i < 30; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          expect(
            _focusSous(cadre),
            isTrue,
            reason:
                'Tab ${i + 1} : hors du panneau, sur '
                '${FocusManager.instance.primaryFocus?.context?.widget.toStringShort()} '
                '${FocusManager.instance.primaryFocus?.debugLabel} '
                'apres ${premierTour.map((FocusNode f) => f.context?.widget.toStringShort()).toList()}',
          );
          if (!_focusSous(_contenu)) break;
          final FocusNode n = FocusManager.instance.primaryFocus!;
          premierTour.add(n);
          // L'ordre suit la colonne : jamais un retour vers le haut.
          final double ici = _dansColonne(tester);
          expect(ici, greaterThanOrEqualTo(precedent - 0.5));
          precedent = ici;
          if (_focusSous(find.byKey(CommandesPedagogiques.cleFocus))) {
            focusAtteint = true;
            break;
          }
        }
        // La derniere commande, Focus, est atteinte sans sortir du panneau.
        expect(focusAtteint, isTrue, reason: 'Focus atteint au Tab');
        expect(premierTour.length, greaterThanOrEqualTo(4));
        // Le second tour suit le premier (meme suite de noeuds).
        depart.requestFocus();
        await tester.pump();
        for (final FocusNode attendu in premierTour) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus, same(attendu));
        }
      });
    }
  });

  testWidgets('M7 : sous les affichages, ce que voit la classe', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    final Finder ligne = find.byKey(CommandesPedagogiques.cleClasseVoit);
    expect(ligne, findsOneWidget);
    expect(
      tester.getTopLeft(ligne).dy,
      greaterThanOrEqualTo(
        tester
            .getBottomLeft(find.byKey(CommandesPedagogiques.cleAffichages))
            .dy,
      ),
    );
    expect(
      tester.widget<Text>(ligne).data,
      t.salle.seance.commandes.classeVoitAvecNotes,
    );
    // Un choix change la ligne : « Support » dit que les notes sont cachees.
    await tester.tap(
      find.descendant(
        of: find.byKey(CommandesPedagogiques.cleAffichages),
        matching: find.text(t.salle.seance.commandes.affichageSupport),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(ligne).data,
      t.salle.seance.commandes.classeVoitSupport,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(CommandesPedagogiques.cleAffichages),
        matching: find.text(t.salle.seance.commandes.affichageTableau),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(ligne).data,
      t.salle.seance.commandes.classeVoitTableau,
    );
  });

  group('m1 : un seul nom du focus, vu et lu, aux deux endroits', () {
    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.enseignant,
      RoleSeance.eleve,
    ]) {
      testWidgets(role.name, (WidgetTester tester) async {
        final SemanticsHandle lecteur = tester.ensureSemantics();
        await _monter(tester, role: role);
        final Finder focus = find.byKey(CommandesPedagogiques.cleFocus);
        expect(
          find.descendant(
            of: focus,
            matching: find.text(t.salle.seance.commandes.focus),
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(focus);
        await tester.tap(focus);
        await tester.pumpAndSettle();
        // En focus : la bascule de la barre garde son mot d'etat « Focus »
        // (une ligne, ETATS-BTN-1) et se lit « Quitter le focus » ; plus
        // aucun « Reduire » ni « Agrandir » pour elle.
        final Finder sortie = find.byWidgetPredicate(
          (Widget w) =>
              w.key == const ValueKey<String>('bouton-agrandir') ||
              w.key == const ValueKey<String>('bouton-agrandir-barre'),
        );
        expect(sortie, findsWidgets);
        for (final Element e in sortie.evaluate()) {
          final Finder f = find.byWidget(e.widget);
          expect(
            find.descendant(
              of: f,
              matching: find.text(t.salle.seance.commandes.focus),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: f, matching: find.text(t.salle.seance.reduire)),
            findsNothing,
          );
          final String lu = tester.getSemantics(f).label;
          expect(lu, contains(t.salle.seance.commandes.quitterFocus));
          expect(lu, isNot(contains(t.salle.seance.agrandir)));
          expect(lu, isNot(contains(t.salle.seance.reduire)));
        }
        lecteur.dispose();
      });
    }
  });

  testWidgets('m2 : Interface guidee, « Voir toute la page » et « Agrandir » '
      'avec pictogramme', (WidgetTester tester) async {
    await _monter(tester, taille: _telephone, role: RoleSeance.guidee);
    for (final (Key cle, String mot) in <(Key, String)>[
      (CommandesPedagogiques.cleAjuster, t.salle.seance.commandes.ajusterGuide),
      (CommandesPedagogiques.cleFocus, t.salle.seance.commandes.focusGuide),
    ]) {
      final Finder f = find.byKey(cle);
      expect(tester.widget(f), isA<BoutonOutil>());
      expect(find.descendant(of: f, matching: find.text(mot)), findsOneWidget);
      final Finder icone = find.descendant(of: f, matching: find.byType(Icon));
      expect(icone, findsOneWidget);
      // Le pictogramme est au-dessus du mot, les deux dans la tuile.
      expect(
        tester.getBottomLeft(icone).dy,
        lessThanOrEqualTo(
          tester
              .getTopLeft(find.descendant(of: f, matching: find.text(mot)))
              .dy,
        ),
      );
    }
    expect(find.text(t.salle.seance.commandes.ajuster), findsNothing);
  });

  testWidgets('m3 : la largeur du panneau suit le texte, bornee', (
    WidgetTester tester,
  ) async {
    late double x1;
    late double x2;
    late double borne;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Builder(
          builder: (BuildContext c) {
            x2 = largeurPanneauPour(c, double.infinity);
            borne = largeurPanneauPour(c, 500);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (BuildContext c) {
            x1 = largeurPanneauPour(c, 1000);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(x1, largeurPanneauSeance);
    expect(x2, 2 * largeurPanneauSeance);
    expect(borne, 500);
  });

  group('m4, n. 21, n. 2, n. 10 : le chevron dit seulement la suite', () {
    for (final (
          String nom,
          Size taille,
          double texte,
          RoleSeance role,
          bool suite,
        )
        in <(String, Size, double, RoleSeance, bool)>[
          (
            'eleve 768 : tout tient, pas de chevron',
            _tablette,
            1,
            RoleSeance.eleve,
            false,
          ),
          ('eleve 320 x1 : coupe, chevron', _etroit, 1, RoleSeance.eleve, true),
          (
            'guidee 320 x1 : coupe, chevron',
            _etroit,
            1,
            RoleSeance.guidee,
            true,
          ),
          (
            'enseignant 320 x1 : coupe, chevron',
            _etroit,
            1,
            RoleSeance.enseignant,
            true,
          ),
          (
            'enseignant 1440 x2 : coupe, chevron',
            _bureau,
            2,
            RoleSeance.enseignant,
            true,
          ),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await _monter(tester, taille: taille, texte: texte, role: role);
        expect(
          find.byKey(PanneauSeance.cleSuite),
          suite ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(CommandesPedagogiques.cleFonduBas),
          suite ? findsOneWidget : findsNothing,
        );
        if (suite) {
          // Le chevron est pose sur le fondu, au bas de la vue qui defile,
          // sans prendre de place.
          final Rect vue = tester.getRect(
            find.byKey(CommandesPedagogiques.cleDefilement),
          );
          final Rect chevron = tester.getRect(
            find.byKey(PanneauSeance.cleSuite),
          );
          expect(chevron.bottom, lessThanOrEqualTo(vue.bottom + 0.5));
          expect(chevron.top, greaterThanOrEqualTo(vue.center.dy));
          expect(chevron.center.dx, closeTo(vue.center.dx, 1));
        }
      });
    }
  });

  testWidgets('m8 : au bout de la colonne, plus de fondu ; le focus clavier '
      'n\'est jamais sous le fondu', (WidgetTester tester) async {
    await _monter(tester, taille: _etroit);
    final Finder defile = find.byKey(CommandesPedagogiques.cleDefilement);
    expect(find.byKey(CommandesPedagogiques.cleFonduBas), findsOneWidget);
    // Tab jusqu'a la fleche suivante de la pagination.
    final FocusNode bib = _noeudBibliotheque(tester);
    bib.requestFocus();
    await tester.pump();
    for (int i = 0; i < 12 && !_focusSous(_pagination); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(_focusSous(_pagination), isTrue);
    final Rect vue = tester.getRect(defile);
    final Rect focus = _rectFocus(tester);
    final double fondu = DefilementAFondu.fonduPour(vue.height);
    expect(focus.bottom, lessThanOrEqualTo(vue.bottom - fondu + 0.5));
    expect(focus.top, greaterThanOrEqualTo(vue.top + fondu - 0.5));
    // La derniere commande posee au bord bas, seule la marge interne
    // dessous (ce que fait la traversee du focus) : plus de fondu.
    final ScrollPosition position = tester
        .state<ScrollableState>(
          find.descendant(of: defile, matching: find.byType(Scrollable)),
        )
        .position;
    position.jumpTo(position.maxScrollExtent - AppSpacing.md + 1);
    await tester.pumpAndSettle();
    expect(find.byKey(CommandesPedagogiques.cleFonduBas), findsNothing);
    // Tout en bas, de meme.
    await tester.drag(defile, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.byKey(CommandesPedagogiques.cleFonduBas), findsNothing);
    expect(find.byKey(CommandesPedagogiques.cleFonduHaut), findsOneWidget);
  });

  testWidgets('m9 : apres « Ranger dans la bibliotheque », le focus est sur '
      'la Bibliotheque', (WidgetTester tester) async {
    await _monter(tester);
    final Finder menu = find.byKey(CommandesPedagogiques.cleMenu);
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.salle.seance.rangement.ranger).last);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'commandes-bibliotheque',
    );
    expect(
      _focusSous(find.byKey(CommandesPedagogiques.cleBibliotheque)),
      isTrue,
    );
  });

  testWidgets('m13 : le declencheur ne se dit ni selectionne ni non '
      'selectionne', (WidgetTester tester) async {
    final SemanticsHandle lecteur = tester.ensureSemantics();
    await _monter(tester, ouvrir: false);
    final SemanticsNode n = tester.getSemantics(_declencheur);
    expect(n.getSemanticsData().flagsCollection.isSelected, Tristate.none);
    expect(n.label, contains(t.salle.seance.commandes.declencheurSemantique));
    lecteur.dispose();
  });

  group('n. 9 : la fleche suivante reste dans la pagination', () {
    for (final (String nom, Size taille, double texte)
        in <(String, Size, double)>[
          ('390 x1', _telephone, 1),
          ('768 x2', _tablette, 2),
          ('1440 x1', _bureau, 1),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await _monter(tester, taille: taille, texte: texte);
        await tester.ensureVisible(_pagination);
        await tester.pumpAndSettle();
        final Rect pilule = tester.getRect(_pagination);
        final Rect suivant = tester.getRect(
          find.byKey(const ValueKey<String>('nav-suivant')),
        );
        // Une marge tout autour : le disque ne touche ni ne passe le bord.
        expect(suivant.top, greaterThan(pilule.top + 0.5));
        expect(suivant.bottom, lessThan(pilule.bottom - 0.5));
        expect(suivant.right, lessThan(pilule.right - 0.5));
        expect(suivant.left, greaterThan(pilule.left + 0.5));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
