// MA-11 : passe technique transverse sur les ecrans du Mode Accessibilite.
//
// Sur chaque destination de la demonstration (Accueil, Ma classe, Coran,
// Mon espace) : parcours clavier complet (Tab, puis Maj+Tab), chaque cible
// atteinte au clavier mesuree a 48 au moins, les actions majeures a 52 au
// moins (Q3 : jetons existants gardes s'ils font au moins 52), animations
// reduites honorees. Coran : la reprise n'est plus avalee en silence et
// l'action principale attend son arrivee (revue MA-7).
//
// La « cible » mesuree est celle du doigt (MA-11 : « cibles >= 48 » ; revue
// UX_REVIEW_06 : W-258, AND-48, « cibles reelles mesurees »). D'ordinaire la
// boite du focus la donne : `Pressable` pose son minimum de 48 (72 en guidee)
// sous le focus. Un element qui porte sa cible hors de sa boite (le lien
// « En savoir plus » de la salle, `CibleDebordante`, JUR-APP-1) a une boite
// de focus serree sur son texte ; il n'est alors accepte que si la zone qui
// l'active reellement au doigt, mesuree point par point par le test de
// touche de l'application, fait elle-meme 48 de cote au moins.

import 'dart:async';

import 'package:flutter/gestures.dart' show HitTestEntry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/mouvement.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_accessibilite.dart';
import 'package:rewayah_academy/features/accueil_eleve/coran_accessibilite.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../router/support_routeur.dart' show stabiliser;
import '../teaching_core/c/faux/faux_corpus_coran.dart';

const double _cibleMin = 48;
const double _cibleMajeure = 52;

Widget _hote(Widget ecran, {bool animationsReduites = false}) => ProviderScope(
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? enfant) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: animationsReduites),
        child: enfant ?? const SizedBox.shrink(),
      ),
      home: ecran,
    ),
  ),
);

Future<void> _taille(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Parcourt l'ecran au clavier : Tab jusqu'au retour au depart, chaque
/// focus mesure ; puis Maj+Tab revient sur le focus precedent.
Future<int> _parcourir(WidgetTester tester, String ecran) async {
  final List<FocusNode> vus = <FocusNode>[];
  for (int i = 0; i < 60; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus.context == null) continue;
    if (vus.isNotEmpty && identical(focus, vus.first)) break;
    if (vus.contains(focus)) continue;
    vus.add(focus);
    Rect zone = focus.rect;
    if (zone.height < _cibleMin || zone.width < _cibleMin) {
      zone = _zoneActivable(tester, focus);
    }
    expect(
      zone.height,
      greaterThanOrEqualTo(_cibleMin),
      reason:
          '$ecran : cible clavier ${focus.debugLabel} trop basse $zone '
          '(boite du focus ${focus.rect})',
    );
    expect(
      zone.width,
      greaterThanOrEqualTo(_cibleMin),
      reason:
          '$ecran : cible clavier ${focus.debugLabel} trop etroite $zone '
          '(boite du focus ${focus.rect})',
    );
  }
  expect(vus, isNotEmpty, reason: '$ecran : aucun element au clavier');
  if (vus.length > 1) {
    final FocusNode? avant = FocusManager.instance.primaryFocus;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus,
      isNot(same(avant)),
      reason: '$ecran : Maj+Tab ne recule pas',
    );
  }
  return vus.length;
}

