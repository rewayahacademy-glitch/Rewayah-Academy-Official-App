// TB-7a (plan V2 §7, §9, §13 ; TB19, TB21) : le calque d'annotation au
// repere de la page.
//
// Ce qui est mesure ici est le RENDU : le rectangle de la page a l'ecran
// (zoom compris, `tester.getRect`), le rectangle de la couche montee, et le
// `PointNormalise` effectivement range par la couche apres un vrai geste.
// Aucune attente n'est recalculee avec le code teste : le point vise est
// pris sur le rectangle de la page tel qu'il s'affiche.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart' show OutilDock;
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/repere_page.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../capture/outil_capture.dart' hide stabiliser;

/// L'outil d'ecriture arme (TB-7b le donnera par « Ecrire ») : sans lui,
/// rien n'ecrit (TB-STYLET-1).
class _ControleurArme extends ControleurOutils {
  @override
  EtatOutils build() => const EtatOutils(outilActif: OutilDock.stylet);
}

final double _ratio = DonneesSeanceDemo.supportPageFixe.ratio;

final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _couche = find.byKey(SurfacePageFixe.cleCouche);

/// Les ecrans mesures : 390, 768, 1440, portrait et paysage.
const List<(String, Size)> _ecrans = <(String, Size)>[
  ('390 portrait', Size(390, 844)),
  ('390 paysage', Size(844, 390)),
  ('768 portrait', Size(768, 1024)),
  ('768 paysage', Size(1024, 768)),
  ('1440 paysage', Size(1440, 900)),
  ('1440 portrait', Size(900, 1440)),
];

const PointNormalise _depart = PointNormalise(0.40, 0.45);
const PointNormalise _arrivee = PointNormalise(0.55, 0.52);

Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Le point de l'ecran sur [p] de la page, lu sur le rendu.
Offset _surEcran(WidgetTester tester, PointNormalise p) {
  final Rect r = tester.getRect(_page);
  return r.topLeft + Offset(p.x * r.width, p.y * r.height);
}

/// Un geste au doigt de [a] a [b], en six pas.
Future<void> _tracer(WidgetTester tester, Offset a, Offset b) async {
  final TestPointer doigt = TestPointer(7);
  await tester.sendEventToBinding(doigt.down(a));
  for (int i = 1; i <= 6; i++) {
    await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, i / 6)!));
    await tester.pump();
  }
  await tester.sendEventToBinding(doigt.up());
  await tester.pump();
  await tester.pump();
}

List<TraitVectoriel> _traits(AnnotationsMemoire depot) => <TraitVectoriel>[
  for (final AnnotationLayer c in depot.couches) ...c.traits,
];

/// La surface seule, plein ecran, enseignant en PED-03.
Future<AnnotationsMemoire> _monterSurface(
  WidgetTester tester,
  Size ecran, {
  double zoom = 1,
  RoleSeance role = RoleSeance.enseignant,
}) async {
  fixerVueCapture(tester, ecran, 1);
  addTearDown(tester.view.reset);
  final AnnotationsMemoire depot = AnnotationsMemoire('prof-demo');
  addTearDown(depot.liberer);
  final VueSeance vue = DonneesSeanceDemo.vueTb(role, SituationTb.ped03);
  await tester.pumpWidget(
    hoteCapture(
      SurfacePageFixe(vue: vue, surface: vue.vueSurface, zoom: zoom),
      surcharges: <Override>[
        portAnnotationsProvider.overrideWithValue(depot),
        etatOutilsProvider.overrideWith(_ControleurArme.new),
      ],
    ),
  );
  await _attendre(tester);
  return depot;
}

/// La salle de demonstration (`/demo/salle?role=…&tb=ped03`), outil arme.
Future<AnnotationsMemoire> _monterSalle(
  WidgetTester tester,
  Size ecran,
  RoleSeance role, {
  SituationTb situation = SituationTb.ped03,
  bool arme = true,
}) async {
  fixerVueCapture(tester, ecran, 1);
  addTearDown(tester.view.reset);
  final AnnotationsMemoire depot = AnnotationsMemoire('demo');
  addTearDown(depot.liberer);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: role, situation: situation),
      surcharges: <Override>[
        portAnnotationsProvider.overrideWithValue(depot),
        if (arme) etatOutilsProvider.overrideWith(_ControleurArme.new),
      ],
    ),
  );
  await _attendre(tester);
  return depot;
}

void _memePoint(PointNormalise lu, PointNormalise attendu, String raison) {
  expect(lu.x, moreOrLessEquals(attendu.x, epsilon: 1e-6), reason: raison);
  expect(lu.y, moreOrLessEquals(attendu.y, epsilon: 1e-6), reason: raison);
}

