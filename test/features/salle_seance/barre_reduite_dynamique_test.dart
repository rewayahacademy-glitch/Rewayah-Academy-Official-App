// DYNAMIQUE-CHRONO-2, point 15 (directeur, 12/11/2026 : « la barre marche
// bien quand la salle est reduite ; il faut qu'elle soit exploitee au max ») :
// la salle reduite (`BarreSeanceEnDirect`) recoit l'appel (alerte, sonnerie
// repetee, marque) et la pause relayee (debut avec l'heure, couleur, fin a
// l'heure), par les paquets de la visio, sans la page de la salle. Son
// toucher garde son geste : retourner dans la salle.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_classe/port_session_persistante.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/chrono_vivant.dart';
import 'package:rewayah_academy/features/salle_seance/barre_seance_en_direct.dart';
import 'package:rewayah_academy/features/salle_seance/bornes_salle.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/relais_salle.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

AccesSalle _acces({bool enseignant = false}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: enseignant ? 'teacher' : 'student',
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: enseignant,
    peutRecevoir: true,
    invisible: false,
    peutModerer: enseignant,
  ),
  expireLe: DateTime.utc(2030),
);

Future<FauxMoteurSalle> _monter(
  WidgetTester tester, {
  required DateTime Function() horloge,
  required DateTime t0,
  void Function()? signal,
  ThemeMode mode = ThemeMode.light,
  bool enseignant = false,
  List<Override> autres = const <Override>[],
}) async {
  fixerVueCapture(tester, const Size(390, 844), 2);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  final ControleurSessionPersistante controleur = ControleurSessionPersistante(
    moteur,
    FauxServiceVideo(),
  );
  addTearDown(controleur.liberer);
  controleur.adopter(
    cours: const SessionEnCours(
      sessionId: 's1',
      groupeId: 'g1',
      libelleGroupe: 'Les sourates courtes, mardi 18 h',
    ),
    acces: _acces(enseignant: enseignant),
  );
  // Le faux moteur ne publie qu'avec un acces courant (comme le vrai, entre
  // dans la salle).
  if (enseignant) moteur.entrees.add(_acces(enseignant: true));
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.eleve,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.eleve,
        builder: (BuildContext _, GoRouterState _) => const SizedBox.shrink(),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    hoteCapture(
      BarreSeanceEnDirect(
        routeur: routeur,
        child: Builder(
          builder: (BuildContext c) => ColoredBox(
            color: AppPalette.of(c).surfaceCanvas.background,
            child: const SizedBox.expand(),
          ),
        ),
      ),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(
            SessionState(
              resolue: true,
              role: enseignant ? AppRole.teacher : AppRole.student,
              profileId: enseignant ? 't1' : 'e1',
              accountStatus: AccountStatus.active,
              lectureProfil: LectureProfil.presente,
            ),
          ),
        ),
        signalChronoProvider.overrideWithValue(() {}),
        signalRappelProvider.overrideWithValue(signal ?? () {}),
        controleurSessionProvider.overrideWithValue(controleur),
        moteurSalleProvider.overrideWithValue(moteur),
        horlogeChronoProvider.overrideWithValue(horloge),
        bornesSalleProvider.overrideWith(
          (Ref _, CleBornesSalle _) => BornesChrono(
            debutUtc: t0,
            finPrevueUtc: t0.add(const Duration(minutes: 90)),
          ),
        ),
        ...autres,
      ],
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
  return moteur;
}

Future<void> _capture(WidgetTester tester, String nom) async {
  if (dossierCapture == null) return;
  await capturer(tester, nom);
}

Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// HARMONIE-SALLE : le port de la pause de l'enseignant, sans reseau.
class _PortPause implements PortPauseSeance {
  _PortPause(this.etatCourant);
  PauseSeance etatCourant;
  PauseSeance Function(PauseSeance)? apresDemarrer;

  @override
  Future<PauseSeance> demarrer({
    required String seanceId,
    required String cleIdempotence,
  }) async {
    final PauseSeance Function(PauseSeance)? suite = apresDemarrer;
    if (suite != null) etatCourant = suite(etatCourant);
    return etatCourant;
  }

  @override
  Future<PauseSeance> terminer({
    required String seanceId,
    required String cleIdempotence,
  }) async => etatCourant;

  @override
  Future<PauseSeance> refuser({
    required String seanceId,
    required String cleIdempotence,
  }) async => etatCourant;

  @override
  Future<PauseSeance> etat(String seanceId) async => etatCourant;

  @override
  Future<ReglagePause> reglage(String groupeId) => throw UnimplementedError();

