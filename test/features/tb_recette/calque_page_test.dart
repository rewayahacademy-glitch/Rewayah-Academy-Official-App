// TB-7a (plan V2 §7, §9, §13 ; TB19, TB21) : le calque d'annotation au
// repere de la page.
//
// Ce qui est mesure ici est le RENDU : le rectangle de la page a l'ecran
// (zoom compris, `tester.getRect`), le rectangle de la couche montee, et le
// `PointNormalise` effectivement range par la couche apres un vrai geste.
// Aucune attente n'est recalculee avec le code teste : le point vise est
// pris sur le rectangle de la page tel qu'il s'affiche.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart'
    show LibellesGroupe;
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart'
    show OutilDock;
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/repere_page.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart'
    show SalleSeance;
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';
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

/// L'entree « Commandes » : le declencheur, ou, pendant l'ecriture, le
/// dernier bouton de la palette courte qui a pris sa place (TB-7b).
final Finder _entreeCommandes = find.byWidgetPredicate(
  (Widget w) =>
      w.key == DeclencheurCommandes.cle || w.key == BarreStylet.cleCommandes,
);

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

/// TB-7b : outil arme, les Commandes s'ouvrent sur « Outils » ; la
/// Lecture (zoom) est sous « Support ».
Future<void> _ongletSupport(WidgetTester tester) async {
  final Finder support = find.descendant(
    of: find.byKey(CommandesPedagogiques.cleOnglets),
    matching: find.text(t.salle.seance.commandes.ongletSupport),
  );
  if (support.evaluate().isEmpty) return;
  await tester.tap(support);
  await tester.pump();
}

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
      surcharges: <Override>[portAnnotationsProvider.overrideWithValue(depot)],
    ),
  );
  await _attendre(tester);
  // TB-RC (m21) : les outils sont ceux de la salle ; l'outil est arme dans
  // sa portee, pas a la racine.
  if (arme) {
    ProviderScope.containerOf(tester.element(find.byType(SalleSeance)))
        .read(etatOutilsProvider.notifier)
        .choisirOutil(OutilDock.stylet);
    await _attendre(tester);
  }
  return depot;
}

void _memePoint(PointNormalise lu, PointNormalise attendu, String raison) {
  expect(lu.x, moreOrLessEquals(attendu.x, epsilon: 1e-6), reason: raison);
  expect(lu.y, moreOrLessEquals(attendu.y, epsilon: 1e-6), reason: raison);
}

/// L'image rendue de la coquille (`cadreCapture`), lue pixel a pixel : ce
/// qui est mesure est ce qui est peint, pas ce que le code croit peindre.
class _Photo {
  _Photo._(this._octets, this._largeur, this._densite);

  static Future<_Photo> prendre(WidgetTester tester) async {
    final double densite = tester.view.devicePixelRatio;
    final RenderRepaintBoundary cadre = tester.renderObject(
      find.byKey(cadreCapture),
    );
    final (ByteData, int)? lu = await tester.runAsync<(ByteData, int)>(
      () async {
        final ui.Image image = await cadre.toImage(pixelRatio: densite);
        final ByteData? brut = await image.toByteData();
        final int largeur = image.width;
        image.dispose();
        return (brut!, largeur);
      },
    );
    return _Photo._(lu!.$1, lu.$2, densite);
  }

  final ByteData _octets;
  final int _largeur;
  final double _densite;

  /// Somme des trois canaux (765 : blanc) au point logique [x], [y].
  int _clarte(double x, double y) {
    final int i =
        ((y * _densite).round() * _largeur + (x * _densite).round()) * 4;
    return _octets.getUint8(i) +
        _octets.getUint8(i + 1) +
        _octets.getUint8(i + 2);
  }

