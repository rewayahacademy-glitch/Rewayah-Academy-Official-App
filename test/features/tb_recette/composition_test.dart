// TB-5 (UI-02, UI-03 ; plan V2 §6, §18.3, §19.4) : bureau equilibre,
// tablette et focus local de l'enseignant.
//
// UX-13 : Participants a gauche, surface au centre, Commandes a droite si
// ouvertes. UX-14 : Focus replie les deux cotes. UX-15 : Commandes en focus
// puis Reduire, la gauche ne revient pas seule. UX-16 : sortie du focus
// apres redimensionnement. UX-24 : ni reconnexion ni perte d'etat au
// changement d'orientation. Colonnes decidees sur la largeur divisee par le
// facteur de texte (UX_REVIEW_CL-4 n. 20).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/capsule_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrome_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/composition_salle.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';

import '../../capture/outil_capture.dart' hide stabiliser;
import '../../router/support_routeur.dart';

const Size _bureau = Size(1440, 900);
const Size _tabletteLarge = Size(1024, 768);
const Size _tablettePortrait = Size(768, 1024);

final Finder _participants = find.byType(PanneauEleves);
final Finder _commandes = find.byKey(CommandesPedagogiques.cle);
final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);
final Finder _focus = find.byKey(CommandesPedagogiques.cleFocus);
final Finder _reduireDock = find.byKey(
  const ValueKey<String>('bouton-agrandir'),
);
final Finder _boutonEleves = find.byKey(
  const ValueKey<String>('bouton-eleves'),
);

Future<void> _monter(
  WidgetTester tester, {
  Size taille = _bureau,
  double texte = 1,
  SituationTb situation = SituationTb.cmd01,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: RoleSeance.enseignant, situation: situation),
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

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await _attendre(tester);
}

Future<void> _redimensionner(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 1);
  await _attendre(tester);
}

Rect _zone(WidgetTester tester) => tester.getRect(find.byType(ZoneSupport));

bool _chevauche(Rect a, Rect b) =>
    a.intersect(b).width > 0.5 && a.intersect(b).height > 0.5;

CompositionSalle _pour({
  double largeur = 1440,
  double texte = 1,
  bool telephone = false,
  PanneauOuvert panneau = PanneauOuvert.aucun,
  bool replies = false,
  bool agrandi = false,
  bool contexte = false,
}) => CompositionSalle.pour(
  largeur: largeur,
  facteurTexte: texte,
  telephone: telephone,
  panneau: panneau,
  participantsReplies: replies,
  agrandi: agrandi,
  contexteOuvert: contexte,
  participantsDisponibles: true,
);

