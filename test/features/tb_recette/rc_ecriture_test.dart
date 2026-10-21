// TB-RC (revue croisee TB-R, lot L3-ecriture) : corrections de l'ecriture
// dans la salle, mesurees sur le rendu.
//
// - M5 : un seul « stylet detecte » ; stylet vu en lecture, puis Ecrire,
//   puis un doigt : aucun trait.
// - M6 : une seule voie d'Annuler ; Annuler de la palette emet exactement
//   un `tc.outils.trait_retire`.
// - m6 : l'outil retenu est annonce « selectionne ».
// - m14 : le deplacement de la page agrandie survit aux Commandes et a
//   Ecrire.
// - m15 : une gomme commencee a vide s'arrete au changement de page.
// - m16 : la gomme respecte la page et sa part visible.
// - m30 : le trait en cours a sa frontiere de repeint.
// - m31 : « Effacer les notes » vide l'historique meme si le panneau est
//   demonte pendant la confirmation.
// - m32 : Annuler n'est pas propose quand sa cible a disparu.
//
// Les parcours partent de la VRAIE salle de demonstration (`/demo/salle`,
// K-07), son depot en memoire.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart'
    show CapaciteRessource;
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart'
    show ModeAffichagePartage;
import 'package:rewayah_academy/core/tc_outils/ancrage_annotation.dart'
    show CarteDesBlocs;
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/evenements_outils.dart';
import 'package:rewayah_academy/core/tc_outils/operations_personnelles.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart';
import 'package:rewayah_academy/features/salle_seance/notes_deposees.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../capture/outil_capture.dart'
    show fixerVueCapture, hoteCapture, stabiliser;

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _entreeCommandes = find.byWidgetPredicate(
  (Widget w) =>
      w.key == DeclencheurCommandes.cle || w.key == BarreStylet.cleCommandes,
);
final Finder _onglets = find.byKey(CommandesPedagogiques.cleOnglets);
final Finder _ecrire = find.byKey(const ValueKey<String>('outil-ecrire'));
final Finder _palette = find.byKey(PaletteEcriture.cle);
final Finder _ecriture = find.byKey(EcritureSeance.cle);
final Finder _annulerPalette = find.descendant(
  of: _palette,
  matching: find.byKey(BarreStylet.cleAnnuler),
);

Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// La salle de /demo/salle, enseignant, montee seule.
Future<void> _monter(
  WidgetTester tester, {
  SituationTb situation = SituationTb.ped03,
  Size taille = _telephone,
  List<Override> surcharges = const <Override>[],
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: RoleSeance.enseignant, situation: situation),
      surcharges: surcharges,
    ),
  );
  await stabiliser(tester);
}

ProviderContainer _conteneur(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SalleSeance)));

AnnotationsMemoire _depot(WidgetTester tester) =>
    _conteneur(tester).read(portAnnotationsProvider) as AnnotationsMemoire;

List<TraitVectoriel> _traits(WidgetTester tester) => <TraitVectoriel>[
  for (final AnnotationLayer c in _depot(tester).couches) ...c.traits,
];

Offset _surPage(WidgetTester tester, double x, double y) {
  final Rect r = tester.getRect(_page);
  return r.topLeft + Offset(x * r.width, y * r.height);
}

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

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await _attendre(tester);
}

Future<void> _onglet(WidgetTester tester, String libelle) async {
  final Finder onglet = find.descendant(
    of: _onglets,
    matching: find.text(libelle),
  );
  if (onglet.evaluate().isNotEmpty) await _taper(tester, onglet);
}

/// Commandes > Outils.
Future<void> _outils(WidgetTester tester) async {
  await _taper(tester, _entreeCommandes);
  await _onglet(tester, t.salle.seance.commandes.ongletOutils);
}

Future<void> _reduire(WidgetTester tester) =>
    _taper(tester, find.byKey(PanneauSeance.cleReduire));