  /// Le plus grand ecart de clarte avec [autre] dans [zone], pas de 1.
  int ecartMax(_Photo autre, Rect zone) {
    int ecart = 0;
    for (double y = zone.top; y < zone.bottom; y++) {
      for (double x = zone.left; x < zone.right; x++) {
        ecart = math.max(ecart, (_clarte(x, y) - autre._clarte(x, y)).abs());
      }
    }
    return ecart;
  }

  /// Le milieu de l'encre sombre sur la ligne [y], entre [debut] et [fin]
  /// (abscisses logiques), pondere par l'assombrissement. `null` si rien
  /// n'est peint la.
  double? milieuEncre(double y, double debut, double fin) {
    double poids = 0;
    double somme = 0;
    for (double x = debut; x <= fin; x += 1 / _densite) {
      final int sombre = 765 - _clarte(x, y);
      if (sombre > 60) {
        poids += sombre;
        somme += sombre * x;
      }
    }
    return poids == 0 ? null : somme / poids;
  }
}

/// L'abscisse, a l'ecran, du bord droit du cercle de demonstration sur la
/// ligne de son centre, mesuree sur l'image ; et celle ou la page la place.
Future<(double, double)> _bordDroitCercle(WidgetTester tester) async {
  final Rect page = tester.getRect(_page);
  const PointNormalise c = DonneesSeanceDemo.centreCercle;
  const double r = DonneesSeanceDemo.rayonCercle;
  final double attendu = page.left + (c.x + r) * page.width;
  final double y = page.top + c.y * page.height;
  final _Photo photo = await _Photo.prendre(tester);
  final double? lu = photo.milieuEncre(
    y,
    attendu - 0.06 * page.width,
    attendu + 0.06 * page.width,
  );
  expect(lu, isNotNull, reason: 'le cercle est peint pres de $attendu');
  return (lu!, attendu);
}

