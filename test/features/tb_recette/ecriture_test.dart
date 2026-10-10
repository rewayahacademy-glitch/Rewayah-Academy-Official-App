// TB-7b (CMD-02, CMD-03 ; plan V2 §4.2, §7, §13, §19.1, §20 ; UX_REVIEW_TB
// n. 21 et 22 ; TB14, TB21 ; TB-STYLET-1) : Ecrire dans la salle.
//
// Les parcours partent de la VRAIE coquille (`/demo/salle`, K-07) : le
// depot d'annotations est celui de la demonstration (en memoire), lu dans
// le perimetre de la salle. Les mesures portent sur le rendu : traits pris
// par le depot, rectangles de la page, widgets montes, pixels peints.

import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart'
    show CapaciteRessource;
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart'
    show ModeAffichagePartage;
import 'package:rewayah_academy/core/tc_outils/ancrage_annotation.dart'
    show CarteDesBlocs;
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/operations_personnelles.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../capture/outil_capture.dart'
    show cadreCapture, fixerVueCapture, hoteCapture;
import '../../router/support_routeur.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);
final Finder _onglets = find.byKey(CommandesPedagogiques.cleOnglets);
final Finder _ecrire = find.byKey(const ValueKey<String>('outil-ecrire'));
final Finder _pointeurOutil = find.byKey(
  const ValueKey<String>('outil-pointeur'),
);
final Finder _palette = find.byKey(PaletteEcriture.cle);
final Finder _ecriture = find.byKey(EcritureSeance.cle);

Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// K-07 : la salle de la situation, ouverte depuis la liste de /demo/salle.
Future<void> _ouvrir(
  WidgetTester tester, {
  SituationTb situation = SituationTb.ped03,
  Size taille = _telephone,
}) async {
  await monterRouteur(tester, Routes.demoSalle, taille: taille);
  final Finder lien = find.byKey(
    ValueKey<String>('lien-${RoleSeance.enseignant.name}-tb-${situation.name}'),
  );
  await tester.ensureVisible(lien);
  await tester.pump();
  await tester.tap(lien);
  await stabiliser(tester);
  expect(tester.takeException(), isNull);
}

/// La page servie par /demo/salle, montee seule (rendu mesure en pixels).
Future<void> _monter(
  WidgetTester tester, {
  SituationTb situation = SituationTb.ped03,
  Size taille = _telephone,
  double densite = 1,
  double texte = 1,
  List<Override> surcharges = const <Override>[],
}) async {
  fixerVueCapture(tester, taille, densite);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: RoleSeance.enseignant, situation: situation),
      echelleTexte: texte,
      surcharges: surcharges,
    ),
  );
  await stabiliser(tester);
}

ProviderContainer _conteneur(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SalleSeance)));

/// Le depot de la salle (celui de la demonstration).
AnnotationsMemoire _depot(WidgetTester tester) =>
    _conteneur(tester).read(portAnnotationsProvider) as AnnotationsMemoire;

List<TraitVectoriel> _traits(WidgetTester tester) => <TraitVectoriel>[
  for (final AnnotationLayer c in _depot(tester).couches) ...c.traits,
];

OutilDock? _outil(WidgetTester tester) =>
    _conteneur(tester).read(etatOutilsProvider).outilActif;

Offset _surPage(WidgetTester tester, double x, double y) {
  final Rect r = tester.getRect(_page);
  return r.topLeft + Offset(x * r.width, y * r.height);
}

/// Un geste de [a] a [b] avec un appareil, en huit pas.
Future<void> _glisser(
  WidgetTester tester,
  Offset a,
  Offset b, {
  PointerDeviceKind appareil = PointerDeviceKind.touch,
  int id = 31,
}) async {
  final TestPointer p = TestPointer(id, appareil);
  await tester.sendEventToBinding(p.down(a));
  for (int i = 1; i <= 8; i++) {
    await tester.sendEventToBinding(p.move(Offset.lerp(a, b, i / 8)!));
    await tester.pump();
  }
  await tester.sendEventToBinding(p.up());
  await _attendre(tester);
}

