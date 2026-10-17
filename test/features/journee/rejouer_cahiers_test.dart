// L2-03 : la file des cahiers hors ligne se rejoue vraiment.
//
// Trois preuves, sur la Journee montee seule :
// - a l'ouverture, `rejouer` part une fois, et « 2 cahiers de transmission
//   envoyes » s'affiche dans un `LocalFeedback`
//   quand la file en contenait deux ; une file vide n'affiche rien ;
// - un retour du reseau (hors ligne vers en ligne) rejoue la file une seconde
//   fois ; le passage en ligne vers hors ligne, lui, ne rejoue rien ;
// - une reconstruction de la page ne rejoue pas une seconde fois.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart'
    show
        SoumissionCahier,
        SortCahier,
        cahiersEnFileProvider,
        soumissionCahierProvider;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/local_feedback.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

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

/// Un faux soumetteur : compte les appels a `rejouer` et rend les reponses
/// donnees, puis 0 une fois la liste epuisee.
class _FauxSoumission implements SoumissionCahier {
  _FauxSoumission(this._reponses);

  final List<int> _reponses;

  /// Combien de fois la file a ete rejouee.
  int appels = 0;

  @override
  Future<int> rejouer() async {
    appels++;
    return _reponses.isEmpty ? 0 : _reponses.removeAt(0);
  }

  @override
  Future<SortCahier> soumettre(CahierARendre cahier) =>
      throw UnimplementedError('hors du test');
}

/// Un faux reseau que le test pilote : `true` hors ligne, `false` en ligne.
class _ReseauPilote implements ServiceReseau {
  final StreamController<bool> controleur = StreamController<bool>.broadcast();

  @override
  Stream<bool> horsLigne() => controleur.stream;

  /// Ferme le flux a la fin du test.
  Future<void> fermer() => controleur.close();
}

List<Override> _surcharges({
  required _FauxSoumission soumission,
  required _ReseauPilote reseau,
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
  serviceReseauProvider.overrideWithValue(reseau),
  soumissionCahierProvider.overrideWithValue(soumission),
  serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
  cahiersEnFileProvider.overrideWith((Ref _) async => const <String>{}),
  maintenantJourneeProvider.overrideWithValue(() => _maintenant),
  seancesEnseignantProvider.overrideWith(
    (Ref _) async => <SeanceEnseignant>[_seance],
  ),
  cahiersEnRetardProvider.overrideWith(
    (Ref _) async => const <CahierEnRetard>[],
  ),
  reglagesPriereProvider('ens-1').overrideWith((Ref _) async => null),
  valeurRegleProvider((profilId: 'ens-1', cle: CleRegle.pauseEntreCours))
      .overrideWith((Ref _) async => 10),
];

Future<void> _monter(
  WidgetTester tester, {
  required _FauxSoumission soumission,
  required _ReseauPilote reseau,
}) async {
  tester.view.physicalSize = const Size(390, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(soumission: soumission, reseau: reseau),
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
  testWidgets('a l ouverture, la file part une fois et le compte s affiche', (
    WidgetTester tester,
  ) async {
    final _FauxSoumission soumission = _FauxSoumission(<int>[2]);
    final _ReseauPilote reseau = _ReseauPilote();
    addTearDown(reseau.fermer);

    await _monter(tester, soumission: soumission, reseau: reseau);

    expect(soumission.appels, 1);
    expect(
      find.text(t.enseignant.journee.cahiersEnvoyes(n: 2)),
      findsOneWidget,
    );
    expect(find.text('2 cahiers de transmission envoyés'), findsOneWidget);
    expect(find.byType(LocalFeedback), findsOneWidget);
  });

  testWidgets('une file vide ne rend rien, ni a l ouverture ni au retour', (
    WidgetTester tester,
  ) async {
    final _FauxSoumission soumission = _FauxSoumission(<int>[]);
    final _ReseauPilote reseau = _ReseauPilote();
    addTearDown(reseau.fermer);

    await _monter(tester, soumission: soumission, reseau: reseau);
    reseau.controleur.add(true);
    await tester.pump();
    reseau.controleur.add(false);
    await tester.pump();
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(soumission.appels, 2);
    expect(find.textContaining('envoy'), findsNothing);
  });

  testWidgets('le retour du reseau rejoue la file une seconde fois', (
    WidgetTester tester,
  ) async {
    final _FauxSoumission soumission = _FauxSoumission(<int>[0, 1]);
    final _ReseauPilote reseau = _ReseauPilote();
    addTearDown(reseau.fermer);

    await _monter(tester, soumission: soumission, reseau: reseau);
    expect(soumission.appels, 1);

    reseau.controleur.add(true);
    await tester.pump();
    expect(soumission.appels, 1, reason: 'passer hors ligne ne rejoue rien');

    reseau.controleur.add(false);
    await tester.pump();
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(soumission.appels, 2);
    expect(find.text('1 cahier de transmission envoyé'), findsOneWidget);
  });

  testWidgets('une reconstruction de la page ne rejoue pas une seconde fois', (
    WidgetTester tester,
  ) async {
    final _FauxSoumission soumission = _FauxSoumission(<int>[]);
    final _ReseauPilote reseau = _ReseauPilote();
    addTearDown(reseau.fermer);

    await _monter(tester, soumission: soumission, reseau: reseau);
    // Un changement de taille reconstruit l'arbre sans recreer l'ecran.
    tester.view.physicalSize = const Size(400, 3000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(soumission.appels, 1, reason: 'une reconstruction ne rejoue pas');
  });
}