void main() {
  group('ReperePage (utilitaire de reference) : toScene, offset de '
      'BoxFit.contain, normalisation', () {
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
      _memePoint(
        r.versPage(r.page.center)!,
        const PointNormalise(0.5, 0.5),
        'centre',
      );
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

    // UX_REVIEW_TB n. 20 : « trait qui sort de la page arrete au bord, sans
    // point rabattu » ; plan §9.4 : pas de trait inattendu. Le doigt sort a
    // droite, longe la page dehors sur toute sa hauteur et revient dedans
    // sans se lever : rien ne doit relier la sortie au retour.
    testWidgets('un geste qui sort de la page s arrete a la sortie, un '
        'retour dans la page ne trace rien', (WidgetTester tester) async {
      final AnnotationsMemoire depot = await _monterSurface(
        tester,
        const Size(1440, 900),
      );
      final Rect r = tester.getRect(_page);
      expect(1440 - r.right, greaterThan(40), reason: 'marge a droite');
      final double haut = r.top + 100;
      final double bas = r.bottom - 100;
      final Rect bande = Rect.fromLTRB(r.right - 80, haut + 40, r.right, bas);
      final _Photo avant = await _Photo.prendre(tester);

      final TestPointer doigt = TestPointer(11);
      Future<void> aller(Offset o) async {
        await tester.sendEventToBinding(doigt.move(o));
        await tester.pump();
      }

      await tester.sendEventToBinding(doigt.down(Offset(r.right - 160, haut)));
      // Dans la page, vers la droite.
      for (final double dx in <double>[120, 80, 60, 40, 20]) {
        await aller(Offset(r.right - dx, haut));
      }
      // Dehors : a droite, puis le long de la page jusqu'en bas.
      await aller(Offset(r.right + 20, haut));
      for (int i = 1; i <= 6; i++) {
        await aller(Offset(r.right + 30, haut + (bas - haut) * i / 6));
      }
      // Retour dans la page, doigt toujours pose, et quelques pas dedans.
      for (final double dx in <double>[20, 40, 60, 80]) {
        await aller(Offset(r.right - dx, bas));
      }
      // Rendu pendant le geste : aucune encre dans la bande que le doigt a
      // longee dehors ni la ou il est revenu.
      final _Photo pendant = await _Photo.prendre(tester);
      expect(
        pendant.ecartMax(avant, bande),
        lessThan(30),
        reason: 'aucun trait ne relie la sortie au retour',
      );

      await tester.sendEventToBinding(doigt.up());
      await tester.pump();
      await tester.pump();

      final TraitVectoriel trait = _traits(depot).single;
      final double yHaut = (haut - r.top) / r.height;
      final double xSortie = (r.width - 20) / r.width;
      for (final PointNormalise p in trait.points) {
        expect(
          p.y,
          moreOrLessEquals(yHaut, epsilon: 1e-6),
          reason: 'aucun point apres la sortie : $p',
        );
        expect(p.x, lessThanOrEqualTo(xSortie + 1e-6), reason: 'non rabattu');
      }
      _memePoint(
        trait.points.last,
        PointNormalise(xSortie, yHaut),
        'le trait finit au dernier point pose dans la page',
      );
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
      await tester.tap(_entreeCommandes);
      await _attendre(tester);
      await _ongletSupport(tester);
      final Rect avant = tester.getRect(_page);
      expect(tester.getRect(_couche), avant);
      final Offset centreAvant = _surEcran(
        tester,
        DonneesSeanceDemo.centreCercle,
      );
      expect(avant.contains(centreAvant), isTrue);
      final (double luAvant, double attenduAvant) = await _bordDroitCercle(
        tester,
      );
      expect(luAvant, moreOrLessEquals(attenduAvant, epsilon: 1.5));

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
      expect(
        find.text(
          LibellesGroupe.valeurSeule(t.salle.seance.zoomValeur(valeur: 200)),
        ),
        findsWidgets,
      );

      final Rect apres = tester.getRect(_page);
      expect(apres.width, moreOrLessEquals(avant.width * 2, epsilon: 1e-6));
      expect(tester.getRect(_couche), apres);
      // Mesure sur l'image : l'encre du cercle est la ou la page zoomee
      // place son bord droit, et elle a bouge avec la page.
      final (double luApres, double attenduApres) = await _bordDroitCercle(
        tester,
      );
      expect(luApres, moreOrLessEquals(attenduApres, epsilon: 1.5));
      expect(
        (luApres - luAvant).abs(),
        greaterThan(20),
        reason: 'le zoom deplace le bord du cercle avec la page',
      );
      expect(tester.takeException(), isNull);
    });

    // §9 : « un changement d'orientation recalcule l'affichage, pas les
    // traits stockes ». La meme salle, montee une fois, tourne.
    testWidgets('rotation : le cercle suit la page, rien de stocke ne change', (
      WidgetTester tester,
    ) async {
      final AnnotationsMemoire depot = await _monterSalle(
        tester,
        const Size(768, 1024),
        RoleSeance.enseignant,
      );
      List<PointNormalise> pointsLus() => <PointNormalise>[
        for (final TraitVectoriel trait
            in tester.widget<CoucheAnnotation>(_couche).traits)
          ...trait.points,
      ];
      final List<PointNormalise> stockesAvant = pointsLus();
      expect(stockesAvant, isNotEmpty);
      final Rect portrait = tester.getRect(_page);
      final (double luPortrait, double attenduPortrait) =
          await _bordDroitCercle(tester);
      expect(luPortrait, moreOrLessEquals(attenduPortrait, epsilon: 1.5));

      tester.view.physicalSize = const Size(1024, 768);
      await _attendre(tester);

      final Rect paysage = tester.getRect(_page);
      expect(paysage, isNot(equals(portrait)), reason: 'la page se recalcule');
      expect(tester.getRect(_couche), paysage);
      final (double luPaysage, double attenduPaysage) = await _bordDroitCercle(
        tester,
      );
      expect(luPaysage, moreOrLessEquals(attenduPaysage, epsilon: 1.5));
      // Meme part de la page, de part et d'autre de la rotation.
      expect(
        (luPaysage - paysage.left) / paysage.width,
        moreOrLessEquals(
          (luPortrait - portrait.left) / portrait.width,
          epsilon: 3 / paysage.width,
        ),
      );
      expect(pointsLus(), stockesAvant, reason: 'aucun trait recalcule');
      expect(_traits(depot), isEmpty, reason: 'rien d ecrit par la rotation');
      expect(tester.takeException(), isNull);
    });

    // UX-04 (UX_REVIEW_TB) : l'outil arme, toucher Micro ne laisse aucun
    // trait ; la barre consomme son toucher, meme quand la page zoomee
    // deborde vers elle. Le toucher atteint bien la commande (elle bascule).
    for (final (Size ecran, int clics) in <(Size, int)>[
      (const Size(390, 844), 0),
      (const Size(390, 844), 10),
      (const Size(1440, 900), 0),
    ]) {
      final int zoom = 100 + 10 * clics;
      testWidgets('outil arme, ${ecran.width.toInt()} a $zoom % : activer '
          'Micro n ajoute aucun trait', (WidgetTester tester) async {
        final AnnotationsMemoire depot = await _monterSalle(
          tester,
          ecran,
          RoleSeance.enseignant,
        );
        if (clics > 0) {
          await tester.tap(_entreeCommandes);
          await _attendre(tester);
          await _ongletSupport(tester);
          final Finder plus = find.byWidgetPredicate(
            (Widget w) =>
                w is Pressable &&
                w.libelleSemantique == t.salle.seance.zoomPlus,
          );
          await tester.ensureVisible(plus.first);
          await tester.pump();
          for (int i = 0; i < clics; i++) {
            await tester.tap(plus.first);
            await tester.pump();
          }
          expect(
            find.text(
              LibellesGroupe.valeurSeule(
                t.salle.seance.zoomValeur(valeur: zoom),
              ),
            ),
            findsWidgets,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await _attendre(tester);
          await tester.pump(const Duration(milliseconds: 1400));
          expect(find.byKey(CommandesPedagogiques.cle), findsNothing);
        }
        final Finder micro = find.byKey(const ValueKey<String>('bouton-micro'));
        final Rect rMicro = tester.getRect(micro);
        // A 200 % sur telephone, la page deborde jusque sous la barre : la
        // couche n'y recoit rien, la barre garde son toucher.
        final bool sousLaPage = tester.getRect(_page).overlaps(rMicro);
        expect(sousLaPage, clics > 0, reason: 'cas mesure : page sous Micro');
        final bool ouvert = find
            .descendant(of: micro, matching: find.text(t.salle.microOuvert))
            .evaluate()
            .isNotEmpty;
        // Un doigt pose sur Micro qui glisse jusque dans la page.
        await _tracer(
          tester,
          rMicro.center,
          _surEcran(tester, const PointNormalise(0.5, 0.5)),
        );
        expect(_traits(depot), isEmpty, reason: 'glisser depuis Micro');
        await tester.tap(micro);
        await _attendre(tester);
        expect(_traits(depot), isEmpty, reason: 'toucher Micro');
        expect(
          find.descendant(
            of: micro,
            matching: find.text(
              ouvert ? t.salle.microCoupe : t.salle.microOuvert,
            ),
          ),
          findsOneWidget,
          reason: 'le toucher a bascule le micro',
        );
        expect(tester.takeException(), isNull);
      });
    }

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

  // L'epaisseur se mesure sur l'image rendue : la largeur, en pixels, de
  // l'encre du cercle la ou il coupe l'horizontale de son centre, rapportee
  // a la largeur de la page a l'ecran. Une epaisseur fixe en points
  // d'ecran donnerait a 1440 une part de page bien plus fine qu'a 390.
  group('l epaisseur suit la page (§9)', () {
    Future<double> partDePage(WidgetTester tester, Size ecran) async {
      fixerVueCapture(tester, ecran, 3);
      addTearDown(tester.view.reset);
      final VueSeance vue = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.ped03,
      );
      await tester.pumpWidget(
        hoteCapture(
          SurfacePageFixe(vue: vue, surface: vue.vueSurface),
          surcharges: <Override>[
            portAnnotationsProvider.overrideWithValue(
              AnnotationsMemoire('prof-demo'),
            ),
          ],
        ),
      );
      await _attendre(tester);
      final Rect page = tester.getRect(_page);
      final RenderRepaintBoundary cadre = tester.renderObject(
        find.byKey(cadreCapture),
      );
      final ByteData? octets = await tester.runAsync<ByteData?>(() async {
        final ui.Image image = await cadre.toImage(pixelRatio: 3);
        final ByteData? brut = await image.toByteData();
        image.dispose();
        return brut;
      });
      final int largeur = (ecran.width * 3).round();
      int pixel(int x, int y) {
        final int i = (y * largeur + x) * 4;
        return octets!.getUint8(i) +
            octets.getUint8(i + 1) +
            octets.getUint8(i + 2);
      }

      const PointNormalise c = DonneesSeanceDemo.centreCercle;
      const double r = DonneesSeanceDemo.rayonCercle;
      final int y = ((page.top + c.y * page.height) * 3).round();
      final int fond = pixel(((page.left + c.x * page.width) * 3).round(), y);
      final int debut = ((page.left + (c.x + r - 0.05) * page.width) * 3)
          .round();
      final int fin = ((page.left + (c.x + r + 0.05) * page.width) * 3).round();
      // L'encre est plus sombre que la page : sa couverture se somme pixel
      // a pixel (l'anticrenelage compte pour sa part).
      int plusSombre = 0;
      for (int x = debut; x <= fin; x++) {
        plusSombre = math.max(plusSombre, fond - pixel(x, y));
      }
      expect(plusSombre, greaterThan(60), reason: 'le cercle est peint');
      double couverture = 0;
      for (int x = debut; x <= fin; x++) {
        couverture += ((fond - pixel(x, y)) / plusSombre).clamp(0, 1);
      }
      return couverture / (page.width * 3);
    }

    testWidgets('meme part de la page a 390 et a 1440', (
      WidgetTester tester,
    ) async {
      final double telephone = await partDePage(tester, const Size(390, 844));
      final double bureau = await partDePage(tester, const Size(1440, 900));
      expect(
        bureau / telephone,
        moreOrLessEquals(1, epsilon: 0.2),
        reason: 'telephone $telephone, bureau $bureau',
      );
    });
  });

  // Revue du tour 2 (TB-7a) : l'encre posee par la personne doit rester
  // peinte apres le lever du doigt, et suivre la page au zoom. Mesure sur
  // l'image : l'encre est cherchee sur l'horizontale du milieu du trait,
  // la ou la page affichee le place.
  group('l encre posee reste peinte', () {
    const PointNormalise milieu = PointNormalise(
      (0.40 + 0.55) / 2,
      (0.45 + 0.52) / 2,
    );

    Future<(double?, double)> encreAuMilieu(WidgetTester tester) async {
      final Rect page = tester.getRect(_page);
      final Offset attendu = _surEcran(tester, milieu);
      final _Photo photo = await _Photo.prendre(tester);
      return (
        photo.milieuEncre(
          attendu.dy,
          attendu.dx - 0.03 * page.width,
          attendu.dx + 0.03 * page.width,
        ),
        attendu.dx,
      );
    }

    testWidgets('surface : le trait reste peint apres le lever du doigt', (
      WidgetTester tester,
    ) async {
      final AnnotationsMemoire depot = await _monterSurface(
        tester,
        const Size(1440, 900),
      );
      final (double? avant, _) = await encreAuMilieu(tester);
      expect(avant, isNull, reason: 'rien n est peint la avant le geste');
      await _tracer(
        tester,
        _surEcran(tester, _depart),
        _surEcran(tester, _arrivee),
      );
      await _attendre(tester);
      expect(_traits(depot), hasLength(1));
      final (double? lu, double attendu) = await encreAuMilieu(tester);
      expect(lu, isNotNull, reason: 'l encre reste apres le lever');
      expect(lu, moreOrLessEquals(attendu, epsilon: 2));
    });

    testWidgets('surface : un trait qui sort de la page reste peint', (
      WidgetTester tester,
    ) async {
      final AnnotationsMemoire depot = await _monterSurface(
        tester,
        const Size(1440, 900),
      );
      final Rect r = tester.getRect(_page);
      final double y = r.top + r.height / 2;
      final _Photo avant = await _Photo.prendre(tester);
      final TestPointer doigt = TestPointer(12);
      await tester.sendEventToBinding(doigt.down(Offset(r.right - 160, y)));
      for (final double dx in <double>[120, 80, 40, -30, -60]) {
        await tester.sendEventToBinding(doigt.move(Offset(r.right - dx, y)));
        await tester.pump();
      }
      await tester.sendEventToBinding(doigt.up());
      await _attendre(tester);
      expect(_traits(depot), hasLength(1));
      final _Photo apres = await _Photo.prendre(tester);
      expect(
        apres.ecartMax(
          avant,
          Rect.fromLTRB(r.right - 150, y - 3, r.right - 50, y + 3),
        ),
        greaterThan(200),
        reason: 'le trait arrete a la sortie reste peint',
      );
    });

    testWidgets('vraie salle : le trait reste peint, et suit la page au '
        'zoom 200 %', (WidgetTester tester) async {
      await _monterSalle(tester, const Size(1440, 900), RoleSeance.enseignant);
      await _tracer(
        tester,
        _surEcran(tester, _depart),
        _surEcran(tester, _arrivee),
      );
      await _attendre(tester);
      final (double? luPose, double attenduPose) = await encreAuMilieu(tester);
      expect(luPose, isNotNull, reason: 'peint apres le lever');
      expect(luPose, moreOrLessEquals(attenduPose, epsilon: 2));

      // Les Commandes ouvertes ensuite : la surface change de place et se
      // remonte ; l'encre posee reste peinte (relue du depot).
      await tester.tap(_entreeCommandes);
      await _attendre(tester);
      await _ongletSupport(tester);
      final (double? luAvant, double attenduAvant) = await encreAuMilieu(
        tester,
      );
      expect(luAvant, isNotNull, reason: 'peint apres l ouverture');
      expect(luAvant, moreOrLessEquals(attenduAvant, epsilon: 2));

      final Finder plus = find.byWidgetPredicate(
        (Widget w) =>
            w is Pressable && w.libelleSemantique == t.salle.seance.zoomPlus,
      );
      for (int i = 0; i < 10; i++) {
        await tester.tap(plus);
        await tester.pump();
      }
      await _attendre(tester);
      expect(
        find.text(
          LibellesGroupe.valeurSeule(t.salle.seance.zoomValeur(valeur: 200)),
        ),
        findsWidgets,
      );
      final (double? luApres, double attenduApres) = await encreAuMilieu(
        tester,
      );
      expect(luApres, isNotNull, reason: 'peint apres le zoom');
      expect(luApres, moreOrLessEquals(attenduApres, epsilon: 3));
      expect(
        (luApres! - luAvant!).abs(),
        greaterThan(10),
        reason: 'le trait a bouge avec la page',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('le trait pose ne se peint pas sur une autre page', (
      WidgetTester tester,
    ) async {
      final AnnotationsMemoire depot = await _monterSurface(
        tester,
        const Size(1440, 900),
      );
      await _tracer(
        tester,
        _surEcran(tester, _depart),
        _surEcran(tester, _arrivee),
      );
      await _attendre(tester);
      expect((await encreAuMilieu(tester)).$1, isNotNull);
      final VueSeance vue = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.ped03,
      );
      final VueSeance page2 = vue.copyWith(
        supportPresente: vue.supportPresente!.aLaPage(2),
      );
      await tester.pumpWidget(
        hoteCapture(
          SurfacePageFixe(vue: page2, surface: page2.vueSurface),
          surcharges: <Override>[
            portAnnotationsProvider.overrideWithValue(depot),
            etatOutilsProvider.overrideWith(_ControleurArme.new),
          ],
        ),
      );
      await _attendre(tester);
      expect(_traits(depot), hasLength(1), reason: 'le depot le garde');
      expect(
        (await encreAuMilieu(tester)).$1,
        isNull,
        reason: 'un trait de la page 1 ne se peint pas sur la page 2',
      );
    });

    testWidgets('sans depot : aucune erreur, aucune encre restee comme si '
        'le trait etait garde', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      addTearDown(tester.view.reset);
      final VueSeance vue = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.ped03,
      );
      await tester.pumpWidget(
        hoteCapture(
          SurfacePageFixe(vue: vue, surface: vue.vueSurface),
          surcharges: <Override>[
            etatOutilsProvider.overrideWith(_ControleurArme.new),
          ],
        ),
      );
      await _attendre(tester);
      await _tracer(
        tester,
        _surEcran(tester, _depart),
        _surEcran(tester, _arrivee),
      );
      await _attendre(tester);
      expect(tester.takeException(), isNull);
      final (double? lu, _) = await encreAuMilieu(tester);
      expect(lu, isNull, reason: 'le depot n a rien pris : rien ne reste');
    });
  });

  // Revue du tour 2, mineur : a 200 %, la page deborde de sa surface, qui
  // la rogne. Un trait s'arrete au bord de la part visible, pas au bord de
  // la page cachee.
  testWidgets('zoom 200 % : le trait s arrete au bord de la part visible', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(1440, 900), 1);
    addTearDown(tester.view.reset);
    final AnnotationsMemoire depot = AnnotationsMemoire('prof-demo');
    addTearDown(depot.liberer);
    final VueSeance vue = DonneesSeanceDemo.vueTb(
      RoleSeance.enseignant,
      SituationTb.ped03,
    );
    const Key boiteCle = ValueKey<String>('boite');
    await tester.pumpWidget(
      hoteCapture(
        Center(
          child: SizedBox(
            key: boiteCle,
            width: 600,
            height: 500,
            child: SurfacePageFixe(vue: vue, surface: vue.vueSurface, zoom: 2),
          ),
        ),
        surcharges: <Override>[
          portAnnotationsProvider.overrideWithValue(depot),
          etatOutilsProvider.overrideWith(_ControleurArme.new),
        ],
      ),
    );
    await _attendre(tester);
    final Rect boite = tester.getRect(find.byKey(boiteCle));
    final Rect page = tester.getRect(_page);
    expect(page.right, greaterThan(boite.right + 40), reason: 'page rognee');
    final double y = boite.center.dy;
    final TestPointer doigt = TestPointer(13);
    await tester.sendEventToBinding(doigt.down(Offset(boite.right - 100, y)));
    for (final double dx in <double>[70, 40, 10, -20, -40]) {
      await tester.sendEventToBinding(doigt.move(Offset(boite.right - dx, y)));
      await tester.pump();
    }
    await tester.sendEventToBinding(doigt.up());
    await _attendre(tester);
    final TraitVectoriel trait = _traits(depot).single;
    final double limite = (boite.right - page.left) / page.width;
    for (final PointNormalise p in trait.points) {
      expect(
        p.x,
        lessThanOrEqualTo(limite + 1e-6),
        reason: 'aucun point dans la page cachee : $p',
      );
    }
    _memePoint(
      trait.points.last,
      PointNormalise(
        (boite.right - 10 - page.left) / page.width,
        (y - page.top) / page.height,
      ),
      'le trait finit au dernier point visible',
    );
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