Future<void> _armerEcrire(WidgetTester tester) async {
  await _outils(tester);
  await _taper(tester, _ecrire);
  expect(
    _conteneur(tester).read(etatOutilsProvider).outilActif,
    OutilDock.stylet,
  );
  await _reduire(tester);
}

/// Zoom local a 200 % par les Commandes (onglet Support, Lecture).
Future<void> _zoom200(WidgetTester tester) async {
  await _taper(tester, _entreeCommandes);
  await _onglet(tester, t.salle.seance.commandes.ongletSupport);
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

/// La part de la page qui se trouve au centre de la surface (0,5 = page
/// centree) : la part regardee, quelle que soit la taille de la surface.
Offset _partAuCentre(WidgetTester tester) {
  final Rect surface = tester.getRect(find.byType(SurfacePageFixe));
  final Rect page = tester.getRect(_page);
  final Offset c = surface.center - page.topLeft;
  return Offset(c.dx / page.width, c.dy / page.height);
}

/// Une couche seule, au repere d'une page de [cadre].
Widget _couche(
  ProviderContainer conteneur,
  ContentPosition page,
  List<TraitVectoriel> traits, {
  Rect cadre = const Rect.fromLTWH(0, 0, 400, 500),
  Rect? zoneVisible,
}) => UncontrolledProviderScope(
  container: conteneur,
  child: hoteCapture(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: cadre.size,
        child: CoucheAnnotation(
          support: SupportPresente(
            resourceId: page.resourceId,
            capacites: const <CapaciteRessource>{CapaciteRessource.annotatable},
            blocs: CarteDesBlocs(cadre: cadre),
            ancrageCadre: page,
            modeAffichage: ModeAffichagePartage.page,
          ),
          contexte: const ContexteDock(groupeId: 'g'),
          traits: traits,
          repereDePage: true,
          zoneVisible: zoneVisible,
        ),
      ),
    ),
  ),
);

TraitVectoriel _horizontal(String id, ContentPosition page, double y) =>
    TraitVectoriel(
      id: id,
      ancrage: page,
      outil: OutilTrait.stylet,
      points: <PointNormalise>[PointNormalise(0, y), PointNormalise(1, y)],
    );

/// Un conteneur dont la gomme est armee, sur un depot en memoire.
ProviderContainer _gommeArmee() {
  final AnnotationsMemoire depot = AnnotationsMemoire('prof');
  addTearDown(depot.liberer);
  final ProviderContainer conteneur = ProviderContainer(
    overrides: <Override>[portAnnotationsProvider.overrideWithValue(depot)],
  );
  addTearDown(conteneur.dispose);
  conteneur.read(etatOutilsProvider.notifier)
    ..choisirOutil(OutilDock.stylet)
    ..choisirOutilTrait(OutilTrait.gomme);
  return conteneur;
}