void main() {
  group('ReperePage : toScene, offset de BoxFit.contain, normalisation', () {
    for (final (String nom, Size boite) in _ecrans) {
      for (final double zoom in <double>[1, 2]) {
        test('$nom, zoom $zoom : aller-retour exact', () {
          final ReperePage r = ReperePage.de(
            ratio: _ratio,
            boite: boite,
            zoom: zoom,
          );
          final PointNormalise? lu = r.versPage(r.versSurface(_depart));
          expect(lu, isNotNull);
          _memePoint(lu!, _depart, 'meme point de page');
        });
      }
    }

    test('deplacement (pan) : toScene retire le zoom ET le deplacement', () {
      final ReperePage r = ReperePage.de(
        ratio: _ratio,
        boite: const Size(390, 700),
        zoom: 2,
        deplacement: const Offset(40, -30),
      );
      final Offset ecran = r.versSurface(_arrivee);
      _memePoint(r.versPage(ecran)!, _arrivee, 'pan et zoom inverses');
      // Le meme ecran lu sans le deplacement donnerait un autre point.
      final ReperePage sansPan = ReperePage.de(
        ratio: _ratio,
        boite: const Size(390, 700),
        zoom: 2,
      );
      expect(sansPan.versPage(ecran), isNot(equals(r.versPage(ecran))));
    });

    test('un point de la marge est rejete, jamais rabattu sur le bord', () {
      final ReperePage r = ReperePage.de(
        ratio: _ratio,
        boite: const Size(1440, 900),
      );
      expect(r.page.left, greaterThan(0), reason: 'marges laterales');
      expect(r.versPage(Offset(r.page.left / 2, 450)), isNull);
      expect(r.versPage(Offset(r.page.right + 10, 450)), isNull);
      _memePoint(r.versPage(r.page.center)!, const PointNormalise(0.5, 0.5), 'centre');
    });
  });

  group('geste reel : meme point normalise sur tous les ecrans', () {
    for (final (String nom, Size ecran) in _ecrans) {
      for (final double zoom in <double>[1, 2]) {
        testWidgets('$nom, zoom $zoom', (WidgetTester tester) async {
          final AnnotationsMemoire depot = await _monterSurface(
            tester,
            ecran,
            zoom: zoom,
          );
          // La couche couvre exactement la page affichee (zoom compris) :
          // image et encre dans la meme transformation.
          expect(tester.getRect(_couche), tester.getRect(_page));
          final Rect base = rectanglePage(ratio: _ratio, boite: ecran);
          expect(
            tester.getRect(_page).width,
            moreOrLessEquals(base.width * zoom, epsilon: 1e-6),
            reason: 'la page est lue au zoom $zoom',
          );

          await _tracer(
            tester,
            _surEcran(tester, _depart),
            _surEcran(tester, _arrivee),
          );

          final TraitVectoriel trait = _traits(depot).single;
          _memePoint(trait.points.last, _arrivee, 'point final du geste');
          // Chaque point range est sur le segment vise, dans la page.
          for (final PointNormalise p in trait.points) {
            final double croix =
                (_arrivee.x - _depart.x) * (p.y - _depart.y) -
                (_arrivee.y - _depart.y) * (p.x - _depart.x);
            expect(croix.abs(), lessThan(1e-6), reason: '$p sur le segment');
          }
          expect(
            trait.ancrage,
            DonneesSeanceDemo.vueTb(
              RoleSeance.enseignant,
              SituationTb.ped03,
            ).ancrageSurface,
            reason: 'ancre a la page presentee (support, version, numero)',
          );
        });
      }
    }

    testWidgets('un geste commence dans la marge est rejete', (
      WidgetTester tester,
    ) async {
      final AnnotationsMemoire depot = await _monterSurface(
        tester,
        const Size(1440, 900),
      );
      final Rect r = tester.getRect(_page);
      expect(r.left, greaterThan(0), reason: 'la page laisse des marges');
      await _tracer(tester, Offset(r.left / 2, r.center.dy), r.center);
      expect(_traits(depot), isEmpty);
    });

    testWidgets('un geste qui sort de la page n est pas rabattu sur le bord', (
      WidgetTester tester,
    ) async {
      final AnnotationsMemoire depot = await _monterSurface(
        tester,
        const Size(1440, 900),
      );
      final Rect r = tester.getRect(_page);
      await _tracer(
        tester,
        r.center,
        Offset(r.right + (1440 - r.right) / 2, r.center.dy),
      );
      final TraitVectoriel trait = _traits(depot).single;
      for (final PointNormalise p in trait.points) {
        expect(p.x, lessThan(1), reason: 'aucun point colle au bord : $p');
      }
    });
  });

  group('dans la vraie salle (/demo/salle)', () {
    for (final Size ecran in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('enseignant ${ecran.width.toInt()} : le trait se range au '
          'repere de la page', (WidgetTester tester) async {
        final AnnotationsMemoire depot = await _monterSalle(
          tester,
          ecran,
          RoleSeance.enseignant,
        );
        expect(tester.widget(_couche), isA<CoucheAnnotation>());
        expect(tester.getRect(_couche), tester.getRect(_page));
        await _tracer(
          tester,
          _surEcran(tester, _depart),
          _surEcran(tester, _arrivee),
        );
        _memePoint(
          _traits(depot).single.points.last,
          _arrivee,
          'meme point qu en surface seule',
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('eleve sans autorisation : outil arme, rien ne s ecrit', (
      WidgetTester tester,
    ) async {
      final AnnotationsMemoire depot = await _monterSalle(
        tester,
        const Size(390, 844),
        RoleSeance.eleve,
      );
      expect(_couche, findsOneWidget, reason: 'les notes se lisent');
      await _tracer(
        tester,
        _surEcran(tester, _depart),
        _surEcran(tester, _arrivee),
      );
      expect(_traits(depot), isEmpty);
    });

    testWidgets('outil non arme : ni le doigt ni le stylet n ecrivent', (
      WidgetTester tester,
    ) async {
      final AnnotationsMemoire depot = await _monterSalle(
        tester,
        const Size(1440, 900),
        RoleSeance.enseignant,
        arme: false,
      );
      for (final PointerDeviceKind appareil in <PointerDeviceKind>[
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
      ]) {
        final TestPointer p = TestPointer(9, appareil);
        final Offset a = _surEcran(tester, _depart);
        final Offset b = _surEcran(tester, _arrivee);
        await tester.sendEventToBinding(p.down(a));
        for (int i = 1; i <= 6; i++) {
          await tester.sendEventToBinding(p.move(Offset.lerp(a, b, i / 6)!));
          await tester.pump();
        }
        await tester.sendEventToBinding(p.up());
        await tester.pump();
      }
      expect(_traits(depot), isEmpty);
    });

    testWidgets('le cercle de demonstration reste au meme endroit de la '
        'page apres le zoom', (WidgetTester tester) async {
      await _monterSalle(tester, const Size(1440, 900), RoleSeance.enseignant);
      // Les Commandes ouvertes d'abord : leur colonne change la place de la
      // surface ; la mesure « avant » se prend a place egale.
      await tester.tap(find.byKey(DeclencheurCommandes.cle));
      await _attendre(tester);
      final Rect avant = tester.getRect(_page);
      expect(tester.getRect(_couche), avant);
      final Offset centreAvant = _surEcran(
        tester,
        DonneesSeanceDemo.centreCercle,
      );
      expect(avant.contains(centreAvant), isTrue);

      // Zoom par le vrai bouton des Commandes (Lecture), jusqu'a 200 %.
      final Finder plus = find.byWidgetPredicate(
        (Widget w) =>
            w is Pressable && w.libelleSemantique == t.salle.seance.zoomPlus,
      );
      for (int i = 0; i < 10; i++) {
        await tester.tap(plus);
        await tester.pump();
      }
      await _attendre(tester);
      expect(find.text(t.salle.seance.zoomValeur(valeur: 200)), findsWidgets);

      final Rect apres = tester.getRect(_page);
      expect(apres.width, moreOrLessEquals(avant.width * 2, epsilon: 1e-6));
      // La couche suit la page : le cercle, peint en part de la couche,
      // reste sur le meme endroit de la page.
      expect(tester.getRect(_couche), apres);
      final RenderBox couche = tester.renderObject(_couche);
      final Offset centreCouche = couche.localToGlobal(
        Offset(
          DonneesSeanceDemo.centreCercle.x * couche.size.width,
          DonneesSeanceDemo.centreCercle.y * couche.size.height,
        ),
      );
      final Offset centrePage = _surEcran(
        tester,
        DonneesSeanceDemo.centreCercle,
      );
      expect((centreCouche - centrePage).distance, lessThan(1e-6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Support seul : le calque reste monte, ses notes cachees', (
      WidgetTester tester,
    ) async {
      await _monterSalle(
        tester,
        const Size(1440, 900),
        RoleSeance.enseignant,
        situation: SituationTb.ped02,
      );
      expect(_couche, findsOneWidget);
      expect(
        tester
            .widget<Visibility>(find.byKey(SurfacePageFixe.cleCalque))
            .visible,
        isFalse,
      );
    });
  });

  group('notes de la page montree seulement', () {
    test('un trait d une autre page ne se peint pas', () {
      final VueSeance vue = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.ped03,
      );
      expect(vue.notesAffichees, hasLength(1));
      final VueSeance page2 = vue.copyWith(
        supportPresente: vue.supportPresente!.aLaPage(2),
      );
      expect(page2.notesAffichees, isEmpty);
    });

    test('le tableau libre n herite pas des notes du support (TB5)', () {
      final VueSeance libre =
          DonneesSeanceDemo.vueTb(
            RoleSeance.enseignant,
            SituationTb.ped01,
          ).copyWith(
            notesSurface: <TraitVectoriel>[
              DonneesSeanceDemo.traitDemonstration,
            ],
          );
      expect(libre.notesAffichees, isEmpty);
    });
  });
}
