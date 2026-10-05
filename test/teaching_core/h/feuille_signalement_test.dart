import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/core/tc_parcours/student_concern.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/features/tc_flux_academique/feuille_signalement.dart';

import 'support/hote_h.dart';

const String _interne = 'Confusion sad / sin, deux retards cette semaine.';

/// Un hote minimal qui ouvre la feuille : `AppBottomSheet.ouvrir` a besoin
/// d'une route a fermer, comme dans l'application.
class _Ouvreur extends StatelessWidget {
  const _Ouvreur();

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

Future<void> _ouvrirLaFeuille(WidgetTester tester, List<Override> s) async {
  await tester.pumpWidget(hoteH(const _Ouvreur(), surcharges: s));
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

/// Fait defiler jusqu'au bouton avant de le toucher.
///
/// Sur 390 x 844, la feuille depasse la hauteur de l'ecran : c'est le cas reel
/// sur un telephone, et `AppBottomSheet` le prevoit par un `SingleChildScrollView`.
/// Un test qui toucherait un bouton hors champ mesurerait une feuille qui n'existe
/// que sur une tablette.
Future<void> _envoyer(WidgetTester tester) async {
  final Finder bouton = find.text(t.tc.parcours.signalement.envoyer);
  await tester.ensureVisible(bouton);
  await tester.pumpAndSettle();
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

void main() {
  group('feuille de signalement', () {
    testWidgets('le contexte est dit, il n est pas saisi', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final SignalementMemoire depot = SignalementMemoire('ens-1');

      await _ouvrirLaFeuille(tester, <Override>[
        portSignalementProvider.overrideWithValue(depot),
      ]);

      expect(
        find.text(t.tc.parcours.signalement.contexte(eleve: 'Amina')),
        findsOneWidget,
      );
      // Un seul champ ouvert, la note interne : aucun champ d'identifiant a
      // retaper. Le message famille se choisit en phrases-types (L7), le
      // champ libre s'ouvre par « Autre ».
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text(t.motifs.signalement.pedagogique.renforcement),
        findsOneWidget,
      );
      // La regle est ecrite sous le champ concerne, pas dans une page d'aide.
      expect(
        find.text(t.tc.parcours.signalement.interneAide),
        findsOneWidget,
      );
    });

    testWidgets('sans note interne, le bouton dit ce qui manque', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final SignalementMemoire depot = SignalementMemoire('ens-1');

      await _ouvrirLaFeuille(tester, <Override>[
        portSignalementProvider.overrideWithValue(depot),
      ]);

      // Jamais grise (K-56).
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.byType(ActionPrincipale),
      );
      expect(bouton.onPress, isNotNull);
      await _envoyer(tester);
      expect(
        find.text(t.tc.parcours.signalement.interneRequis),
        findsOneWidget,
      );
      expect(await depot.mesSignalements(), isEmpty);
    });

    testWidgets('L7 : la phrase-type part telle quelle vers la famille', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final SignalementMemoire depot = SignalementMemoire('ens-1');

      await _ouvrirLaFeuille(tester, <Override>[
        portSignalementProvider.overrideWithValue(depot),
      ]);

      await tester.enterText(find.byType(TextField).first, _interne);
      final Finder phrase = find.text(
        t.motifs.signalement.pedagogique.revision,
      );
      await tester.ensureVisible(phrase);
      await tester.pumpAndSettle();
      await tester.tap(phrase);
      await tester.pumpAndSettle();
      await _envoyer(tester);

      final StudentConcern signalement = (await depot.mesSignalements()).single;
      expect(
        signalement.pourLaFamille()!.message,
        t.motifs.signalement.pedagogique.revision,
      );
    });

    testWidgets('sans message famille, le signalement part quand meme', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final SignalementMemoire depot = SignalementMemoire('ens-1');

      await _ouvrirLaFeuille(tester, <Override>[
        portSignalementProvider.overrideWithValue(depot),
      ]);

      await tester.enterText(find.byType(TextField).first, _interne);
      await tester.pumpAndSettle();
      await _envoyer(tester);

      final StudentConcern signalement = (await depot.mesSignalements()).single;
      expect(signalement.internalDetails, _interne);
      // Le cas normal : rien n'a ete ecrit pour la famille, donc rien ne peut
      // lui etre transmis.
      expect(signalement.familySummary, isNull);
      expect(signalement.peutEtreTransmis, isFalse);
      expect(signalement.pourLaFamille(), isNull);
      // Le contexte a bien ete joint sans que personne ne le tape.
      expect(signalement.groupeId, 'g1');
      expect(signalement.sessionId, 's1');
      expect(signalement.academyId, 'RA-AB0012');
      expect(signalement.enseignantId, 'ens-1');
    });

    testWidgets('avec un message famille, les deux textes restent separes', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final SignalementMemoire depot = SignalementMemoire('ens-1');

      await _ouvrirLaFeuille(tester, <Override>[
        portSignalementProvider.overrideWithValue(depot),
      ]);

      await tester.enterText(find.byType(TextField).first, _interne);
      await tester.ensureVisible(find.byKey(SelecteurMotif.cleAutre));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SelecteurMotif.cleAutre));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).at(1),
        'Un point de prononciation a travailler a la maison.',
      );
      await tester.pumpAndSettle();
      await _envoyer(tester);

      final StudentConcern signalement = (await depot.mesSignalements()).single;
      final ResumeFamilleSignalement resume = signalement.pourLaFamille()!;

      expect(resume.message, isNot(contains('sad')));
      expect(
        resume.versJson().values.join(' '),
        isNot(contains(_interne)),
      );
    });
  });
}
