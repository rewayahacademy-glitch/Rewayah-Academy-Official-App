import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_parcours/libelles_tc_parcours.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/content_position.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/content_range.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_parcours/ports_externes/slot_action.dart';
import 'package:rewayah_academy/core/tc_parcours/source_contenu_seance.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/features/tc_flux_academique/bloc_avant_prochain_cours.dart';

import 'faux/faux_ports_externes.dart';
import 'support/hote_h.dart';

const String _groupe = 'g1';
const String _coran = 'res-coran';

LearningAssignment _travail({
  required String id,
  IntentionPedagogique intention = IntentionPedagogique.aRevoir,
  ContentRange? plage,
}) => LearningAssignment(
  id: id,
  groupId: _groupe,
  resourceId: _coran,
  contentRange: plage,
  purpose: intention,
  startsAtUtc: DateTime.utc(2026, 9, 20),
  createdBy: 'ens-1',
  status: StatutAssignation.aFaire,
);

List<Override> _surcharges({
  List<LearningAssignment> travaux = const <LearningAssignment>[],
  ContentPosition? reprise,
}) => <Override>[
  portTravailAVenirProvider.overrideWithValue(
    TravailAVenir(
      FauxAssignations(travaux: travaux),
      reprise == null
          ? const ContenuSeanceIndisponible()
          : FauxContenuSeance(
              reprisesDeGroupe: <String, ContentPosition>{_groupe: reprise},
            ),
    ),
  ),
];

void main() {
  group('bloc « Avant le prochain cours »', () {
    testWidgets('port non branche : le bloc le dit, et ne dit pas « rien »', (
      WidgetTester tester,
    ) async {
      telephone(tester);

      // Aucune surcharge : le provider canonique rend `null`, c'est-a-dire
      // « non branche ». Il ne leve pas -- l'Espace Groupe d'Agent A monte ce
      // bloc et planterait des le premier build.
      await tester.pumpWidget(
        hoteH(const BlocAvantProchainCours(groupeId: _groupe)),
      );
      await tester.pumpAndSettle();

      expect(find.text(LibellesParcours.avantNonBranche), findsOneWidget);
      expect(
        find.text(LibellesParcours.avantRien),
        findsNothing,
        reason:
            'un port non branche ne prouve aucune absence de travail : le dire '
            'serait mentir a la famille',
      );
      expect(find.byType(AppCard), findsNothing);
    });

    testWidgets('aucune tache : un etat vide qui ne propose rien', (
      WidgetTester tester,
    ) async {
      telephone(tester);

      await tester.pumpWidget(
        hoteH(
          const BlocAvantProchainCours(groupeId: _groupe),
          surcharges: _surcharges(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(LibellesParcours.avantRien), findsOneWidget);
      expect(
        find.text(LibellesParcours.avantNonBranche),
        findsNothing,
        reason: 'le port est branche ici : l absence de travail est mesuree',
      );
      // Aucun bouton, aucune carte : il n'y a rien a faire, et proposer une
      // action serait inviter a inventer une tache.
      expect(find.byType(ActionPrincipale), findsNothing);
      expect(find.byType(AppCard), findsNothing);
    });

    testWidgets('trois taches au maximum, avec leur intention', (
      WidgetTester tester,
    ) async {
      telephone(tester);

      await tester.pumpWidget(
        hoteH(
          const BlocAvantProchainCours(groupeId: _groupe),
          surcharges: _surcharges(
            travaux: <LearningAssignment>[
              _travail(
                id: 't1',
                intention: IntentionPedagogique.aApprendre,
                plage: ContentRange(
                  resourceId: _coran,
                  debut: const ContentPosition.ayah(
                    resourceId: _coran,
                    sourate: 2,
                    ayah: 255,
                  ),
                  fin: const ContentPosition.ayah(
                    resourceId: _coran,
                    sourate: 2,
                    ayah: 257,
                  ),
                ),
              ),
              _travail(id: 't2'),
              _travail(id: 't3'),
              _travail(id: 't4'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(LibellesParcours.intentionApprendre), findsOneWidget);
      expect(find.text(LibellesParcours.intentionRevoir), findsNWidgets(2));
      expect(find.text(LibellesParcours.avantRien), findsNothing);
      expect(
        find.textContaining('Sourate 2, versets 255'),
        findsOneWidget,
      );
    });

    testWidgets('« Reprendre le cours » apparait en tete quand elle existe', (
      WidgetTester tester,
    ) async {
      telephone(tester);

      await tester.pumpWidget(
        hoteH(
          const BlocAvantProchainCours(groupeId: _groupe),
          surcharges: _surcharges(
            travaux: <LearningAssignment>[_travail(id: 't1')],
            reprise: const ContentPosition.page(resourceId: _coran, page: 12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(LibellesParcours.avantReprendre), findsOneWidget);
      expect(find.textContaining('Page 12'), findsOneWidget);
    });

    testWidgets('une action choisie remonte a l hote, telle quelle', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final List<SlotAction> choisies = <SlotAction>[];

      await tester.pumpWidget(
        hoteH(
          BlocAvantProchainCours(
            groupeId: _groupe,
            onAction: choisies.add,
          ),
          surcharges: _surcharges(
            travaux: <LearningAssignment>[_travail(id: 't1')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppCard).first);
      await tester.pumpAndSettle();

      expect(choisies.single.id, 't1');
    });
  });
}
