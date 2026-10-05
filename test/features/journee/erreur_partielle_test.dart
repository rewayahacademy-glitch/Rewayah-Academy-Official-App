// LIB-ERR-2 : le bloc « echec partiel » de Ma journee (enseignant).
//
// Le texte cite ce qui manque vraiment : horaires de priere et pauses, cahiers
// a terminer, ou les deux ; les seances restent affichees et le bouton
// « Reessayer » relance les trois lectures.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart'
    show cahiersEnFileProvider;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';

final DateTime _maintenant = DateTime(2026, 9, 28, 16, 10);

final SeanceEnseignant _seance = SeanceEnseignant(
  id: 's1',
  debut: DateTime(2026, 9, 28, 17),
  fin: DateTime(2026, 9, 28, 17, 45),
  statut: StatutSeance.planifiee,
  nbParticipants: 4,
  cahierDepose: false,
  groupeId: 'g1',
  groupeLibelle: 'Al-Badr',
);

int _lecturesRetards = 0;

List<Override> _surcharges({
  required bool horairesEnEchec,
  required bool retardsEnEchec,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.teacher,
        profileId: 'ens-1',
        householdId: 'h1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
  cahiersEnFileProvider.overrideWith((Ref _) async => const <String>{}),
  maintenantJourneeProvider.overrideWithValue(() => _maintenant),
  seancesEnseignantProvider.overrideWith(
    (Ref _) async => <SeanceEnseignant>[_seance],
  ),
  cahiersEnRetardProvider.overrideWith((Ref _) async {
    _lecturesRetards++;
    if (retardsEnEchec) throw StateError('reseau');
    return const <CahierEnRetard>[];
  }),
  reglagesPriereProvider('ens-1').overrideWith((Ref _) async {
    if (horairesEnEchec) throw StateError('reseau');
    return null;
  }),
  valeurRegleProvider((profilId: 'ens-1', cle: CleRegle.pauseEntreCours))
      .overrideWith((Ref _) async {
        if (horairesEnEchec) throw StateError('reseau');
        return 10;
      }),
];

Future<void> _monter(
  WidgetTester tester, {
  required bool horaires,
  required bool retards,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(390, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(
        horairesEnEchec: horaires,
        retardsEnEchec: retards,
      ),
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext contexte, Widget? app) => Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: app!,
            ),
          ),
          home: const JourneePage(),
        ),
      ),
    ),
  );
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  const ValueKey<String> cle = ValueKey<String>('journee-erreur-partielle');
  const ValueKey<String> bouton = ValueKey<String>(
    'journee-erreur-partielle-reessayer',
  );

  final Map<String, (bool, bool, String Function())> cas =
      <String, (bool, bool, String Function())>{
        'horaires et pauses seuls': (
          true,
          false,
          () => t.enseignant.journee.erreurPartielle,
        ),
        'cahiers a terminer seuls': (
          false,
          true,
          () => t.enseignant.journee.erreurPartielleRetards,
        ),
        'les trois ensemble': (
          true,
          true,
          () => t.enseignant.journee.erreurPartielleTout,
        ),
      };

  for (final MapEntry<String, (bool, bool, String Function())> c
      in cas.entries) {
    testWidgets('${c.key} : la phrase cite ce qui manque', (
      WidgetTester tester,
    ) async {
      await _monter(tester, horaires: c.value.$1, retards: c.value.$2);
      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.byKey(cle)).data, c.value.$3());
      expect(find.byKey(bouton), findsOneWidget);
      // Les seances restent affichees : l'echec n'est que partiel.
      expect(find.text(t.enseignant.journee.erreur), findsNothing);
    });
  }

  test('chaque phrase nomme sa cause, jamais les autres', () {
    expect(t.enseignant.journee.erreurPartielle, contains('prière'));
    expect(t.enseignant.journee.erreurPartielle, isNot(contains('cahiers')));
    expect(t.enseignant.journee.erreurPartielleRetards, contains('cahiers'));
    expect(
      t.enseignant.journee.erreurPartielleRetards,
      isNot(contains('prière')),
    );
    expect(t.enseignant.journee.erreurPartielleTout, contains('cahiers'));
    expect(t.enseignant.journee.erreurPartielleTout, contains('prière'));
  });

  testWidgets('sans echec, le bloc est absent', (WidgetTester tester) async {
    await _monter(tester, horaires: false, retards: false);
    expect(find.byKey(cle), findsNothing);
    expect(find.byKey(bouton), findsNothing);
  });

  testWidgets('Reessayer relance la lecture des cahiers a terminer', (
    WidgetTester tester,
  ) async {
    await _monter(tester, horaires: false, retards: true);
    final int avant = _lecturesRetards;
    await tester.ensureVisible(find.byKey(bouton));
    await tester.tap(find.byKey(bouton));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(_lecturesRetards, greaterThan(avant));
  });

  testWidgets('la phrase et le bouton tiennent a 200 % en RTL', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      horaires: true,
      retards: true,
      echelle: 2,
      direction: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(cle), findsOneWidget);
    expect(find.byKey(bouton), findsOneWidget);
  });
}
