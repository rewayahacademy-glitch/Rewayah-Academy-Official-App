// SALLE-ROBUSTE : la salle ne plante pas quand le serveur d'une fonction n'est
// pas branche.
//
// Les providers de `PortAnnotations`, `PortAssignations`, `PortFeedback`,
// `PortSignalement` et `PortPostCours` levaient `UnimplementedError` par
// defaut. Ils rendent maintenant une implementation « indisponible ». Chaque
// test monte l'ecran SANS surcharger le port, c'est-a-dire comme la production
// d'aujourd'hui, et verifie qu'aucune exception ne remonte et que l'ecran dit
// calmement ce qu'il en est.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/evenements_outils.dart';
import 'package:rewayah_academy/core/tc_outils/fonction_indisponible.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_assignations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/core/tc_parcours/port_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/port_post_cours.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/core/tc_parcours/session_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/student_concern.dart';
import 'package:rewayah_academy/core/widgets/bouton_outil.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';
import 'package:rewayah_academy/features/tc_dock/teaching_dock.dart';
import 'package:rewayah_academy/features/tc_flux_academique/carte_feedback_seance.dart';
import 'package:rewayah_academy/features/tc_flux_academique/feuille_signalement.dart';
import 'package:rewayah_academy/features/tc_flux_academique/panneau_post_cours.dart';

import 'd/faux/faux_dock_hote.dart';
import 'd/support/hote_d.dart';
import 'h/support/hote_h.dart' as h;

Finder _boutonNomme(String libelle) => find.byWidgetPredicate(
  (Widget widget) => widget is BoutonOutil && widget.libelle == libelle,
);

