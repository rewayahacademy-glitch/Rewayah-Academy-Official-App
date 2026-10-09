import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart'
    show ModeAffichagePartage;
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/evenements_outils.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart'
    show CanalFiabilite;
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import 'support/hote_d.dart';

void main() {
  group('qui ecrit, qui navigue', () {
    test('sur un appareil a stylet, le doigt ne dessine pas', () {
      final Set<PointerDeviceKind> appareils =
          PolitiqueSaisie.appareilsDeDessin(
            styletDetecte: true,
            styletArme: true,
          );
      expect(appareils, contains(PointerDeviceKind.stylus));
      expect(
        appareils,
        isNot(contains(PointerDeviceKind.touch)),
        reason: 'stylet = encre, doigt = pan et zoom (spec 8.4)',
      );
    });

    // TB-STYLET-1 (plan V2 §7, ligne 164 ; TB21) : « stylet pour l'encre
    // lorsque Ecrire est actif ». Avant TB-7a, le stylet ecrivait toujours.
    test('le stylet n ecrit pas tant que l outil n est pas arme', () {
      for (final bool detecte in <bool>[true, false]) {
        expect(
          PolitiqueSaisie.appareilsDeDessin(
            styletDetecte: detecte,
            styletArme: false,
          ),
          isEmpty,
          reason: 'stylet detecte : $detecte',
        );
      }
    });

    test('sans stylet, le doigt ecrit seulement si l outil est arme', () {
      expect(
        PolitiqueSaisie.appareilsDeDessin(
          styletDetecte: false,
          styletArme: false,
        ),
        isNot(contains(PointerDeviceKind.touch)),
      );
      expect(
        PolitiqueSaisie.appareilsDeDessin(
          styletDetecte: false,
          styletArme: true,
        ),
        contains(PointerDeviceKind.touch),
      );
    });

    test('outil arme : le stylet ecrit, qu il ait ete detecte ou non', () {
      for (final bool detecte in <bool>[true, false]) {
        expect(
          PolitiqueSaisie.appareilsDeDessin(
            styletDetecte: detecte,
            styletArme: true,
          ),
          contains(PointerDeviceKind.stylus),
        );
      }
    });
  });

  group('la couche pose des traits', () {
    late AnnotationsMemoire annotations;
    late List<EvenementOutil> emis;
    late int ancragesDegrades;

    setUp(() {
      annotations = AnnotationsMemoire('prof-1');
      emis = <EvenementOutil>[];
      ancragesDegrades = 0;
    });

    tearDown(() async => annotations.liberer());

    Widget couche({
      ModeAffichagePartage mode = ModeAffichagePartage.verse,
      List<TraitVectoriel> traits = const <TraitVectoriel>[],
    }) => SizedBox(
      width: 200,
      height: 400,
      child: CoucheAnnotation(
        support: supportTest(mode: mode),
        contexte: const ContexteDock(
          groupeId: 'groupe-1',
          sessionId: 'seance-1',
          profilId: 'prof-1',
        ),
        traits: traits,
        onEvenement: emis.add,
        onAncrageDegrade: () => ancragesDegrades++,
      ),
    );

    List<Override> surcharges() => <Override>[
      portAnnotationsProvider.overrideWithValue(annotations),
    ];

    /// L'hote avec l'outil d'ecriture arme (TB-STYLET-1 : rien n'ecrit
    /// sans lui).
    Widget hoteArme(Widget enfant) {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: surcharges(),
      );
      addTearDown(conteneur.dispose);
      conteneur
          .read(etatOutilsProvider.notifier)
          .choisirOutil(OutilDock.stylet);
      return UncontrolledProviderScope(
        container: conteneur,
        child: hoteSansScope(enfant),
      );
    }

    /// Trace un geste avec l'appareil demande.
    Future<void> tracer(
      WidgetTester tester,
      PointerDeviceKind appareil, {
      Offset depart = const Offset(20, 10),
    }) async {
      final TestPointer pointeur = TestPointer(1, appareil);
      await tester.sendEventToBinding(pointeur.down(depart));
      for (int i = 1; i <= 6; i++) {
        await tester.sendEventToBinding(
          pointeur.move(depart + Offset(i * 5.0, i * 2.0)),
        );
        await tester.pump();
      }
      await tester.sendEventToBinding(pointeur.up());
      await tester.pumpAndSettle();
    }

    testWidgets('le stylet ne pose rien tant que l outil n est pas arme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(couche(), surcharges: surcharges()));
      await tracer(tester, PointerDeviceKind.stylus);

      expect(annotations.couches, isEmpty);
      expect(emis, isEmpty);
    });

    testWidgets('un trait de stylet s ancre au verset touche', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteArme(couche()));
      await tracer(tester, PointerDeviceKind.stylus);

      final AnnotationLayer posee = annotations.couches.single;
      expect(posee.traits, hasLength(1));
      expect(
        posee.traits.single.ancrage,
        ayah1,
        reason: 'le premier verset occupe le haut du support',
      );
      expect(posee.portee, PorteeAnnotation.temporaire);
      expect(ancragesDegrades, 0);

      // Pendant le geste : ephemere. A la fin : fiable.
      expect(emis.whereType<EvenementTraitEnCours>(), isNotEmpty);
      expect(
        emis.whereType<EvenementTraitEnCours>().first.canal,
        CanalFiabilite.ephemere,
      );
      expect(emis.last, isA<EvenementTraitTermine>());
      expect(emis.last.canal, CanalFiabilite.fiable);
    });

    testWidgets('le doigt ne pose rien quand le stylet n est pas arme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(couche(), surcharges: surcharges()));
      await tracer(tester, PointerDeviceKind.touch);

      expect(annotations.couches, isEmpty);
      expect(emis, isEmpty);
    });

    testWidgets(
      'le doigt pose un trait quand le stylet est arme, faute de stylet',
      (WidgetTester tester) async {
        final ProviderContainer conteneur = ProviderContainer(
          overrides: surcharges(),
        );
        addTearDown(conteneur.dispose);
        conteneur
            .read(etatOutilsProvider.notifier)
            .choisirOutil(OutilDock.stylet);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: conteneur,
            child: hoteSansScope(couche()),
          ),
        );
        await tracer(tester, PointerDeviceKind.touch);

        expect(annotations.couches.single.traits, hasLength(1));
      },
    );

    testWidgets('sur page figee, un trait hors bloc s ancre a la page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteArme(couche(mode: ModeAffichagePartage.page)),
      );
      // Sous les deux versets : aucun bloc de texte a cet endroit.
      await tracer(
        tester,
        PointerDeviceKind.stylus,
        depart: const Offset(20, 200),
      );

      expect(annotations.couches.single.traits.single.ancrage, pageCourante);
      expect(
        ancragesDegrades,
        0,
        reason: 'une page figee ne se recompose pas : rien n est degrade',
      );
    });

    testWidgets('sur rendu reflowable, un trait hors bloc est signale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteArme(couche()));
      await tracer(
        tester,
        PointerDeviceKind.stylus,
        depart: const Offset(20, 200),
      );

      expect(annotations.couches.single.traits.single.ancrage, pageCourante);
      expect(
        ancragesDegrades,
        1,
        reason:
            "l'annotation suivra la page et pas les mots : l'hote doit "
            'pouvoir le dire',
      );
    });

    testWidgets('la gomme retire le trait qu elle traverse', (
      WidgetTester tester,
    ) async {
      final TraitVectoriel existant = TraitVectoriel(
        id: 't-existant',
        ancrage: ayah1,
        outil: OutilTrait.stylet,
        intention: IntentionPedagogique.aRevoir,
        points: const <PointNormalise>[
          PointNormalise(0, 0.25),
          PointNormalise(1, 0.25),
        ],
      );
      final AnnotationLayer couchePosee = (await annotations.couche(
        resourceId: ressourceTest,
        sessionId: 'seance-1',
        portee: PorteeAnnotation.temporaire,
      ))!;
      await annotations.ajouterTrait(couchePosee.id, existant);

      final ProviderContainer conteneur = ProviderContainer(
        overrides: surcharges(),
      );
      addTearDown(conteneur.dispose);
      conteneur.read(etatOutilsProvider.notifier)
        ..choisirOutil(OutilDock.stylet)
        ..choisirOutilTrait(OutilTrait.gomme);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: conteneur,
          child: hoteSansScope(couche(traits: <TraitVectoriel>[existant])),
        ),
      );
      // Le trait existant passe a y = 10 (0.25 de 40 points) : la gomme le
      // traverse.
      await tracer(
        tester,
        PointerDeviceKind.stylus,
        depart: const Offset(20, 10),
      );

      expect(annotations.couches.single.traits, isEmpty);
      expect(emis.whereType<EvenementTraitRetire>(), hasLength(1));
      expect(emis.last.canal, CanalFiabilite.fiable);
    });

    testWidgets('sans geste : Suppr et l action semantique effacent', (
      WidgetTester tester,
    ) async {
      TraitVectoriel trait(String id) => TraitVectoriel(
        id: id,
        ancrage: ayah1,
        outil: OutilTrait.stylet,
        intention: IntentionPedagogique.aRevoir,
        points: const <PointNormalise>[
          PointNormalise(0, 0.25),
          PointNormalise(1, 0.25),
        ],
      );
      final AnnotationLayer couchePosee = (await annotations.couche(
        resourceId: ressourceTest,
        sessionId: 'seance-1',
        portee: PorteeAnnotation.temporaire,
      ))!;
      await annotations.ajouterTrait(couchePosee.id, trait('t-1'));
      await annotations.ajouterTrait(couchePosee.id, trait('t-2'));

      final SemanticsHandle semantique = tester.ensureSemantics();
      await tester.pumpWidget(
        hoteD(
          couche(traits: <TraitVectoriel>[trait('t-1'), trait('t-2')]),
          surcharges: surcharges(),
        ),
      );

      // L'ardoise se nomme et se dit facultative.
      final Finder ardoise = find.bySemanticsLabel(t.tc.outils.trait.ardoise);
      expect(ardoise, findsOneWidget);

      // Clavier : la surface prend le focus, Suppr retire le dernier trait.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(
        annotations.couches.single.traits.map((TraitVectoriel x) => x.id),
        <String>['t-1'],
      );

      // Lecteur d'ecran : l'action « Effacer mon dernier trait ».
      final SemanticsNode noeud = tester.getSemantics(ardoise);
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.customAction,
          viewId: tester.view.viewId,
          nodeId: noeud.id,
          arguments: CustomSemanticsAction.getIdentifier(
            CustomSemanticsAction(label: t.tc.outils.trait.effacerDernier),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(annotations.couches.single.traits, isEmpty);
      expect(emis.whereType<EvenementTraitRetire>(), hasLength(2));
      semantique.dispose();
    });
  });
}
