// VIVANT : les briques de mouvement de `lib/core/vivant/`.
//
// La regle commune : tout part du toucher, depasse un peu, se pose, puis se
// tait. « Se tait » se prouve : au repos, plus aucun rappel d'image n'est en
// attente (`transientCallbackCount == 0`), donc aucun ticker actif.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/theme/app_radius.dart';
import 'package:rewayah_academy/core/vivant/niveau_eau.dart';
import 'package:rewayah_academy/core/vivant/nombre_rouleaux.dart';
import 'package:rewayah_academy/core/vivant/pile_feuilletee.dart';
import 'package:rewayah_academy/core/vivant/praxis_vivant.dart';
import 'package:rewayah_academy/core/vivant/ressort.dart';
import 'package:rewayah_academy/core/vivant/surface_penchee.dart';
import 'package:rewayah_academy/core/vivant/texte_qui_s_ecrit.dart';
import 'package:rewayah_academy/core/vivant/toucher_vivant.dart';

import '../../support/harnais.dart';

int _rappels() => SchedulerBinding.instance.transientCallbackCount;

Future<void> _laisserVivre(WidgetTester tester, {int images = 240}) async {
  for (int i = 0; i < images; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Widget _reduit(Widget enfant) => EffetsReduits(actifs: true, child: enfant);

void main() {
  group('Ressort', () {
    test('depasse sa cible puis se pose', () {
      final Ressort r = Ressort(0, raideur: 420, frein: 14)..cible = 1;
      double sommet = 0;
      for (int i = 0; i < 600 && !r.repos; i++) {
        r.pas(1 / 120);
        if (r.x > sommet) sommet = r.x;
      }
      expect(sommet, greaterThan(1), reason: 'il depasse un peu');
      expect(r.repos, isTrue);
      expect(r.x, closeTo(1, 0.002));
    });

    test('poser : sur la cible, sans vitesse', () {
      final Ressort r = Ressort(0)
        ..cible = 3
        ..v = 9
        ..poser();
      expect(r.x, 3);
      expect(r.v, 0);
      expect(r.repos, isTrue);
    });
  });

  group('AppRadius.interieur', () {
    test('rayon exterieur moins la marge, jamais sous le plus petit cran', () {
      expect(AppRadius.interieur(24, 12), 12);
      expect(AppRadius.interieur(24, 8), 16);
      expect(AppRadius.interieur(24, 24), AppRadius.xs);
      expect(AppRadius.interieur(16, 16), AppRadius.xs);
    });

    test('coinContinu rend une superellipse du rayon demande', () {
      final ShapeBorder forme = AppRadius.coinContinu(AppRadius.lg);
      expect(forme, isA<RoundedSuperellipseBorder>());
      expect(
        (forme as RoundedSuperellipseBorder).borderRadius,
        const BorderRadius.all(Radius.circular(AppRadius.lg)),
      );
    });
  });

  group('ToucherVivant', () {
    testWidgets('s enfonce a l appui, appelle le geste, puis se tait', (
      WidgetTester tester,
    ) async {
      int touches = 0;
      await tester.pumpWidget(
        hote(
          Center(
            child: ToucherVivant(
              onPress: () => touches++,
              child: const SizedBox(width: 120, height: 80),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_rappels(), 0, reason: 'au repos avant tout toucher');

      final TestGesture geste = await tester.startGesture(
        tester.getCenter(find.byType(ToucherVivant)),
      );
      await _laisserVivre(tester, images: 12);
      final Iterable<Transform> transformations = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(ToucherVivant),
          matching: find.byType(Transform),
        ),
      );
      expect(
        transformations
            .map((Transform x) => x.transform.storage[0])
            .reduce((double a, double b) => a < b ? a : b),
        lessThan(1),
        reason: 'la surface s enfonce sous le doigt',
      );
      await geste.up();
      await _laisserVivre(tester);
      expect(touches, 1);
      expect(_rappels(), 0, reason: 'au repos, aucun ticker actif');
    });
  });

  group('SurfacePenchee', () {
    testWidgets('penche au survol, se redresse, puis se tait', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const Center(
            child: SurfacePenchee(child: SizedBox(width: 200, height: 120)),
          ),
        ),
      );
      final TestGesture souris = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await souris.addPointer(location: Offset.zero);
      addTearDown(souris.removePointer);
      final Offset centre = tester.getCenter(find.byType(SurfacePenchee));
      await souris.moveTo(centre + const Offset(60, 30));
      await _laisserVivre(tester, images: 10);
      expect(_rappels(), greaterThan(0), reason: 'elle bouge au survol');
      await souris.moveTo(Offset.zero);
      await _laisserVivre(tester);
      expect(_rappels(), 0, reason: 'au repos, aucun ticker actif');
    });
  });

  group('NombreRouleaux', () {
    testWidgets('roule quand le nombre change, puis se tait', (
      WidgetTester tester,
    ) async {
      Widget monter(int n) =>
          hote(Center(child: NombreRouleaux(n, style: const TextStyle())));
      await tester.pumpWidget(monter(12));
      expect(find.text('12'), findsOneWidget);
      expect(_rappels(), 0);

      await tester.pumpWidget(monter(13));
      await _laisserVivre(tester, images: 4);
      expect(find.text('12'), findsOneWidget, reason: 'l ancienne sort');
      expect(find.text('13'), findsOneWidget, reason: 'la nouvelle monte');
      await _laisserVivre(tester);
      expect(find.text('12'), findsNothing);
      expect(find.text('13'), findsOneWidget);
      expect(_rappels(), 0, reason: 'au repos, aucun ticker actif');
    });

    testWidgets('effets reduits : la nouvelle valeur, sans animation', (
      WidgetTester tester,
    ) async {
      Widget monter(int n) => hote(
        _reduit(Center(child: NombreRouleaux(n, style: const TextStyle()))),
      );
      await tester.pumpWidget(monter(1));
      await tester.pumpWidget(monter(2));
      await tester.pump();
      // Des la premiere image : la nouvelle valeur seule, rien ne roule.
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneWidget);
      // Le fondu du theme de `MaterialApp` (nouvelle instance) passe, puis
      // plus rien ne tourne.
      await _laisserVivre(tester, images: 30);
      expect(_rappels(), 0);
    });
  });

  group('NiveauEau', () {
    testWidgets('l eau respire : le seul mouvement qui dure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const Center(
            child: SizedBox(
              width: 200,
              height: 120,
              child: NiveauEau(niveau: 0.5, couleur: Color(0xFF8652E6)),
            ),
          ),
        ),
      );
      await _laisserVivre(tester);
      expect(_rappels(), greaterThan(0));
    });

    testWidgets('effets reduits : l eau est posee, immobile', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          _reduit(
            const Center(
              child: SizedBox(
                width: 200,
                height: 120,
                child: NiveauEau(niveau: 0.5, couleur: Color(0xFF8652E6)),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(_rappels(), 0, reason: 'aucune image animee en mode reduit');
    });
  });

  group('PraxisVivant', () {
    // Le temps vecu avance d'au plus 32 ms par image : 850 images de 32 ms
    // font vingt-sept secondes, la veille (vingt secondes) puis le temps de
    // se poser.
    Future<void> vivre(WidgetTester tester, {int images = 850}) async {
      for (int i = 0; i < images; i++) {
        await tester.pump(const Duration(milliseconds: 32));
      }
    }

    testWidgets('tombe, rebondit, vit, puis s endort et se tait', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPraxisVivant> cle = GlobalKey<EtatPraxisVivant>();
      await tester.pumpWidget(
        hote(
          Center(
            child: PraxisVivant(key: cle, humeur: HumeurPraxis.heureux),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(_rappels(), greaterThan(0), reason: 'il arrive en tombant');
      // Pose, il vit encore : il respire et cligne tant qu'il est eveille.
      await vivre(tester, images: 200);
      expect(_rappels(), greaterThan(0), reason: 'eveille, il respire');
      expect(cle.currentState!.endormi, isFalse);
      // Vingt secondes sans geste : il dort, plus aucune image.
      await vivre(tester);
      expect(cle.currentState!.endormi, isTrue);
      expect(_rappels(), 0, reason: 'endormi, aucun ticker actif');
      expect(tester.takeException(), isNull);
    });

    testWidgets('chaque humeur, le « non » et les larmes finissent', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPraxisVivant> cle = GlobalKey<EtatPraxisVivant>();
      for (final HumeurPraxis h in HumeurPraxis.values) {
        await tester.pumpWidget(
          hote(
            Center(
              child: PraxisVivant(key: cle, humeur: h, tombe: false),
            ),
          ),
        );
        await vivre(tester);
        expect(_rappels(), 0, reason: 'humeur $h : endormi, il se tait');
      }
      cle.currentState!.non();
      await tester.pump();
      await tester.pump();
      expect(_rappels(), greaterThan(0));
      await vivre(tester);
      expect(_rappels(), 0, reason: 'apres le « non », il se tait');
      cle.currentState!.cligner();
      await tester.pump();
      expect(_rappels(), greaterThan(0), reason: 'le clin le reveille');
      await vivre(tester);
      expect(_rappels(), 0, reason: 'apres le clin, il se tait');
      expect(tester.takeException(), isNull);
    });

    testWidgets('un geste du pointeur le reveille', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPraxisVivant> cle = GlobalKey<EtatPraxisVivant>();
      final ValueNotifier<Offset> regard = ValueNotifier<Offset>(Offset.zero);
      addTearDown(regard.dispose);
      await tester.pumpWidget(
        hote(
          Center(
            child: PraxisVivant(key: cle, tombe: false, regard: regard),
          ),
        ),
      );
      await vivre(tester);
      expect(cle.currentState!.endormi, isTrue);
      regard.value = const Offset(40, 60);
      await tester.pump();
      await tester.pump();
      expect(cle.currentState!.endormi, isFalse);
      expect(_rappels(), greaterThan(0), reason: 'reveille, il revit');
      await vivre(tester);
      expect(_rappels(), 0);
    });

    testWidgets('assis, il parle, se tait, s endort : aucune erreur', (
      WidgetTester tester,
    ) async {
      Widget monter({required bool parle}) => hote(
        Center(
          child: PraxisVivant(
            humeur: HumeurPraxis.soucieux,
            assis: true,
            parle: parle,
            tombe: false,
          ),
        ),
      );
      await tester.pumpWidget(monter(parle: true));
      await vivre(tester, images: 60);
      expect(_rappels(), greaterThan(0));
      await tester.pumpWidget(monter(parle: false));
      await vivre(tester);
      expect(_rappels(), 0);
      expect(tester.takeException(), isNull);
      // La ligne d'assise est dans le dessin, sous le corps : les pieds
      // pendent dessous.
      expect(
        PraxisVivant.assisePour(200),
        lessThan(PraxisVivant.hauteurPour(200)),
      );
      expect(PraxisVivant.assisePour(200), greaterThan(100));
    });

    testWidgets('effets reduits : pose d emblee, aucune image animee', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPraxisVivant> cle = GlobalKey<EtatPraxisVivant>();
      await tester.pumpWidget(
        hote(
          _reduit(
            Center(
              child: PraxisVivant(key: cle, humeur: HumeurPraxis.pleure),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(_rappels(), 0);
      // Fige, il ne s'endort pas : ses yeux gardent leur dessin.
      await tester.pump(const Duration(seconds: 30));
      expect(cle.currentState!.endormi, isFalse);
      expect(_rappels(), 0);
    });

    testWidgets('il est decoratif : rien pour le lecteur d ecran', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(const Center(child: PraxisVivant(tombe: false))),
      );
      expect(
        find.ancestor(
          of: find.byType(CustomPaint),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });
  });

  group('TexteQuiSEcrit', () {
    const String phrase = 'Cinq candidats attendent un entretien.';
    const TextStyle style = TextStyle(fontSize: 16, color: Color(0xFF110E20));

    testWidgets(
      'la phrase s ecrit, previent, puis devient un texte ordinaire',
      (WidgetTester tester) async {
        final List<bool> etats = <bool>[];
        await tester.pumpWidget(
          hote(
            Center(
              child: TexteQuiSEcrit(
                phrase,
                style: style,
                onEcriture: etats.add,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 32));
        await tester.pump(const Duration(milliseconds: 32));
        // En cours : la suite de la phrase est posee mais invisible (deux
        // parts : ecrite, a venir) ; le lecteur d'ecran lit deja la phrase.
        expect(etats, <bool>[true]);
        expect(tester.widget<Text>(find.text(phrase)).data, isNull);
        expect(find.bySemanticsLabel(phrase), findsOneWidget);
        final double hauteur = tester
            .getSize(find.byType(TexteQuiSEcrit))
            .height;
        await _laisserVivre(tester);
        expect(etats, <bool>[true, false]);
        expect(tester.widget<Text>(find.text(phrase)).data, phrase);
        // La place etait reservee : rien n'a saute.
        expect(tester.getSize(find.byType(TexteQuiSEcrit)).height, hauteur);
        expect(_rappels(), 0, reason: 'ecrite, elle ne bouge plus');
      },
    );

    testWidgets('effets reduits : la phrase entiere, d emblee', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          _reduit(const Center(child: TexteQuiSEcrit(phrase, style: style))),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text(phrase), findsOneWidget);
      expect(_rappels(), 0);
    });
  });

  group('PileFeuilletee', () {
    Widget pile(
      GlobalKey<EtatPileFeuilletee> cle,
      List<int> dessus, {
      int nombre = 3,
      List<int>? touches,
    }) => Center(
      child: SizedBox(
        width: 260,
        child: PileFeuilletee(
          key: cle,
          nombre: nombre,
          onDessus: dessus.add,
          constructeur: (BuildContext _, int i, {required bool dessus}) =>
              GestureDetector(
                onTap: dessus ? () => touches?.add(i) : null,
                child: SizedBox(
                  height: 120,
                  child: ColoredBox(
                    color: const Color(0xFFFFFFFF),
                    child: Center(child: Text('carte $i')),
                  ),
                ),
              ),
        ),
      ),
    );

    testWidgets('glissee assez loin, la carte passe dessous et la suivante '
        'monte ; puis tout se tait', (WidgetTester tester) async {
      final GlobalKey<EtatPileFeuilletee> cle = GlobalKey<EtatPileFeuilletee>();
      final List<int> dessus = <int>[];
      await tester.pumpWidget(hote(pile(cle, dessus)));
      // Trois cartes se voient, celle du dessus est la premiere.
      expect(find.text('carte 0'), findsOneWidget);
      expect(find.text('carte 1'), findsOneWidget);
      expect(find.text('carte 2'), findsOneWidget);
      await tester.drag(find.text('carte 0'), const Offset(180, 0));
      await _laisserVivre(tester);
      expect(dessus, <int>[1]);
      expect(cle.currentState!.dessus, 1);
      expect(_rappels(), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lachee trop pres, la carte revient', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPileFeuilletee> cle = GlobalKey<EtatPileFeuilletee>();
      final List<int> dessus = <int>[];
      await tester.pumpWidget(hote(pile(cle, dessus)));
      final Offset avant = tester.getCenter(find.text('carte 0'));
      await tester.drag(find.text('carte 0'), const Offset(60, 0));
      await _laisserVivre(tester);
      expect(dessus, isEmpty);
      expect(cle.currentState!.dessus, 0);
      expect(tester.getCenter(find.text('carte 0')).dx, closeTo(avant.dx, 0.5));
      expect(_rappels(), 0);
    });

    testWidgets('suivante, precedente : on tourne dans la pile', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPileFeuilletee> cle = GlobalKey<EtatPileFeuilletee>();
      final List<int> dessus = <int>[];
      await tester.pumpWidget(hote(pile(cle, dessus)));
      cle.currentState!.suivante();
      await _laisserVivre(tester);
      cle.currentState!.suivante();
      await _laisserVivre(tester);
      cle.currentState!.suivante();
      await _laisserVivre(tester);
      expect(dessus, <int>[1, 2, 0]);
      cle.currentState!.precedente();
      await _laisserVivre(tester);
      expect(dessus.last, 2);
      expect(_rappels(), 0);
    });

    testWidgets('feuilleter ne decide rien ; toucher la carte du dessus agit', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPileFeuilletee> cle = GlobalKey<EtatPileFeuilletee>();
      final List<int> touches = <int>[];
      await tester.pumpWidget(hote(pile(cle, <int>[], touches: touches)));
      await tester.drag(find.text('carte 0'), const Offset(-180, 0));
      await _laisserVivre(tester);
      expect(touches, isEmpty, reason: 'un glissement n est pas un toucher');
      await tester.tap(find.text('carte 1'));
      expect(touches, <int>[1]);
    });

    testWidgets('une seule carte : elle ne part pas', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPileFeuilletee> cle = GlobalKey<EtatPileFeuilletee>();
      final List<int> dessus = <int>[];
      await tester.pumpWidget(hote(pile(cle, dessus, nombre: 1)));
      await tester.drag(find.text('carte 0'), const Offset(200, 0));
      await _laisserVivre(tester);
      expect(dessus, isEmpty);
      expect(find.text('carte 0'), findsOneWidget);
    });

    testWidgets('effets reduits : la carte change sans mouvement', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPileFeuilletee> cle = GlobalKey<EtatPileFeuilletee>();
      final List<int> dessus = <int>[];
      await tester.pumpWidget(hote(_reduit(pile(cle, dessus))));
      cle.currentState!.suivante();
      await tester.pump();
      expect(dessus, <int>[1]);
      expect(_rappels(), 0, reason: 'aucune image animee en mode reduit');
    });
  });
}