/// Deux doigts qui glissent ensemble de [pas].
Future<void> _deuxDoigts(WidgetTester tester, Offset a, Offset pas) async {
  final TestPointer un = TestPointer(41);
  final TestPointer deux = TestPointer(42);
  final Offset b = a + const Offset(60, 0);
  await tester.sendEventToBinding(un.down(a));
  await tester.sendEventToBinding(deux.down(b));
  for (int i = 1; i <= 8; i++) {
    await tester.sendEventToBinding(un.move(a + pas * (i / 8)));
    await tester.sendEventToBinding(deux.move(b + pas * (i / 8)));
    await tester.pump();
  }
  await tester.sendEventToBinding(un.up());
  await tester.sendEventToBinding(deux.up());
  await _attendre(tester);
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await _attendre(tester);
}

/// Commandes > Outils.
Future<void> _outils(WidgetTester tester) async {
  await _taper(tester, _declencheur);
  await _taper(
    tester,
    find.descendant(
      of: _onglets,
      matching: find.text(t.salle.seance.commandes.ongletOutils),
    ),
  );
}

/// « Reduire » ferme le panneau.
Future<void> _reduire(WidgetTester tester) =>
    _taper(tester, find.byKey(PanneauSeance.cleReduire));

/// Commandes > Outils > Ecrire, puis le panneau reduit.
Future<void> _armerEcrire(WidgetTester tester) async {
  await _outils(tester);
  await _taper(tester, _ecrire);
  expect(_outil(tester), OutilDock.stylet);
  await _reduire(tester);
}

/// Zoom local a 200 % par les Commandes (onglet Support, Lecture).
Future<void> _zoom200(WidgetTester tester) async {
  await _taper(tester, _declencheur);
  final Finder support = find.descendant(
    of: _onglets,
    matching: find.text(t.salle.seance.commandes.ongletSupport),
  );
  if (support.evaluate().isNotEmpty) await _taper(tester, support);
  final Finder plus = find.byWidgetPredicate(
    (Widget w) =>
        w is Pressable && w.libelleSemantique == t.salle.seance.zoomPlus,
  );
  await tester.ensureVisible(plus.first);
  await tester.pump();
  for (int i = 0; i < 10; i++) {
    await tester.tap(plus.first);
    await tester.pump();
  }
  await _reduire(tester);
}

/// Le nombre de points d'encre sombre sur la verticale [x], entre [haut] et
/// [bas] (pixels physiques), lus sur l'image rendue de la coquille.
Future<int> _encreVerticale(
  WidgetTester tester,
  double x,
  double haut,
  double bas,
) async {
  final double densite = tester.view.devicePixelRatio;
  final RenderRepaintBoundary cadre = tester.renderObject(
    find.byKey(cadreCapture),
  );
  final (ByteData, int)? lu = await tester.runAsync<(ByteData, int)>(() async {
    final ui.Image image = await cadre.toImage(pixelRatio: densite);
    final ByteData? brut = await image.toByteData();
    final int largeur = image.width;
    image.dispose();
    return (brut!, largeur);
  });
  final (ByteData octets, int largeur) = lu!;
  int n = 0;
  final int px = (x * densite).round();
  for (int py = (haut * densite).round(); py < (bas * densite).round(); py++) {
    final int i = (py * largeur + px) * 4;
    final int clarte =
        octets.getUint8(i) + octets.getUint8(i + 1) + octets.getUint8(i + 2);
    if (clarte < 600) n++;
  }
  return n;
}