/// Un carre de [_cibleMin] de cote, en coordonnees d'ecran, dont chaque
/// point active reellement [focus] au doigt ; rect vide s'il n'y en a pas.
///
/// Mesure, pas lu : le test de touche de l'application est rejoue sur une
/// grille de 13 x 13 points (bords compris, pas de 4 au plus) ; un point que
/// prend une autre commande (le chevron Retour, par exemple) ne compte pas.
/// Les carres essayes sont ceux qui couvrent le centre de la boite du focus,
/// du plus centre au plus decale, au pas de 4 : la cible doit entourer ce
/// qu'elle montre.
Rect _zoneActivable(WidgetTester tester, FocusNode focus) {
  final RenderObject element = focus.context!.findRenderObject()!;
  bool active(Offset point) => tester
      .hitTestOnBinding(point)
      .path
      .any((HitTestEntry entree) => identical(entree.target, element));
  bool pleine(Rect carre) {
    for (int i = 0; i <= 12; i++) {
      for (int j = 0; j <= 12; j++) {
        final Offset point = Offset(
          carre.left + 0.5 + (carre.width - 1) * i / 12,
          carre.top + 0.5 + (carre.height - 1) * j / 12,
        );
        if (!active(point)) return false;
      }
    }
    return true;
  }

  final Offset centre = focus.rect.center;
  final List<double> decalages = <double>[0];
  for (double d = 4; d < _cibleMin / 2; d += 4) {
    decalages.addAll(<double>[d, -d]);
  }
  for (final double dy in decalages) {
    for (final double dx in decalages) {
      final Rect carre = Rect.fromCenter(
        center: centre + Offset(dx, dy),
        width: _cibleMin,
        height: _cibleMin,
      );
      if (pleine(carre)) return carre;
    }
  }
  return Rect.fromCenter(center: centre, width: 0, height: 0);
}

/// Un port dont la reprise attend le test.
class _NavigationPilotee extends FauxNavigationCoran {
  final Completer<PositionLecture?> reprise = Completer<PositionLecture?>();

  @override
  Future<PositionLecture?> dernierePositionPersonnelle() => reprise.future;
}

/// Un port dont la reprise echoue.
class _NavigationEnEchec extends FauxNavigationCoran {
  @override
  Future<PositionLecture?> dernierePositionPersonnelle() async =>
      throw StateError('reseau');
}

ActionPrincipale _principale(WidgetTester tester) =>
    tester.widget(find.byKey(const ValueKey<String>('coran-ma-principale')));

Widget _coran(PortNavigationCoran port, {bool tutoiement = true}) =>
    ProviderScope(
      overrides: [portNavigationCoranProvider.overrideWithValue(port)],
      child: CoranAccessibilite(tutoiement: tutoiement, onAide: () {}),
    );