void main() {
  group('CompositionSalle (logique pure)', () {
    test('bureau x1 : deux colonnes, la droite seulement si ouverte', () {
      expect(
        _pour(),
        const CompositionSalle(
          gauche: PlacePanneau.colonne,
          droite: PlacePanneau.aucune,
        ),
      );
      expect(
        _pour(panneau: PanneauOuvert.commandes),
        const CompositionSalle(
          gauche: PlacePanneau.colonne,
          droite: PlacePanneau.colonne,
        ),
      );
      // Supports et Bibliotheque passent a droite (n. 13).
      for (final PanneauOuvert p in <PanneauOuvert>[
        PanneauOuvert.supports,
        PanneauOuvert.ressources,
      ]) {
        expect(_pour(panneau: p).droite, PlacePanneau.colonne, reason: '$p');
      }
    });

    test('largeur divisee par le facteur de texte (CL-4 n. 20)', () {
      // 1440 a 200 % = 720 : aucune colonne, panneaux temporaires.
      expect(
        _pour(texte: 2, panneau: PanneauOuvert.commandes),
        const CompositionSalle(
          gauche: PlacePanneau.aucune,
          droite: PlacePanneau.temporaire,
        ),
      );
      expect(
        _pour(texte: 2, panneau: PanneauOuvert.eleves).gauche,
        PlacePanneau.temporaire,
      );
      // 1024 : la gauche tient, pas les deux ; repliee, la droite tient.
      expect(
        _pour(largeur: 1024, panneau: PanneauOuvert.commandes),
        const CompositionSalle(
          gauche: PlacePanneau.colonne,
          droite: PlacePanneau.temporaire,
        ),
      );
      expect(
        _pour(largeur: 1024, panneau: PanneauOuvert.commandes, replies: true),
        const CompositionSalle(
          gauche: PlacePanneau.aucune,
          droite: PlacePanneau.colonne,
        ),
      );
      // 768 : sous le seuil, rien en colonne ; telephone : jamais.
      expect(_pour(largeur: 768).gauche, PlacePanneau.aucune);
      expect(
        _pour(
          largeur: 2000,
          telephone: true,
          panneau: PanneauOuvert.commandes,
        ).droite,
        PlacePanneau.temporaire,
      );
    });

    test(
      'UX-14, UX-15 : le focus replie la gauche, la droite a la demande',
      () {
        expect(_pour(agrandi: true).gauche, PlacePanneau.aucune);
        expect(
          _pour(agrandi: true, panneau: PanneauOuvert.commandes),
          const CompositionSalle(
            gauche: PlacePanneau.aucune,
            droite: PlacePanneau.colonne,
          ),
        );
        // L'avatar ouvre le contexte sans ouvrir les outils (§18.3).
        expect(
          _pour(agrandi: true, contexte: true),
          const CompositionSalle(
            gauche: PlacePanneau.colonne,
            droite: PlacePanneau.aucune,
          ),
        );
      },
    );

    test('UX-16 : quitter le focus restaure si la largeur le permet', () {
      PanneauOuvert? sortie(
        PanneauOuvert avant,
        PanneauOuvert actuel,
        bool t,
      ) => panneauABasculerEnSortie(
        avantFocus: avant,
        actuel: actuel,
        droiteTient: t,
      );
      // Commandes ouvertes avant, fermees en focus : elles reviennent.
      expect(
        sortie(PanneauOuvert.commandes, PanneauOuvert.aucun, true),
        PanneauOuvert.commandes,
      );
      // Deja ouvertes : rien a faire.
      expect(
        sortie(PanneauOuvert.commandes, PanneauOuvert.commandes, true),
        isNull,
      );
      // Rien avant, Commandes ouvertes en focus : elles se ferment.
      expect(
        sortie(PanneauOuvert.aucun, PanneauOuvert.commandes, true),
        PanneauOuvert.commandes,
      );
      // La largeur ne le permet plus : pas de panneau temporaire rouvert.
      expect(
        sortie(PanneauOuvert.commandes, PanneauOuvert.aucun, false),
        isNull,
      );
      expect(sortie(PanneauOuvert.aucun, PanneauOuvert.aucun, true), isNull);
    });
  });

  group('UX-13 : bureau equilibre', () {
    testWidgets('Participants a gauche, surface, Commandes a droite', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(tester.takeException(), isNull);
      final Rect zone = _zone(tester);
      final Rect gauche = tester.getRect(_participants);
      final Rect droite = tester.getRect(_commandes);
      expect(gauche.right, lessThan(zone.left));
      expect(droite.left, greaterThan(zone.right));
      expect(_chevauche(gauche, zone), isFalse);
      expect(_chevauche(droite, zone), isFalse);
      // La surface reste dominante : plus large que chaque colonne.
      expect(zone.width, greaterThan(gauche.width));
      expect(zone.width, greaterThan(droite.width));
    });

    testWidgets('Commandes fermees : aucune colonne vide a droite', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _taper(tester, find.byKey(PanneauSeance.cleReduire));
      expect(_commandes, findsNothing);
      expect(_participants, findsOneWidget);
      // La surface va jusqu'a la gouttiere de droite.
      expect(_zone(tester).right, greaterThan(_bureau.width - 32));
      expect(_declencheur, findsOneWidget);
    });

    testWidgets('Reduire replie les Participants, le bouton les rouvre', (
      WidgetTester tester,
    ) async {
      await _monter(tester, situation: SituationTb.sal00);
      expect(_participants, findsOneWidget);
      expect(_boutonEleves, findsNothing);
      await _taper(tester, find.byKey(PanneauSeance.cleReduireParticipants));
      expect(_participants, findsNothing);
      expect(_boutonEleves, findsOneWidget);
      // Le bouton prend la place de la colonne, au bord de debut.
      expect(
        tester.getRect(_boutonEleves).left,
        moreOrLessEquals(_zone(tester).left, epsilon: 1),
      );
      // Le focus revient au bouton qui les rouvre.
      final FocusNode? focus = FocusManager.instance.primaryFocus;
      expect(focus?.debugLabel, 'bouton-eleves');
      await _taper(tester, _boutonEleves);
      expect(_participants, findsOneWidget);
      expect(_boutonEleves, findsNothing);
    });

    testWidgets('texte a 200 % au bureau : aucune colonne, rien de comprime', (
      WidgetTester tester,
    ) async {
      await _monter(tester, texte: 2);
      expect(tester.takeException(), isNull);
      expect(_participants, findsNothing);
      // Les Commandes ouvertes passent par-dessus, en volet, et la surface
      // garde toute la largeur.
      expect(
        find.ancestor(
          of: _commandes,
          matching: find.byKey(const ValueKey<String>('panneau-seance-volet')),
        ),
        findsOneWidget,
      );
      expect(_zone(tester).width, greaterThan(_bureau.width - 64));
    });

    testWidgets('tablette 1024 : Participants en colonne, Commandes en volet', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: _tabletteLarge);
      expect(tester.takeException(), isNull);
      expect(
        find.ancestor(
          of: _participants,
          matching: find.byKey(
            const ValueKey<String>('panneau-seance-colonne'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: _commandes,
          matching: find.byKey(const ValueKey<String>('panneau-seance-volet')),
        ),
        findsOneWidget,
      );
      // Le volet ne recouvre pas la colonne des Participants.
      expect(
        _chevauche(
          tester.getRect(_participants),
          tester.getRect(
            find.byKey(const ValueKey<String>('panneau-seance-volet')),
          ),
        ),
        isFalse,
      );
    });
  });

  group('UX-14 a UX-16 : focus local', () {
    testWidgets('UX-14 : depuis deux panneaux ouverts, les deux se replient', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(_participants, findsOneWidget);
      expect(_commandes, findsOneWidget);
      await _taper(tester, _focus);
      expect(_participants, findsNothing);
      expect(_commandes, findsNothing);
      // Contenu agrandi : la surface prend la largeur utile.
      expect(_zone(tester).width, greaterThan(_bureau.width - 64));
      // La visio reste revelable (barre dans CommandesMasquables) et la
      // sortie est la : « Reduire » de la barre, declencheur des Commandes.
      expect(find.byKey(CommandesMasquables.commandesKey), findsOneWidget);
      expect(_reduireDock, findsOneWidget);
      expect(_declencheur, findsOneWidget);
    });

    testWidgets('UX-15 : Commandes en focus puis Reduire, la gauche reste '
        'repliee', (WidgetTester tester) async {
      await _monter(tester);
      await _taper(tester, _focus);
      await _taper(tester, _declencheur);
      expect(_commandes, findsOneWidget);
      expect(_participants, findsNothing);
      await _taper(tester, find.byKey(PanneauSeance.cleReduire));
      expect(_commandes, findsNothing);
      expect(_participants, findsNothing);
      // Toujours en focus.
      expect(_reduireDock, findsOneWidget);
    });

    testWidgets('UX-16 : sortie au bureau, composition d\'avant restauree', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _taper(tester, _focus);
      await _taper(tester, _reduireDock);
      expect(_participants, findsOneWidget);
      expect(_commandes, findsOneWidget);
      expect(_reduireDock, findsNothing);
    });

    testWidgets('UX-16 : sortie apres passage a 1024, Commandes non '
        'rouvertes en volet', (WidgetTester tester) async {
      await _monter(tester);
      await _taper(tester, _focus);
      await _redimensionner(tester, _tabletteLarge);
      await _taper(tester, _reduireDock);
      expect(tester.takeException(), isNull);
      expect(_participants, findsOneWidget);
      expect(_commandes, findsNothing);
    });

    testWidgets('UX-16 : sortie apres passage a 768, aucune colonne', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _taper(tester, _focus);
      await _redimensionner(tester, _tablettePortrait);
      await _taper(tester, _reduireDock);
      expect(tester.takeException(), isNull);
      expect(_participants, findsNothing);
      expect(_commandes, findsNothing);
      expect(_boutonEleves, findsOneWidget);
    });

    testWidgets('Echap : ferme le panneau, puis quitte le focus', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _taper(tester, _focus);
      await _taper(tester, _declencheur);
      expect(_commandes, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _attendre(tester);
      expect(_commandes, findsNothing);
      expect(_reduireDock, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _attendre(tester);
      expect(_reduireDock, findsNothing);
      // L'appel n'est jamais coupe : la salle est toujours la.
      expect(find.byType(ZoneSupport), findsOneWidget);
      expect(find.text(t.salle.seance.quitterQuestion), findsNothing);
    });
  });

  // Revue du 09/10 (plan V2 §19.4.3, §6) : en focus, ne subsistent que le
  // contenu, la capsule compacte, l'acces aux Commandes et la sortie. Mesure
  // sur le rendu : l'en-tete n'est plus monte, la surface remonte, la capsule
  // est dans la vue ; a la sortie, tout revient.
  group('Focus : l\'en-tete se retire, la capsule reste', () {
    final Finder chrome = find.byType(ChromeSeance);
    final Finder titre = find.text(t.salle.seance.titre);
    final Finder capsule = find.byKey(CapsuleSeance.cle);
    for (final (Size taille, double texte) cas in <(Size, double)>[
      (_bureau, 1),
      (_bureau, 2),
      (_tabletteLarge, 2),
      (_tablettePortrait, 2),
    ]) {
      final (Size taille, double texte) = cas;
      testWidgets('${taille.width.toInt()} x${texte.toInt()}', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille: taille, texte: texte);
        expect(chrome, findsOneWidget);
        expect(titre, findsOneWidget);
        final double hautAvant = _zone(tester).top;
        // Commandes ouvertes d'office (CMD-01) : Focus y est. Amene au
        // milieu du panneau (a x2, son bord bas passe sous la barre de
        // l'appel).
        await Scrollable.ensureVisible(tester.element(_focus), alignment: 0.5);
        await tester.pump();
        await tester.tap(_focus);
        await _attendre(tester);
        expect(tester.takeException(), isNull);
        expect(_reduireDock, findsOneWidget, reason: 'en focus');
        expect(chrome, findsNothing);
        expect(titre, findsNothing);
        expect(capsule, findsOneWidget);
        final Rect vue = Offset.zero & taille;
        final Rect laCapsule = tester.getRect(capsule);
        expect(vue.contains(laCapsule.topLeft), isTrue);
        expect(vue.contains(laCapsule.bottomRight), isTrue);
        // La surface prend la hauteur rendue par l'en-tete.
        final double hautFocus = _zone(tester).top;
        expect(hautFocus, lessThan(hautAvant - 24));
        // Le contenu commence sous la capsule, sans la chevaucher.
        expect(_chevauche(laCapsule, _zone(tester)), isFalse);
        // Acces Commandes et sortie du focus restent.
        expect(_declencheur, findsOneWidget);
        expect(_reduireDock, findsOneWidget);
        await _taper(tester, _reduireDock);
        expect(chrome, findsOneWidget);
        expect(titre, findsOneWidget);
        // L'en-tete revient au-dessus de la surface (a 1024 et 768 x2, les
        // Commandes ne reviennent pas en volet : la rangee « Eleves »
        // reprend sa place, ecart 1 de TB-5).
        expect(_zone(tester).top, greaterThanOrEqualTo(hautAvant - 1));
      });
    }
  });

  // Revue du 09/10 : Commandes ouvertes en colonne, le declencheur
  // « Commandes » s'efface (une seule entree visible) et revient a la
  // fermeture.
  testWidgets('1440 x1 : un seul « Commandes » visible a la fois', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    expect(_commandes, findsOneWidget);
    expect(_declencheur, findsNothing);
    expect(find.text(t.salle.seance.commandes.titre), findsOneWidget);
    await _taper(tester, find.byKey(PanneauSeance.cleReduire));
    expect(_commandes, findsNothing);
    expect(_declencheur, findsOneWidget);
  });

  // K-07 : depuis la vraie coquille (/demo/salle, lien de la situation),
  // taper Focus puis la sortie de la barre de l'appel.
  group('K-07 : depuis la vraie coquille', () {
    testWidgets('bureau : Focus replie, Reduire restaure', (
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
      expect(_participants, findsOneWidget);
      expect(_commandes, findsOneWidget);
      await _taper(tester, _focus);
      expect(_participants, findsNothing);
      expect(_commandes, findsNothing);
      await _taper(tester, _reduireDock);
      expect(_participants, findsOneWidget);
      expect(_commandes, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('telephone 320 x2 : le support garde sa place, l\'avatar '
        'ouvre les Participants', (WidgetTester tester) async {
      await _monter(
        tester,
        taille: const Size(320, 700),
        texte: 2,
        situation: SituationTb.ped03,
      );
      expect(tester.takeException(), isNull);
      // Pendant le partage, pas de rangee « Eleves » au telephone.
      expect(_boutonEleves, findsNothing);
      // Mesure : 56 avant TB-5 (rangee « Eleves »), 138 apres.
      expect(_zone(tester).height, greaterThan(120));
      await _taper(tester, find.byKey(CapsuleSeance.cleAvatar));
      expect(_participants, findsOneWidget);
    });
  });

  group('UX-24 : orientation', () {
    testWidgets('tablette paysage puis portrait : etat local garde', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: _tabletteLarge);
      await _taper(tester, _focus);
      await _taper(tester, _declencheur);
      expect(_commandes, findsOneWidget);
      await _redimensionner(tester, _tablettePortrait);
      expect(tester.takeException(), isNull);
      // Focus et Commandes restent ouverts, en volet a cette largeur.
      expect(_commandes, findsOneWidget);
      expect(_reduireDock, findsOneWidget);
      await _redimensionner(tester, _tabletteLarge);
      expect(_commandes, findsOneWidget);
      expect(_reduireDock, findsOneWidget);
    });
  });
}