void main() {
  group('K-07 : Ecrire depuis /demo/salle', () {
    testWidgets('Commandes > Outils > Ecrire : barre, options, trait, '
        'palette courte, Annuler, Terminer', (WidgetTester tester) async {
      await _ouvrir(tester);
      await _outils(tester);
      // Avant Ecrire : ni barre, ni options (sous-barre seulement apres
      // Ecrire, plan V2 §4.2) ; la phrase de la lecture.
      expect(_ecriture, findsNothing);
      expect(find.text(t.salle.seance.outils.aideLecture), findsOneWidget);
      await _taper(tester, _ecrire);
      expect(_outil(tester), OutilDock.stylet);
      expect(_ecriture, findsOneWidget);
      expect(find.text(t.salle.seance.outils.aideEcrire), findsOneWidget);
      for (final OutilTrait o in OutilTrait.values) {
        expect(find.byKey(BarreStylet.cleOutil(o)), findsOneWidget);
      }
      expect(find.byKey(BarreStylet.cleTerminer), findsOneWidget);
      // Rien a annuler encore : pas de bouton (jamais grise).
      expect(find.byKey(BarreStylet.cleAnnuler), findsNothing);
      expect(find.byKey(EcritureSeance.cleCouleur), findsOneWidget);
      expect(find.byKey(EcritureSeance.cleEpaisseur), findsOneWidget);

      // Couleur « A renforcer », Epaisseur « Epais ».
      await _taper(
        tester,
        find.descendant(
          of: find.byKey(EcritureSeance.cleCouleur),
          matching: find.text(t.tc.outils.intention.aRenforcer),
        ),
      );
      await _taper(
        tester,
        find.descendant(
          of: find.byKey(EcritureSeance.cleEpaisseur),
          matching: find.text(t.salle.seance.ecriture.epaisse),
        ),
      );

      // Panneau reduit : la palette courte, a cote de « Commandes ».
      await _reduire(tester);
      expect(_palette, findsOneWidget);
      expect(_declencheur, findsOneWidget);
      expect(
        find.descendant(
          of: _palette,
          matching: find.byKey(BarreStylet.cleOutilActif),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _palette,
          matching: find.byKey(BarreStylet.cleTerminer),
        ),
        findsOneWidget,
      );

      // Un doigt ecrit : le depot prend un trait, avec la couleur et
      // l'epaisseur choisies, sur la page montree.
      await _glisser(
        tester,
        _surPage(tester, 0.2, 0.2),
        _surPage(tester, 0.6, 0.25),
      );
      final TraitVectoriel trait = _traits(tester).single;
      expect(trait.intention, IntentionPedagogique.aRenforcer);
      expect(trait.epaisseur, EpaisseurTrait.epaisse);
      expect(trait.outil, OutilTrait.stylet);
      expect(
        trait.ancrage,
        isA<ContentPosition>().having((ContentPosition p) => p.page, 'page', 1),
      );

      // Annuler (palette) retire ce trait.
      final Finder annuler = find.descendant(
        of: _palette,
        matching: find.byKey(BarreStylet.cleAnnuler),
      );
      expect(annuler, findsOneWidget);
      await _taper(tester, annuler);
      expect(_traits(tester), isEmpty);
      expect(annuler, findsNothing, reason: 'plus rien a annuler');

      // L'outil actif de la palette rouvre les Commandes sur « Outils ».
      await _taper(
        tester,
        find.descendant(
          of: _palette,
          matching: find.byKey(BarreStylet.cleOutilActif),
        ),
      );
      expect(_ecriture, findsOneWidget);
      await _reduire(tester);

      // Terminer : retour a la lecture ; la palette s'en va, un doigt
      // n'ecrit plus.
      await _taper(
        tester,
        find.descendant(
          of: _palette,
          matching: find.byKey(BarreStylet.cleTerminer),
        ),
      );
      expect(_outil(tester), isNull);
      expect(_palette, findsNothing);
      await _glisser(
        tester,
        _surPage(tester, 0.2, 0.2),
        _surPage(tester, 0.6, 0.25),
      );
      expect(_traits(tester), isEmpty);
    });

    testWidgets('Terminer du panneau revient a la lecture, l encre demeure', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, taille: _bureau);
      await _armerEcrire(tester);
      await _glisser(
        tester,
        _surPage(tester, 0.2, 0.2),
        _surPage(tester, 0.6, 0.25),
      );
      expect(_traits(tester), hasLength(1));
      await _outils(tester);
      await _taper(tester, find.byKey(BarreStylet.cleTerminer));
      expect(_outil(tester), isNull);
      expect(_ecriture, findsNothing);
      expect(find.text(t.salle.seance.outils.aideLecture), findsOneWidget);
      expect(_traits(tester), hasLength(1), reason: 'l encre demeure');
    });

    testWidgets('Ecrire en « Support » passe a « Avec notes » (une note '
        'ecrite se voit)', (WidgetTester tester) async {
      await _ouvrir(tester, situation: SituationTb.ped02);
      final Finder calque = find.byKey(SurfacePageFixe.cleCalque);
      expect(tester.widget<Visibility>(calque).visible, isFalse);
      await _outils(tester);
      await _taper(tester, _ecrire);
      expect(tester.widget<Visibility>(calque).visible, isTrue);
    });

    testWidgets('Gomme : retire le trait touche, Annuler le rend', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester);
      await _armerEcrire(tester);
      await _glisser(
        tester,
        _surPage(tester, 0.2, 0.2),
        _surPage(tester, 0.6, 0.2),
      );
      expect(_traits(tester), hasLength(1));
      await _outils(tester);
      await _taper(tester, find.byKey(BarreStylet.cleOutil(OutilTrait.gomme)));
      // La gomme n'a ni couleur ni epaisseur.
      expect(find.byKey(EcritureSeance.cleCouleur), findsNothing);
      await _reduire(tester);
      await _glisser(
        tester,
        _surPage(tester, 0.4, 0.1),
        _surPage(tester, 0.4, 0.3),
      );
      expect(_traits(tester), isEmpty, reason: 'gomme par trait');
      await _taper(
        tester,
        find.descendant(
          of: _palette,
          matching: find.byKey(BarreStylet.cleAnnuler),
        ),
      );
      expect(_traits(tester), hasLength(1), reason: 'Annuler rend le trait');
    });
  });

  group('Gestes (plan V2 §7, TB21, TB-STYLET-1)', () {
    testWidgets('un doigt ne dessine qu en Ecrire', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester);
      Future<void> trait() => _glisser(
        tester,
        _surPage(tester, 0.2, 0.2),
        _surPage(tester, 0.6, 0.25),
      );
      // Lecture (aucun outil).
      await trait();
      expect(_traits(tester), isEmpty, reason: 'lecture');
      // Pointeur : une indication tant que le doigt est pose, sans trace.
      await _outils(tester);
      await _taper(tester, _pointeurOutil);
      expect(_outil(tester), OutilDock.pointeur);
      expect(find.text(t.salle.seance.outils.aidePointeur), findsOneWidget);
      await _reduire(tester);
      final Offset ici = _surPage(tester, 0.3, 0.3);
      final TestPointer doigt = TestPointer(51);
      await tester.sendEventToBinding(doigt.down(ici));
      await tester.pump();
      final Finder indication = find.byKey(SurfacePageFixe.clePointeur);
      expect(indication, findsOneWidget);
      expect(
        (tester.getCenter(indication) - ici).distance,
        lessThan(1),
        reason: 'l indication suit le doigt',
      );
      await tester.sendEventToBinding(doigt.up());
      await tester.pump();
      expect(indication, findsNothing, reason: 'temporaire');
      await trait();
      expect(_traits(tester), isEmpty, reason: 'Pointeur : aucune trace');
      // Ecrire.
      await _outils(tester);
      await _taper(tester, _ecrire);
      await _reduire(tester);
      await trait();
      expect(_traits(tester), hasLength(1), reason: 'Ecrire');
    });

    testWidgets('le stylet n ecrit que si Ecrire est actif', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester);
      Future<void> stylet() => _glisser(
        tester,
        _surPage(tester, 0.2, 0.2),
        _surPage(tester, 0.6, 0.25),
        appareil: PointerDeviceKind.stylus,
      );
      await stylet();
      expect(_traits(tester), isEmpty, reason: 'lecture');
      await _outils(tester);
      await _taper(tester, _pointeurOutil);
      await _reduire(tester);
      await stylet();
      expect(_traits(tester), isEmpty, reason: 'Pointeur');
      await _outils(tester);
      await _taper(tester, _ecrire);
      await _reduire(tester);
      await stylet();
      expect(_traits(tester), hasLength(1), reason: 'Ecrire');
      // Terminer : le stylet ne laisse plus rien.
      await _taper(
        tester,
        find.descendant(
          of: _palette,
          matching: find.byKey(BarreStylet.cleTerminer),
        ),
      );
      await stylet();
      expect(_traits(tester), hasLength(1));
    });

    testWidgets('deux doigts deplacent la page agrandie, sans ecrire ; un '
        'doigt ecrit sans la deplacer', (WidgetTester tester) async {
      await _ouvrir(tester, taille: _bureau);
      await _zoom200(tester);
      await _armerEcrire(tester);
      final Rect avant = tester.getRect(_page);
      final Offset depart = _surPage(tester, 0.45, 0.4);
      // La page agrandie depasse sa surface en hauteur (portrait dans un
      // ecran paysage) : elle se deplace verticalement.
      await _deuxDoigts(tester, depart, const Offset(0, -60));
      final Rect apres = tester.getRect(_page);
      expect(_traits(tester), isEmpty, reason: 'deux doigts n ecrivent pas');
      expect(apres.top, moreOrLessEquals(avant.top - 60, epsilon: 1));
      expect(apres.left, avant.left);
      expect(apres.size, avant.size);
      // Un doigt : un trait, la page ne bouge pas.
      await _glisser(
        tester,
        _surPage(tester, 0.4, 0.4),
        _surPage(tester, 0.5, 0.42),
      );
      expect(_traits(tester), hasLength(1));
      expect(tester.getRect(_page), apres);
    });

    testWidgets('en lecture, un doigt deplace la page agrandie ; a 100 %, '
        'elle ne bouge pas', (WidgetTester tester) async {
      await _ouvrir(tester, taille: _bureau);
      final Rect a100 = tester.getRect(_page);
      await _glisser(
        tester,
        _surPage(tester, 0.5, 0.5),
        _surPage(tester, 0.3, 0.4),
      );
      expect(tester.getRect(_page), a100, reason: 'page entiere : borne');
      await _zoom200(tester);
      final Rect avant = tester.getRect(_page);
      final Offset a = _surPage(tester, 0.5, 0.5);
      await _glisser(tester, a, a + const Offset(40, 30));
      // Verticalement, de son pas ; horizontalement, la page tient deja
      // dans la largeur : bornee, elle ne quitte pas sa place.
      expect(
        tester.getRect(_page).topLeft,
        avant.topLeft + const Offset(0, 30),
      );
      expect(_traits(tester), isEmpty);
    });
  });

  group('Annuler : la derniere operation personnelle (§7, n. 21)', () {
    testWidgets('Annuler ne retire pas le trait d un autre', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester);
      await _armerEcrire(tester);
      await _glisser(
        tester,
        _surPage(tester, 0.2, 0.2),
        _surPage(tester, 0.6, 0.25),
      );
      final TraitVectoriel mien = _traits(tester).single;
      // Un autre (un eleve autorise, TB-10) ecrit APRES : son trait arrive
      // dans le depot de la seance.
      final AnnotationsMemoire depot = _depot(tester);
      final AnnotationLayer couche = depot.couches.single;
      final TraitVectoriel autre = TraitVectoriel(
        id: 'trait-d-un-autre',
        ancrage: mien.ancrage,
        outil: OutilTrait.stylet,
        points: const <PointNormalise>[
          PointNormalise(0.2, 0.8),
          PointNormalise(0.7, 0.85),
        ],
      );
      await tester.runAsync(() => depot.ajouterTrait(couche.id, autre));
      await _attendre(tester);
      await _taper(
        tester,
        find.descendant(
          of: _palette,
          matching: find.byKey(BarreStylet.cleAnnuler),
        ),
      );
      final List<String> restent = <String>[
        for (final TraitVectoriel x in _traits(tester)) x.id,
      ];
      expect(restent, <String>['trait-d-un-autre']);
      // Et le cercle de la demonstration (deja la) reste peint dans la vue.
      expect(
        tester
            .widget<CoucheAnnotation>(find.byKey(SurfacePageFixe.cleCouche))
            .traits
            .map((TraitVectoriel x) => x.id),
        containsAll(<String>['demo-trait-cercle', 'trait-d-un-autre']),
      );
    });

    testWidgets('la gomme d un eleve ne retire que ses propres traits', (
      WidgetTester tester,
    ) async {
      final AnnotationsMemoire depot = AnnotationsMemoire('eleve');
      addTearDown(depot.liberer);
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[portAnnotationsProvider.overrideWithValue(depot)],
      );
      addTearDown(conteneur.dispose);
      conteneur.read(etatOutilsProvider.notifier)
        ..choisirOutil(OutilDock.stylet)
        ..choisirOutilTrait(OutilTrait.gomme);
      final VueSeance vue = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.ped03,
      );
      final ContentPosition page = vue.ancrageSurface!;
      const Rect cadre = Rect.fromLTWH(0, 0, 400, 500);
      final TraitVectoriel autre = TraitVectoriel(
        id: 'trait-enseignant',
        ancrage: page,
        outil: OutilTrait.stylet,
        points: const <PointNormalise>[
          PointNormalise(0, 0.5),
          PointNormalise(1, 0.5),
        ],
      );
      fixerVueCapture(tester, const Size(400, 500), 1);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: conteneur,
          child: hoteCapture(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(
                size: cadre.size,
                child: CoucheAnnotation(
                  support: SupportPresente(
                    resourceId: page.resourceId,
                    capacites: const <CapaciteRessource>{
                      CapaciteRessource.annotatable,
                    },
                    blocs: CarteDesBlocs(cadre: cadre),
                    ancrageCadre: page,
                    modeAffichage: ModeAffichagePartage.page,
                  ),
                  contexte: const ContexteDock(groupeId: 'g'),
                  traits: <TraitVectoriel>[autre],
                  repereDePage: true,
                  gommeSurTous: false,
                ),
              ),
            ),
          ),
        ),
      );
      await _attendre(tester);
      final TestPointer doigt = TestPointer(61);
      await tester.sendEventToBinding(doigt.down(const Offset(200, 230)));
      for (int i = 1; i <= 6; i++) {
        await tester.sendEventToBinding(doigt.move(Offset(200, 230 + i * 8.0)));
        await tester.pump();
      }
      await tester.sendEventToBinding(doigt.up());
      await _attendre(tester);
      expect(
        conteneur.read(historiquePersonnelProvider).retires,
        isEmpty,
        reason: 'le trait d un autre reste',
      );
    });
  });

  testWidgets('changement de page pendant un trait : le trait est resolu '
      'sur sa page, rien ne passe sur la nouvelle', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, _bureau, 1);
    addTearDown(tester.view.reset);
    final AnnotationsMemoire depot = AnnotationsMemoire('prof');
    addTearDown(depot.liberer);
    final ProviderContainer conteneur = ProviderContainer(
      overrides: <Override>[portAnnotationsProvider.overrideWithValue(depot)],
    );
    addTearDown(conteneur.dispose);
    conteneur.read(etatOutilsProvider.notifier).choisirOutil(OutilDock.stylet);
    final VueSeance page1 = DonneesSeanceDemo.vueTb(
      RoleSeance.enseignant,
      SituationTb.ped03,
    );
    final VueSeance page2 = page1.copyWith(
      supportPresente: page1.supportPresente!.aLaPage(2),
    );
    Widget surface(VueSeance vue) => UncontrolledProviderScope(
      container: conteneur,
      child: hoteCapture(SurfacePageFixe(vue: vue, surface: vue.vueSurface)),
    );
    await tester.pumpWidget(surface(page1));
    await _attendre(tester);
    final Offset a = _surPage(tester, 0.2, 0.2);
    final Offset b = _surPage(tester, 0.4, 0.2);
    final Offset c = _surPage(tester, 0.7, 0.3);
    final TestPointer doigt = TestPointer(71);
    await tester.sendEventToBinding(doigt.down(a));
    for (int i = 1; i <= 6; i++) {
      await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, i / 6)!));
      await tester.pump();
    }
    // La page change (Page suivante, ou l'enseignant a distance).
    await tester.pumpWidget(surface(page2));
    await tester.pump();
    for (int i = 1; i <= 6; i++) {
      await tester.sendEventToBinding(doigt.move(Offset.lerp(b, c, i / 6)!));
      await tester.pump();
    }
    await tester.sendEventToBinding(doigt.up());
    await _attendre(tester);
    final List<TraitVectoriel> traits = <TraitVectoriel>[
      for (final AnnotationLayer x in depot.couches) ...x.traits,
    ];
    expect(traits, hasLength(1), reason: 'un seul trait, aucun sur la page 2');
    final TraitVectoriel trait = traits.single;
    expect(trait.ancrage, page1.ancrageSurface);
    expect(
      trait.points.last.x,
      lessThanOrEqualTo(0.4 + 1e-6),
      reason: 'aucun point pose apres le changement de page',
    );
    expect(
      tester
          .widget<CoucheAnnotation>(find.byKey(SurfacePageFixe.cleCouche))
          .traits,
      isEmpty,
      reason: 'la page 2 ne peint pas le trait de la page 1',
    );
  });

  testWidgets('changement de page pendant un geste de gomme : la gomme '
      's arrete a sa page, rien n est gomme sur la nouvelle', (
    WidgetTester tester,
  ) async {
    final AnnotationsMemoire depot = AnnotationsMemoire('prof');
    addTearDown(depot.liberer);
    final ProviderContainer conteneur = ProviderContainer(
      overrides: <Override>[portAnnotationsProvider.overrideWithValue(depot)],
    );
    addTearDown(conteneur.dispose);
    conteneur.read(etatOutilsProvider.notifier)
      ..choisirOutil(OutilDock.stylet)
      ..choisirOutilTrait(OutilTrait.gomme);
    final VueSeance vue = DonneesSeanceDemo.vueTb(
      RoleSeance.enseignant,
      SituationTb.ped03,
    );
    final ContentPosition page1 = vue.ancrageSurface!;
    final ContentPosition page2 = vue
        .copyWith(supportPresente: vue.supportPresente!.aLaPage(2))
        .ancrageSurface!;
    expect(page2, isNot(page1));
    const Rect cadre = Rect.fromLTWH(0, 0, 400, 500);
    TraitVectoriel horizontal(String id, ContentPosition page, double y) =>
        TraitVectoriel(
          id: id,
          ancrage: page,
          outil: OutilTrait.stylet,
          points: <PointNormalise>[PointNormalise(0, y), PointNormalise(1, y)],
        );
    final TraitVectoriel surPage1 = horizontal('trait-page-1', page1, 0.3);
    final TraitVectoriel surPage2 = horizontal('trait-page-2', page2, 0.7);
    Widget couche(ContentPosition page, TraitVectoriel trait) =>
        UncontrolledProviderScope(
          container: conteneur,
          child: hoteCapture(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(
                size: cadre.size,
                child: CoucheAnnotation(
                  support: SupportPresente(
                    resourceId: page.resourceId,
                    capacites: const <CapaciteRessource>{
                      CapaciteRessource.annotatable,
                    },
                    blocs: CarteDesBlocs(cadre: cadre),
                    ancrageCadre: page,
                    modeAffichage: ModeAffichagePartage.page,
                  ),
                  contexte: const ContexteDock(groupeId: 'g'),
                  traits: <TraitVectoriel>[trait],
                  repereDePage: true,
                ),
              ),
            ),
          ),
        );
    fixerVueCapture(tester, const Size(400, 500), 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(couche(page1, surPage1));
    await _attendre(tester);
    // La gomme descend a travers le trait de la page 1 (y = 150).
    final TestPointer doigt = TestPointer(81);
    await tester.sendEventToBinding(doigt.down(const Offset(200, 120)));
    for (int i = 1; i <= 6; i++) {
      await tester.sendEventToBinding(doigt.move(Offset(200, 120 + i * 10.0)));
      await tester.pump();
    }
    // La page change ; le meme geste continue a travers le trait de la
    // page 2 (y = 350).
    await tester.pumpWidget(couche(page2, surPage2));
    await tester.pump();
    for (int i = 1; i <= 12; i++) {
      await tester.sendEventToBinding(doigt.move(Offset(200, 180 + i * 20.0)));
      await tester.pump();
    }
    await tester.sendEventToBinding(doigt.up());
    await _attendre(tester);
    final HistoriquePersonnel historique = conteneur.read(
      historiquePersonnelProvider,
    );
    expect(historique.retires, <String>{'trait-page-1'});
    expect(
      historique.retires,
      isNot(contains('trait-page-2')),
      reason: 'rien n est gomme sur la nouvelle page',
    );
    final OperationPersonnelle? derniere = historique.derniere(
      surLaSurface(page1),
    );
    expect(derniere, isA<TraitsGommesPersonnels>());
    expect(derniere!.surface, page1, reason: 'operation de la page 1');
    expect(historique.peutAnnuler(surLaSurface(page2)), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repaint cible : un trait en cours ne repeint pas les traits '
      'termines (plan V2 §13)', (WidgetTester tester) async {
    await _monter(tester, taille: _bureau);
    // Ecrire par les vrais boutons.
    await _outils(tester);
    await _taper(tester, _ecrire);
    await _reduire(tester);
    final Offset a = _surPage(tester, 0.2, 0.2);
    final Offset b = _surPage(tester, 0.6, 0.25);
    final TestPointer doigt = TestPointer(81);
    await tester.sendEventToBinding(doigt.down(a));
    await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, 0.1)!));
    await tester.pump();
    await tester.pump();
    final int avant = CoucheAnnotation.debugPeinturesTraits;
    for (int i = 2; i <= 12; i++) {
      await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, i / 12)!));
      await tester.pump();
    }
    expect(
      CoucheAnnotation.debugPeinturesTraits,
      avant,
      reason: 'onze points, aucun repeint des traits termines',
    );
    await tester.sendEventToBinding(doigt.up());
    await _attendre(tester);
    expect(
      CoucheAnnotation.debugPeinturesTraits,
      greaterThan(avant),
      reason: 'le trait pose rejoint les traits termines',
    );
  });

  testWidgets('Epaisseur : « Epais » peint un trait nettement plus large que '
      '« Fin » (mesure sur l image)', (WidgetTester tester) async {
    await _monter(tester, taille: _bureau, densite: 2);
    await _outils(tester);
    await _taper(tester, _ecrire);
    Future<void> choisir(String texte) => _taper(
      tester,
      find.descendant(
        of: find.byKey(EcritureSeance.cleEpaisseur),
        matching: find.text(texte),
      ),
    );
    await choisir(t.salle.seance.ecriture.fine);
    await _reduire(tester);
    await _glisser(
      tester,
      _surPage(tester, 0.15, 0.15),
      _surPage(tester, 0.45, 0.15),
    );
    await _outils(tester);
    await choisir(t.salle.seance.ecriture.epaisse);
    await _reduire(tester);
    await _glisser(
      tester,
      _surPage(tester, 0.55, 0.15),
      _surPage(tester, 0.85, 0.15),
    );
    final double y = _surPage(tester, 0, 0.15).dy;
    final int fin = await _encreVerticale(
      tester,
      _surPage(tester, 0.3, 0).dx,
      y - 20,
      y + 20,
    );
    final int epais = await _encreVerticale(
      tester,
      _surPage(tester, 0.7, 0).dx,
      y - 20,
      y + 20,
    );
    expect(fin, greaterThan(0), reason: 'le trait fin est peint');
    expect(epais, greaterThan(fin * 2.5), reason: 'fin $fin, epais $epais');
  });

  group('Palette courte : dans l ecran, rien de coupe', () {
    for (final (String nom, Size taille, double texte) cas
        in <(String, Size, double)>[
          ('390 x1', _telephone, 1),
          ('320 x2', const Size(320, 700), 2),
          ('1440 x1', _bureau, 1),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        await _monter(tester, taille: cas.$2, texte: cas.$3);
        // Ecrire retenu (le parcours par les Commandes est prouve plus haut ;
        // a 320 x2, la feuille des Commandes deborde deja a son ouverture,
        // defaut anterieur note au rapport).
        _conteneur(
          tester,
        ).read(etatOutilsProvider.notifier).choisirOutil(OutilDock.stylet);
        await _attendre(tester);
        expect(tester.takeException(), isNull);
        final Rect ecran = Offset.zero & cas.$2;
        for (final Finder f in <Finder>[
          _palette,
          _declencheur,
          find.byKey(BarreStylet.cleTerminer),
          find.byKey(BarreStylet.cleOutilActif),
        ]) {
          expect(f, findsOneWidget);
          final Rect r = tester.getRect(f);
          expect(
            ecran.intersect(r) == r,
            isTrue,
            reason: '$f dans l ecran : $r',
          );
        }
        // La palette ne recouvre pas le declencheur.
        expect(
          tester
              .getRect(find.byKey(BarreStylet.cleTerminer))
              .overlaps(tester.getRect(_declencheur)),
          isFalse,
        );
        // Rien d'enseignant chez l'eleve : ni palette ni outil.
      });
    }
  });
}
