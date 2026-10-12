// LIVE-PAUSE-01b : la commande de pause de la Classe Live suit la capacite lue
// du serveur (`PauseSeance.peutPiloter`), jamais le role.
//
// Avant ce lot, `classe_live_page.dart` lisait `p.peutPiloter && enseignant` :
// le role decidait en plus de la capacite, alors que le commentaire disait
// l'inverse, et aucun test ne tombait si `peutPiloter` etait retire de la
// ligne. Ce test monte la vraie page, pour de vrai, avec un faux moteur :
// - l'enseignant avec la capacite : la commande « Demarrer la pause » existe ;
// - l'enseignant SANS la capacite : rien (retirer `peutPiloter` de la ligne
//   fait tomber ce cas) ;
// - l'eleve, que le serveur ne dote jamais de la capacite : rien ;
// - le role n'entre pas dans la decision : un jeton eleve auquel le serveur
//   donnerait la capacite voit la commande (la capacite seule decide).
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/tc_classe/session_live_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';

import 'faux/faux_classe.dart';
import 'support/hote_classe.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 12, 18);

SessionClockVM _horloge() => SessionClockVM(
  sessionId: 's1',
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 60)),
  joinOpensAtUtc: _t0.subtract(const Duration(minutes: 15)),
  fenetreAcces: const Duration(minutes: 15),
  graceApresFin: const Duration(minutes: 30),
  horlogeUtilisateur: const HorlogeAffichee(
    fuseauIana: 'Europe/London',
    libelleVille: 'Londres',
    heureLocaleRendue: '19:15',
    dateLocaleRendue: '12 oct. 2026',
  ),
  phase: PhaseSeance.enCours,
  restant: const Duration(minutes: 45),
  rejoindreOuvert: true,
  calculeeAUtc: _t0.add(const Duration(minutes: 15)),
);

PauseSeance _programmee({required bool peutPiloter}) => PauseSeance(
  statut: StatutPause.programmee,
  dureePrevueMinutes: 10,
  debutPrevuUtc: _t0.add(const Duration(minutes: 20)),
  peutPiloter: peutPiloter,
);

/// Les actions que la page passe a la salle : c'est la ligne `onPause` de
/// `classe_live_page.dart` elle-meme. Le chrono recontrole `peutPiloter` de son
/// cote, donc seule cette lecture voit la ligne de la page.
ActionsSeance _actionsDeLaPage(WidgetTester tester) =>
    tester.widget<SalleSeance>(find.byType(SalleSeance)).actions;

void main() {
  Future<void> monter(
    WidgetTester tester, {
    required String role,
    required bool peutPiloter,
  }) async {
    final FauxMoteurClasse moteur = FauxMoteurClasse();
    final FauxServiceVideoClasse video = FauxServiceVideoClasse(
      acces0: accesDe(role),
    );
    await monterClasse(
      tester,
      contexte: ContexteClasseLive(
        sessionId: 's1',
        groupeId: 'g1',
        libelleGroupe: 'Classe Al-Fatiha',
        enseignant: const EnseignantDeClasse(
          nomAffichage: 'Youssouf',
          titre: TitreEnseignant.sayyid,
          photoCleOuUrl: 'https://exemple.invalid/photo.jpg',
        ),
        horloge: _horloge(),
      ),
      surcharges: <Override>[
        ...surchargesClasse(
          moteur: moteur,
          video: video,
          preVol: FauxPreVolClasse(),
          presence: FauxPresenceClasse(),
        ),
        pauseSeanceProvider(
          's1',
        ).overrideWith((Ref _) async => _programmee(peutPiloter: peutPiloter)),
        horlogeChronoProvider.overrideWithValue(
          () => _t0.add(const Duration(minutes: 15)),
        ),
      ],
      ecran: LargeurEcran.desktop,
    );
  }

  testWidgets('l\'enseignant avec la capacite : la commande existe', (
    WidgetTester tester,
  ) async {
    await monter(tester, role: 'teacher', peutPiloter: true);
    expect(_actionsDeLaPage(tester).onPause, isNotNull);
    expect(find.byKey(ChronoSalle.clePause), findsOneWidget);
    expect(find.byKey(ChronoSalle.cleCommandePause), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('l\'enseignant sans la capacite : aucune commande', (
    WidgetTester tester,
  ) async {
    await monter(tester, role: 'teacher', peutPiloter: false);
    // La ligne de la page : sans la capacite, aucune commande n'est fournie.
    expect(_actionsDeLaPage(tester).onPause, isNull);
    // La pause se dit (« Pause dans N min »), la commande n'existe pas.
    expect(find.byKey(ChronoSalle.clePause), findsOneWidget);
    expect(find.byKey(ChronoSalle.cleCommandePause), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('l\'eleve, jamais dote de la capacite : aucune commande', (
    WidgetTester tester,
  ) async {
    await monter(tester, role: 'student', peutPiloter: false);
    expect(_actionsDeLaPage(tester).onPause, isNull);
    expect(find.byKey(ChronoSalle.clePause), findsOneWidget);
    expect(find.byKey(ChronoSalle.cleCommandePause), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la capacite seule decide : le role n\'entre pas', (
    WidgetTester tester,
  ) async {
    // Le serveur ne donne pas cette capacite a un eleve ; ce cas prouve que
    // l'ecran ne la refuse pas lui-meme d'apres le role.
    await monter(tester, role: 'student', peutPiloter: true);
    expect(_actionsDeLaPage(tester).onPause, isNotNull);
    expect(find.byKey(ChronoSalle.cleCommandePause), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