void main() {
  group('les cinq ports ont un defaut qui ne leve pas', () {
    test(
      'annotations : rien a lire, toute ecriture dit « indisponible »',
      () async {
        const PortAnnotations port = AnnotationsIndisponibles();
        expect(port, isA<PortIndisponible>());
        expect(
          await port.couche(
            resourceId: 'r',
            portee: PorteeAnnotation.temporaire,
          ),
          isNull,
        );
        expect(await port.suivre(resourceId: 'r').isEmpty, isTrue);
        await expectLater(
          port.annulerDernier('c'),
          throwsA(isA<FonctionIndisponible>()),
        );
      },
    );

    test('assignations : listes vides, creation refusee en clair', () async {
      const PortAssignations port = AssignationsIndisponibles();
      expect(port, isA<PortIndisponible>());
      expect(await port.pourGroupe('g'), isEmpty);
      expect(await port.aVenir(groupId: 'g'), isEmpty);
      await expectLater(
        port.creerDepuisSelection(
          groupId: 'g',
          resourceId: 'r',
          purpose: IntentionPedagogique.aApprendre,
        ),
        throwsA(isA<FonctionIndisponible>()),
      );
      await expectLater(
        port.changerStatut('a', StatutAssignation.annule),
        throwsA(isA<FonctionIndisponible>()),
      );
    });

    test('feedback : aucune question, tendance sous le seuil', () async {
      const PortFeedback port = FeedbackIndisponible();
      expect(port, isA<PortIndisponible>());
      expect(await port.questionPour('s'), isNull);
      final TendanceFeedback tendance = await port.tendance(groupeId: 'g');
      expect(tendance.visibleParEnseignant, isFalse);
      expect(tendance.repartition, isNull);
      await expectLater(
        port.soumettre(
          sessionId: 's',
          questionId: 'q',
          reponse: ReponseFeedback.values.first,
        ),
        throwsA(isA<EchecFeedback>()),
      );
    });

    test('signalement : rien d est avale, tout est refuse en clair', () async {
      const PortSignalement port = SignalementIndisponible();
      expect(port, isA<PortIndisponible>());
      expect(await port.mesSignalements(), isEmpty);
      await expectLater(
        port.signaler(
          categorie: CategorieSignalement.values.first,
          groupeId: 'g',
          academyId: 'RA-1',
          internalDetails: 'note',
        ),
        throwsA(isA<FonctionIndisponible>()),
      );
      await expectLater(
        port.transmettre(concernId: 'c', cible: CibleTransmission.values.first),
        throwsA(isA<FonctionIndisponible>()),
      );
    });

    test(
      'post-cours : preparer et enregistrer disent « indisponible »',
      () async {
        const PortPostCours port = PostCoursIndisponible();
        expect(port, isA<PortIndisponible>());
        await expectLater(
          port.preparer('s'),
          throwsA(isA<FonctionIndisponible>()),
        );
      },
    );
  });

  group('la salle ne plante pas sans serveur', () {
    late FauxDockHote faux;
    late List<EvenementOutil> emis;

    ContentRange plage() =>
        ContentRange(resourceId: ressourceTest, debut: ayah1, fin: ayah2);

    setUp(() {
      faux = FauxDockHote(
        support: supportTest(),
        selection: SelectionSupport(
          plage: plage(),
          ancrageSemantique: ayah1,
          ancrageSpatial: pageCourante,
        ),
      );
      emis = <EvenementOutil>[];
    });

    // Seule la position du dock est surchargee (elle n'a rien de serveur) ;
    // les cinq ports gardent leur defaut de production.
    List<Override> positionSeule() => <Override>[
      portPositionDockProvider.overrideWithValue(PositionDockMemoire()),
    ];

    testWidgets('dock : « Marquer » dit que ce n est pas disponible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteD(
          TeachingDock(hote: faux, onEvenement: emis.add),
          surcharges: positionSeule(),
        ),
      );

      await tester.tap(_boutonNomme(t.tc.outils.dock.marquer));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(t.tc.indisponible), findsOneWidget);
      expect(find.text(t.tc.outils.marquer.titre), findsNothing);
      expect(emis, isEmpty);
    });

    testWidgets('dock : « Revision » dit que ce n est pas disponible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteD(
          TeachingDock(hote: faux, onEvenement: emis.add),
          surcharges: positionSeule(),
        ),
      );

      await tester.tap(_boutonNomme(t.tc.outils.dock.revision));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(t.tc.indisponible), findsOneWidget);
      expect(find.text(t.tc.outils.revision.posee), findsNothing);
    });

    testWidgets('dock : le stylet ne s arme pas, et le dit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteD(
          TeachingDock(hote: faux, onEvenement: emis.add),
          surcharges: positionSeule(),
        ),
      );

      await tester.tap(_boutonNomme(t.tc.outils.dock.stylet));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(t.tc.indisponible), findsOneWidget);
      expect(find.text(t.tc.outils.trait.annuler), findsNothing);
    });

    testWidgets('couche d annotation : un trait de stylet ne leve rien', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteD(
          SizedBox(
            width: 200,
            height: 400,
            child: CoucheAnnotation(
              support: supportTest(),
              contexte: const ContexteDock(
                groupeId: 'groupe-1',
                sessionId: 'seance-1',
                profilId: 'prof-1',
              ),
              traits: const [],
              onEvenement: emis.add,
              onAncrageDegrade: () {},
            ),
          ),
        ),
      );

      final TestPointer pointeur = TestPointer(1, PointerDeviceKind.stylus);
      await tester.sendEventToBinding(pointeur.down(const Offset(20, 10)));
      for (int i = 1; i <= 6; i++) {
        await tester.sendEventToBinding(
          pointeur.move(Offset(20 + i * 5.0, 10 + i * 2.0)),
        );
        await tester.pump();
      }
      await tester.sendEventToBinding(pointeur.up());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        emis.whereType<EvenementTraitTermine>(),
        isEmpty,
        reason: 'un trait non conserve n est pas annonce comme termine',
      );
    });

    testWidgets('carte de feedback : rien a demander, rien a afficher', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        h.hoteH(const CarteFeedbackSeance(sessionId: 's1')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CarteFeedbackSeance), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('signalement : la feuille dit la limite, sans bouton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(h.hoteH(const _OuvreurSignalement()));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(t.tc.indisponible), findsOneWidget);
      expect(
        find.text(t.tc.parcours.signalement.envoyer),
        findsNothing,
        reason: 'un bouton qui ne peut pas aboutir n est pas rendu',
      );
    });

    testWidgets('post-cours : le panneau dit la limite, sans reessayer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(h.hoteH(const PanneauPostCours(sessionId: 's1')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(t.tc.indisponible), findsOneWidget);
      expect(find.text(t.tc.parcours.postCours.repriseInconnue), findsNothing);
    });
  });
}

/// Un hote minimal qui ouvre la feuille de signalement.
class _OuvreurSignalement extends StatelessWidget {
  const _OuvreurSignalement();

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => FeuilleSignalement.ouvrir(
      context,
      groupeId: 'g1',
      academyId: 'RA-AB0012',
      prenomEleve: 'Amina',
      sessionId: 's1',
    ),
    child: const Text('ouvrir'),
  );
}