  @override
  Future<ReglagePause> enregistrerReglage({
    required String groupeId,
    required bool actif,
    required int apresMinutes,
    required int dureeMinutes,
    required String versionAttendue,
    required String cleIdempotence,
  }) => throw UnimplementedError();
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('salle reduite : l appel recu, sonnerie repetee, alerte puis '
      'marque ; le toucher ramene a la salle', (WidgetTester tester) async {
    DateTime maintenant = DateTime.now().toUtc();
    int sons = 0;
    final FauxMoteurSalle moteur = await _monter(
      tester,
      horloge: () => maintenant,
      t0: maintenant.subtract(const Duration(minutes: 52)),
      signal: () => sons++,
    );
    moteur.recevoirDonnees(
      PaquetDonnees(
        sujet: sujetProtocolePedagogique,
        charge: messageVersOctets(
          messageRappelDiscret(
            sessionId: 's1',
            emetteurProfilId: 't1',
            academyId: 'RA-26-e1',
            maintenantUtc: DateTime.now(),
          ),
        ),
        fiable: true,
        emetteurIdentite: 't1',
      ),
    );
    await _attendre(tester);
    expect(find.byKey(BarreSeanceEnDirect.cleAlerte), findsOneWidget);
    expect(find.text(t.salle.gestes.appelRecuTitre), findsOneWidget);
    expect(sons, 1);
    await tester.pump(AppMouvement.sonnerieAppelEspace);
    expect(sons, 2);
    await tester.pump(AppMouvement.alerteChrono);
    await _attendre(tester);
    expect(find.byKey(BarreSeanceEnDirect.cleAlerte), findsNothing);
    expect(sons, SonnerieAppel.repetitions);
    final SemanticsHandle s = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(t.salle.gestes.appelRecuTitre),
      findsOneWidget,
    );
    s.dispose();
    maintenant = maintenant.add(const Duration(seconds: 1));
  });

  testWidgets('salle reduite : la pause relayee, « Reprise a ... », couleur '
      'de pause ; passee l heure, « La pause est finie »', (
    WidgetTester tester,
  ) async {
    DateTime maintenant = DateTime.now().toUtc();
    final FauxMoteurSalle moteur = await _monter(
      tester,
      horloge: () => maintenant,
      t0: maintenant.subtract(const Duration(minutes: 52)),
    );
    moteur.recevoirDonnees(
      PaquetDonnees(
        sujet: sujetPauseSalle,
        charge: utf8.encode(
          jsonEncode(
            chargePause(
              PauseSeance(
                statut: StatutPause.enCours,
                dureePrevueMinutes: 10,
                debutUtc: maintenant,
              ),
            ),
          ),
        ),
        fiable: true,
        emetteurIdentite: 't1',
      ),
    );
    await _attendre(tester);
    expect(find.byKey(BarreSeanceEnDirect.cleAlerte), findsOneWidget);
    expect(find.text(t.salle.seance.chrono.pause), findsOneWidget);
    // Relecture du 13/11/2026 : les chiffres comptent jusqu'a la reprise.
    String chiffres() => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(ChronoVivant.cleChiffres).first,
            matching: find.byType(Text),
          ),
        )
        .map((Text e) => e.data ?? '')
        .join();
    expect(chiffres(), '10:00');
    await stabiliser(tester);
    await _capture(tester, 'salle_reduite_390_pause_light');
    await tester.pump(AppMouvement.alerteChrono);
    await _attendre(tester);
    maintenant = maintenant.add(const Duration(minutes: 10, seconds: 1));
    await tester.pump(AppMouvement.battementDynamique);
    await tester.pump(AppMouvement.battementDynamique);
    await _attendre(tester);
    expect(find.text(t.salle.dynamique.pauseFinie), findsOneWidget);
    expect(find.text(t.salle.seance.chrono.pause), findsNothing);
  });
  // HARMONIE-SALLE (13/11/2026) : une pause demarree depuis la salle reduite
  // (l'enseignant hors de la page de la salle) est relayee a la classe sur le
  // moment, sur le canal fiable, avec l'etat rendu par le serveur.
  testWidgets('salle reduite, enseignant : « Oui » a la pause proposee la '
      'demarre et la relaie aux eleves', (WidgetTester tester) async {
    DateTime maintenant = DateTime.now().toUtc();
    final _PortPause port =
        _PortPause(
            PauseSeance(
              statut: StatutPause.programmee,
              dureePrevueMinutes: 10,
              debutPrevuUtc: maintenant.add(const Duration(minutes: 2)),
              proposerAUtc: maintenant.add(const Duration(minutes: 2)),
              peutPiloter: true,
            ),
          )
          ..apresDemarrer = (PauseSeance p) => PauseSeance(
            statut: StatutPause.enCours,
            dureePrevueMinutes: 10,
            debutPrevuUtc: p.debutPrevuUtc,
            debutUtc: maintenant,
            peutPiloter: true,
          );
    final FauxMoteurSalle moteur = await _monter(
      tester,
      horloge: () => maintenant,
      t0: maintenant.subtract(const Duration(minutes: 40)),
      enseignant: true,
      autres: <Override>[
        portPauseSeanceProvider.overrideWithValue(port),
        pauseSeanceProvider.overrideWith(
          (Ref _, String _) async => port.etatCourant,
        ),
      ],
    );
    expect(moteur.donneesPubliees, isEmpty);
    maintenant = maintenant.add(const Duration(minutes: 2));
    await tester.pump(AppMouvement.battementDynamique);
    await _attendre(tester);
    expect(find.text(t.salle.dynamique.oui), findsOneWidget);
    await tester.tap(find.text(t.salle.dynamique.oui));
    await _attendre(tester);
    final List<PaquetDonnees> pauses = moteur.donneesPubliees
        .where((PaquetDonnees p) => p.sujet == sujetPauseSalle)
        .toList();
    expect(pauses, hasLength(1));
    expect(pauses.single.fiable, isTrue);
    expect(
      pauseDepuisCharge(pauses.single.charge)?.statut,
      StatutPause.enCours,
    );
  });
}