void main() {
  const Map<String, int> destinations = <String, int>{
    'Accueil': EcranAccessibiliteDemo.indexAccueil,
    'Ma classe': EcranAccessibiliteDemo.indexMaClasse,
    'Coran': EcranAccessibiliteDemo.indexCoran,
    'Mon espace': EcranAccessibiliteDemo.indexMonEspace,
  };

  group('MA-11 clavier et cibles sur chaque destination', () {
    for (final EleveDemoAccessibilite eleve in EleveDemoAccessibilite.values) {
      for (final MapEntry<String, int> d in destinations.entries) {
        for (final Size taille in <Size>[
          const Size(390, 844),
          const Size(1440, 900),
        ]) {
          testWidgets('${d.key}, ${eleve.name}, ${taille.width.toInt()} px : '
              'Tab et Maj+Tab, chaque cible au moins 48', (
            WidgetTester tester,
          ) async {
            await _taille(tester, taille);
            await tester.pumpWidget(
              _hote(
                EcranAccessibiliteDemo(
                  eleve: eleve,
                  destinationInitiale: d.value,
                ),
              ),
            );
            await stabiliser(tester);
            final int n = await _parcourir(tester, d.key);
            expect(n, greaterThanOrEqualTo(2));
          });
        }
      }
    }

    for (final EleveDemoAccessibilite eleve in EleveDemoAccessibilite.values) {
      testWidgets('Apres la seance, ${eleve.name} : Tab et Maj+Tab, chaque '
          'cible au moins 48', (WidgetTester tester) async {
        await _taille(tester, const Size(390, 844));
        await tester.pumpWidget(
          _hote(
            EcranAccessibiliteDemo(
              eleve: eleve,
              moment: MomentDemoAccessibilite.apres,
            ),
          ),
        );
        await stabiliser(tester);
        expect(await _parcourir(tester, 'apres'), greaterThanOrEqualTo(2));
      });
    }
  });

  group('MA-11 clavier et cibles : preparation et salle', () {
    for (final EtapeDemoAccessibilite etape in <EtapeDemoAccessibilite>[
      EtapeDemoAccessibilite.preparation,
      EtapeDemoAccessibilite.salle,
    ]) {
      for (final EleveDemoAccessibilite eleve
          in EleveDemoAccessibilite.values) {
        testWidgets('${etape.name}, ${eleve.name} : Tab et Maj+Tab, chaque '
            'cible au moins 48', (WidgetTester tester) async {
          await _taille(tester, const Size(390, 844));
          await tester.pumpWidget(
            _hote(EcranAccessibiliteDemo(eleve: eleve, etapeInitiale: etape)),
          );
          await stabiliser(tester);
          await _parcourir(tester, etape.name);
        });
      }
    }
  });

  group('MA-11 actions majeures a 52 au moins', () {
    testWidgets('Accueil : « Voir ma classe »', (WidgetTester tester) async {
      await _taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        _hote(
          const EcranAccessibiliteDemo(
            eleve: EleveDemoAccessibilite.mariam,
            destinationInitiale: EcranAccessibiliteDemo.indexAccueil,
          ),
        ),
      );
      await stabiliser(tester);
      expect(
        tester.getSize(find.byKey(AccueilAccessibilite.cleVoirClasse)).height,
        greaterThanOrEqualTo(_cibleMajeure),
      );
    });

    testWidgets('Coran : action principale', (WidgetTester tester) async {
      await _taille(tester, const Size(390, 844));
      await tester.pumpWidget(_hote(_coran(FauxNavigationCoran())));
      await stabiliser(tester);
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('coran-ma-principale')))
            .height,
        greaterThanOrEqualTo(_cibleMajeure),
      );
    });
  });

  group('MA-11 Coran : reprise (revue MA-7)', () {
    testWidgets('pendant la recherche, message et action non cliquable ; '
        'puis la reprise arrive', (WidgetTester tester) async {
      final _NavigationPilotee port = _NavigationPilotee();
      await tester.pumpWidget(_hote(_coran(port)));
      await tester.pump();
      expect(find.text(t.accessibilite.coran.repriseRecherche), findsOneWidget);
      expect(_principale(tester).onPress, isNull);

      port.reprise.complete(
        const PositionLecture(page: 12, sourate: 2, verset: 77),
      );
      await stabiliser(tester);
      expect(
        find.text(t.accessibilite.coran.reprendreDetail(page: '12')),
        findsOneWidget,
      );
      expect(_principale(tester).onPress, isNotNull);
      expect(find.text(t.accessibilite.coran.reprendre), findsOneWidget);
    });

    for (final bool tu in <bool>[true, false]) {
      testWidgets('echec de la reprise : message K-59 '
          '(${tu ? 'tutoiement' : 'vouvoiement'}), le Coran s ouvre quand '
          'meme', (WidgetTester tester) async {
        await tester.pumpWidget(
          _hote(_coran(_NavigationEnEchec(), tutoiement: tu)),
        );
        await stabiliser(tester);
        expect(
          find.text(
            tu
                ? t.accessibilite.coran.repriseErreur
                : t.accessibilite.coran.repriseErreurVous,
          ),
          findsOneWidget,
        );
        expect(_principale(tester).onPress, isNotNull);
        expect(find.text(t.accessibilite.coran.ouvrir), findsOneWidget);
      });
    }

    testWidgets('Entree sur l action principale ouvre le lecteur', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(_coran(FauxNavigationCoran())));
      await stabiliser(tester);
      for (int i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx != null &&
            ctx.findAncestorWidgetOfExactType<ActionPrincipale>()?.key ==
                const ValueKey<String>('coran-ma-principale')) {
          break;
        }
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await stabiliser(tester);
      expect(
        find.byKey(const ValueKey<String>('coran-ma-lecteur')),
        findsOneWidget,
      );
    });
  });

  group('MA-11 animations reduites', () {
    testWidgets('disableAnimations : Mouvement.duree vaut zero et chaque '
        'destination se stabilise', (WidgetTester tester) async {
      await _taille(tester, const Size(390, 844));
      for (final int d in destinations.values) {
        await tester.pumpWidget(
          _hote(
            EcranAccessibiliteDemo(
              key: ValueKey<int>(d),
              eleve: EleveDemoAccessibilite.mariam,
              destinationInitiale: d,
            ),
            animationsReduites: true,
          ),
        );
        await stabiliser(tester);
        final BuildContext contexte = tester.element(
          find.byType(EcranAccessibiliteDemo),
        );
        expect(Mouvement.duree(contexte, Mouvement.moyen), Duration.zero);
        expect(tester.hasRunningAnimations, isFalse);
      }
    });
  });
}