void main() {
  testWidgets('M5 : stylet vu en lecture, puis Ecrire, puis un doigt : '
      'aucun trait, le doigt deplace la page', (WidgetTester tester) async {
    await _monter(tester, taille: _bureau);
    await _zoom200(tester);
    // Lecture : le stylet deplace la page agrandie (aucun trait).
    final Offset a = _surPage(tester, 0.5, 0.5);
    await _glisser(
      tester,
      a,
      a + const Offset(0, -40),
      appareil: PointerDeviceKind.stylus,
      id: 61,
    );
    expect(_traits(tester), isEmpty, reason: 'lecture');
    await _armerEcrire(tester);
    final Rect avant = tester.getRect(_page);
    // Un doigt (la paume) : il deplace, il n'ecrit pas.
    await _glisser(
      tester,
      _surPage(tester, 0.4, 0.5),
      _surPage(tester, 0.6, 0.45),
    );
    expect(_traits(tester), isEmpty, reason: 'le doigt n ecrit pas');
    expect(
      tester.getRect(_page),
      isNot(avant),
      reason: 'le doigt deplace la page',
    );
    // Le stylet, lui, ecrit.
    await _glisser(
      tester,
      _surPage(tester, 0.3, 0.5),
      _surPage(tester, 0.6, 0.52),
      appareil: PointerDeviceKind.stylus,
      id: 62,
    );
    expect(_traits(tester), hasLength(1), reason: 'le stylet ecrit');
  });

  testWidgets('M6 : Annuler depuis la palette emet exactement un '
      'tc.outils.trait_retire, par le rappel de la couche', (
    WidgetTester tester,
  ) async {
    final List<EvenementOutil> emis = <EvenementOutil>[];
    await _monter(
      tester,
      surcharges: <Override>[
        diffusionEcritureProvider.overrideWithValue(emis.add),
      ],
    );
    await _armerEcrire(tester);
    await _glisser(
      tester,
      _surPage(tester, 0.2, 0.2),
      _surPage(tester, 0.6, 0.25),
    );
    final String id = _traits(tester).single.id;
    // Le trait pose part une fois sur le canal fiable (ses paquets en cours
    // passent sur le canal ephemere).
    expect(
      emis
          .where((EvenementOutil e) => e.type != 'tc.outils.trait_en_cours')
          .map((EvenementOutil e) => e.type),
      <String>['tc.outils.trait_termine'],
    );
    emis.clear();
    await _taper(tester, _annulerPalette);
    expect(_traits(tester), isEmpty);
    expect(emis, hasLength(1));
    expect(emis.single.type, 'tc.outils.trait_retire');
    expect((emis.single as EvenementTraitRetire).traitId, id);
    expect(_annulerPalette, findsNothing, reason: 'plus rien a annuler');
  });

  testWidgets('M6 (ERR-01) : Annuler de la palette leve la marque « non '
      'partage » du trait annule', (WidgetTester tester) async {
    await _monter(tester, situation: SituationTb.err01);
    await _armerEcrire(tester);
    await _glisser(
      tester,
      _surPage(tester, 0.3, 0.3),
      _surPage(tester, 0.6, 0.35),
    );
    final String pose = _traits(tester).single.id;
    expect(_conteneur(tester).read(traitsNonPartagesProvider), contains(pose));
    await _taper(tester, _annulerPalette);
    expect(
      _conteneur(tester).read(traitsNonPartagesProvider),
      isNot(contains(pose)),
    );
  });

  testWidgets('m6 : l outil retenu est annonce selectionne', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(tester, taille: _bureau);
    await _outils(tester);
    await _taper(tester, _ecrire);
    Finder outil(OutilTrait o) => find.descendant(
      of: _ecriture,
      matching: find.byKey(BarreStylet.cleOutil(o)),
    );
    expect(
      tester.getSemantics(outil(OutilTrait.stylet)),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(outil(OutilTrait.gomme)),
      isNot(isSemantics(isSelected: true)),
    );
    await _taper(tester, outil(OutilTrait.gomme));
    expect(
      tester.getSemantics(outil(OutilTrait.gomme)),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(outil(OutilTrait.stylet)),
      isNot(isSemantics(isSelected: true)),
    );
    semantique.dispose();
  });

  testWidgets('m14 : le deplacement de la page agrandie survit aux '
      'Commandes et a Ecrire', (WidgetTester tester) async {
    await _monter(tester, taille: _bureau);
    await _zoom200(tester);
    final Offset centre = _partAuCentre(tester);
    final Offset a = _surPage(tester, 0.5, 0.5);
    await _glisser(tester, a, a + const Offset(0, -120));
    final Offset deplace = _partAuCentre(tester);
    expect(
      deplace.dy - centre.dy,
      greaterThan(0.03),
      reason: 'la page a ete deplacee',
    );
    // Commandes ouvertes : la surface change de taille, la part regardee
    // reste la meme.
    await _taper(tester, _entreeCommandes);
    expect(
      _partAuCentre(tester).dy,
      moreOrLessEquals(deplace.dy, epsilon: 0.01),
    );
    await _onglet(tester, t.salle.seance.commandes.ongletOutils);
    await _taper(tester, _ecrire);
    await _reduire(tester);
    expect(
      _partAuCentre(tester).dy,
      moreOrLessEquals(deplace.dy, epsilon: 0.01),
    );
  });

  testWidgets('m15 : une gomme commencee a vide s arrete au changement de '
      'page, rien n est gomme sur la nouvelle', (WidgetTester tester) async {
    final ProviderContainer conteneur = _gommeArmee();
    final VueSeance vue = DonneesSeanceDemo.vueTb(
      RoleSeance.enseignant,
      SituationTb.ped03,
    );
    final ContentPosition page1 = vue.ancrageSurface!;
    final ContentPosition page2 = vue
        .copyWith(supportPresente: vue.supportPresente!.aLaPage(2))
        .ancrageSurface!;
    // Page 1 vide : la gomme ne retire rien avant le changement.
    fixerVueCapture(tester, const Size(400, 500), 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _couche(conteneur, page1, const <TraitVectoriel>[]),
    );
    await _attendre(tester);
    final TestPointer doigt = TestPointer(81);
    await tester.sendEventToBinding(doigt.down(const Offset(200, 120)));
    for (int i = 1; i <= 6; i++) {
      await tester.sendEventToBinding(doigt.move(Offset(200, 120 + i * 10.0)));
      await tester.pump();
    }
    await tester.pumpWidget(
      _couche(conteneur, page2, <TraitVectoriel>[
        _horizontal('trait-page-2', page2, 0.7),
      ]),
    );
    await tester.pump();
    for (int i = 1; i <= 12; i++) {
      await tester.sendEventToBinding(doigt.move(Offset(200, 180 + i * 20.0)));
      await tester.pump();
    }
    await tester.sendEventToBinding(doigt.up());
    await _attendre(tester);
    expect(
      conteneur.read(historiquePersonnelProvider).retires,
      isEmpty,
      reason: 'rien n est gomme sur la nouvelle page',
    );
    // Un nouveau geste sur la page 2 gomme normalement.
    await tester.sendEventToBinding(doigt.down(const Offset(200, 300)));
    for (int i = 1; i <= 6; i++) {
      await tester.sendEventToBinding(doigt.move(Offset(200, 300 + i * 15.0)));
      await tester.pump();
    }
    await tester.sendEventToBinding(doigt.up());
    await _attendre(tester);
    expect(conteneur.read(historiquePersonnelProvider).retires, <String>{
      'trait-page-2',
    });
  });

  testWidgets('m16 : la gomme ne retire rien hors de la part visible de la '
      'page', (WidgetTester tester) async {
    final ProviderContainer conteneur = _gommeArmee();
    const ContentPosition page = ContentPosition.page(resourceId: 'r', page: 1);
    // Seule la moitie haute de la page se voit (page agrandie, rognee).
    fixerVueCapture(tester, const Size(400, 500), 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _couche(conteneur, page, <TraitVectoriel>[
        _horizontal('cache', page, 0.8),
        _horizontal('visible', page, 0.2),
      ], zoneVisible: const Rect.fromLTWH(0, 0, 400, 250)),
    );
    await _attendre(tester);
    Future<void> gommer(double y0, double y1) async {
      final TestPointer doigt = TestPointer(91);
      await tester.sendEventToBinding(doigt.down(Offset(200, y0)));
      for (int i = 1; i <= 8; i++) {
        await tester.sendEventToBinding(
          doigt.move(Offset(200, y0 + (y1 - y0) * i / 8)),
        );
        await tester.pump();
      }
      await tester.sendEventToBinding(doigt.up());
      await _attendre(tester);
    }

    // Commencee dans la part visible, la gomme descend sur le trait cache
    // (y = 400) : il reste.
    await gommer(200, 440);
    expect(conteneur.read(historiquePersonnelProvider).retires, isEmpty);
    // Le trait visible (y = 100), lui, se gomme.
    await gommer(60, 140);
    expect(conteneur.read(historiquePersonnelProvider).retires, <String>{
      'visible',
    });
  });

  testWidgets('m30 : le trait en cours est peint sous sa propre frontiere '
      'de repeint', (WidgetTester tester) async {
    await _monter(tester);
    await _armerEcrire(tester);
    final Finder apercu = find.descendant(
      of: find.byKey(SurfacePageFixe.cleCouche),
      matching: find.byKey(CoucheAnnotation.cleApercu),
    );
    expect(apercu, findsOneWidget);
    final RenderObject frontiere = tester.renderObject(apercu);
    expect(frontiere.isRepaintBoundary, isTrue);
    expect(
      (frontiere as RenderProxyBox).child,
      isA<RenderCustomPaint>(),
      reason: 'la frontiere ne porte que le peintre de l apercu',
    );
    // Pendant un trait, seule cette frontiere est a repeindre.
    final Offset a = _surPage(tester, 0.2, 0.2);
    final TestPointer doigt = TestPointer(71);
    await tester.sendEventToBinding(doigt.down(a));
    await tester.sendEventToBinding(doigt.move(a + const Offset(20, 0)));
    await tester.pump();
    await tester.sendEventToBinding(doigt.move(a + const Offset(40, 4)));
    final RenderObject page = tester.renderObject(_page);
    expect(frontiere.debugNeedsPaint, isTrue);
    expect(page.debugNeedsPaint, isFalse, reason: 'la page n est pas repeinte');
    await tester.pump();
    await tester.sendEventToBinding(doigt.up());
    await _attendre(tester);
  });

  testWidgets('m31 : la salle se recompose pendant la confirmation '
      '« Effacer les notes » : l historique de la page est vide quand meme', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _armerEcrire(tester);
    await _glisser(
      tester,
      _surPage(tester, 0.2, 0.2),
      _surPage(tester, 0.6, 0.25),
    );
    final ContentPosition? surface = tester
        .widget<SurfacePageFixe>(find.byType(SurfacePageFixe))
        .vue
        .ancrageSurface;
    bool annulable() =>
        _conteneur(tester)
            .read(historiquePersonnelProvider)
            .peutAnnuler(surLaSurface(surface));
    expect(annulable(), isTrue);
    await _taper(tester, _entreeCommandes);
    await _onglet(tester, t.salle.seance.commandes.ongletSupport);
    final State<StatefulWidget> panneau = tester.state(
      find.byType(CommandesPedagogiques),
    );
    await _taper(tester, find.byKey(CommandesPedagogiques.cleMenu));
    await _taper(tester, find.text(t.salle.seance.rangement.effacer).last);
    // La confirmation est ouverte ; l'ecran passe au bureau : le panneau
    // de la feuille est demonte, une colonne le remplace.
    fixerVueCapture(tester, _bureau, 1);
    await _attendre(tester);
    expect(panneau.mounted, isFalse, reason: 'panneau demonte');
    await _taper(
      tester,
      find.widgetWithText(ActionPrincipale, t.salle.seance.rangement.effacer),
    );
    expect(_traits(tester), isEmpty, reason: 'les notes sont effacees');
    expect(annulable(), isFalse, reason: 'Annuler ne les remet pas');
  });

  testWidgets('m32 : la cible d Annuler disparait (gommee ailleurs) : '
      'Annuler n est plus propose', (WidgetTester tester) async {
    await _monter(tester);
    await _armerEcrire(tester);
    await _glisser(
      tester,
      _surPage(tester, 0.2, 0.2),
      _surPage(tester, 0.6, 0.25),
    );
    expect(_annulerPalette, findsOneWidget);
    final AnnotationsMemoire depot = _depot(tester);
    final AnnotationLayer couche = depot.couches.single;
    // Un autre (l'enseignant, un autre appareil) retire le trait.
    await tester.runAsync(
      () => depot.retirerTrait(couche.id, couche.traits.single.id),
    );
    await _attendre(tester);
    expect(_traits(tester), isEmpty);
    expect(_annulerPalette, findsNothing, reason: 'plus de cible');
    expect(tester.takeException(), isNull);
  });
}
