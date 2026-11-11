// FOYER-ELEVE (04/11/2026) : la ligne « Foyer » (appareils et profils du
// foyer) ne s'affiche qu'a qui tient un foyer, par la capacite `aUnFoyer`,
// jamais par le role. Sans foyer, elle etait une ligne inerte qui promettait
// des appareils et des profils que l'eleve ne gere pas (releve du 04/11).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsAction, SemanticsNode;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';

import '../../support/harnais.dart';

List<Override> _session(
  AppRole role, {
  InterfaceMode mode = InterfaceMode.standard,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: role,
        profileId: 'p1',
        accountStatus: AccountStatus.active,
        interfaceMode: mode,
      ),
    ),
  ),
];

// La ligne visee, par sa description (« Les appareils et profils rattaches a
// votre foyer ») : le titre « Foyer » sert aussi a l'interrupteur des
// notifications du foyer, dans les Reglages, que ce lot ne touche pas.
Finder _ligneFoyer() =>
    find.widgetWithText(SettingRow, t.compte.appareilsDetail);

/// PROFILS P4 : le Compte partage est compose dans `PageCompte` ; sa ligne
/// « Foyer » (appareils) est une `LigneRubrique`, trouvee par sa legende.
Finder _ligneFoyerCompte() => find.text(t.compte.appareilsDetail);

Future<void> _monter(
  WidgetTester tester,
  Widget page,
  AppRole role, {
  InterfaceMode mode = InterfaceMode.standard,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      page,
      mode: mode,
      surcharges: _session(role, mode: mode),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Compte', () {
    for (final (String cas, AppRole role, InterfaceMode mode)
        in <(String, AppRole, InterfaceMode)>[
          (
            'eleve hors Interface guidee',
            AppRole.student,
            InterfaceMode.standard,
          ),
          ('eleve en Interface guidee', AppRole.student, InterfaceMode.enfant),
          ('enseignant', AppRole.teacher, InterfaceMode.standard),
          ('direction', AppRole.admin, InterfaceMode.standard),
        ]) {
      testWidgets('$cas : pas de ligne « Foyer »', (WidgetTester tester) async {
        await _monter(tester, const ComptePage(), role, mode: mode);
        expect(_ligneFoyerCompte(), findsNothing);
      });
    }

    testWidgets('qui tient un foyer : la ligne est la, et active', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await _monter(tester, const ComptePage(), AppRole.guardian);
      expect(_ligneFoyerCompte(), findsOneWidget);
      // Active : la ligne est un bouton qui se presse.
      final SemanticsNode noeud = tester.getSemantics(_ligneFoyerCompte());
      expect(noeud.flagsCollection.isButton, isTrue);
      expect(noeud.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantique.dispose();
    });
  });

  group('Reglages', () {
    testWidgets('eleve : pas de ligne « Foyer »', (WidgetTester tester) async {
      await _monter(tester, const ReglagesComptePage(), AppRole.student);
      expect(_ligneFoyer(), findsNothing);
      expect(find.text(t.compte.appareilsDetail), findsNothing);
      // Ni l'interrupteur des notifications du foyer (garde-cap, 04/11) :
      // aucun « Foyer » ne reste chez l'eleve.
      expect(find.text(t.compte.notificationsFoyerDetail), findsNothing);
      expect(find.text(t.compte.notificationsFoyer), findsNothing);
    });

    testWidgets('eleve en Interface guidee : pas de ligne « Foyer »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const ReglagesComptePage(),
        AppRole.student,
        mode: InterfaceMode.enfant,
      );
      expect(_ligneFoyer(), findsNothing);
    });

    testWidgets('qui tient un foyer : la ligne est la, et active', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const ReglagesComptePage(), AppRole.guardian);
      expect(_ligneFoyer(), findsOneWidget);
      expect(tester.widget<SettingRow>(_ligneFoyer()).onPress, isNotNull);
      // PROFILS P4 (garde-cap, 11/11/2026) : l'interrupteur des
      // notifications du foyer, que rien ne lisait, est retire.
      expect(find.text(t.compte.notificationsFoyerDetail), findsNothing);
    });
  });
}
