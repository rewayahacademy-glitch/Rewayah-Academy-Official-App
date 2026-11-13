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
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/chrono_vivant.dart';
import 'package:rewayah_academy/features/salle/seance_vivante.dart';
import 'package:rewayah_academy/features/salle/synchro_salle.dart'
    show typeParoleSalle;
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

/// Le controleur du dernier montage.
late ControleurSessionPersistante _controleur;

ParticipantSalle _personne(String id, String role, {bool local = false}) =>
    ParticipantSalle(
      identite: id,
      nom: id == 'e2' ? 'Aicha' : id,
      role: role,
      estLocal: local,
      micro: false,
      camera: false,
      parle: false,
      qualite: QualiteLien.bonne,
    );

Future<FauxMoteurSalle> _monter(
  WidgetTester tester, {
  required DateTime Function() horloge,
  required DateTime t0,
  void Function()? signal,
  ThemeMode mode = ThemeMode.light,
  bool enseignant = false,
  PortPauseSeance? port,
  List<Override> autres = const <Override>[],
  double largeur = 390,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, Size(largeur, 844), 2);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  // SYNCHRO-SESSION : le controleur de l application tient la seance de
  // l appel (SeanceVivante), comme en production ; la salle reduite la lit.
  final ControleurSessionPersistante controleur = ControleurSessionPersistante(
    moteur,
    FauxServiceVideo(),
    fabriqueCompagnon:
        ({
          required SessionEnCours cours,
          required AccesSalle acces,
          required VideoSessionProvider moteur,
        }) => SeanceVivante(
          moteur: moteur,
          acces: acces,
          sessionId: cours.sessionId,
          profilLocalId: enseignant ? 't1' : 'e1',
          tutoie: cours.interfaceGuidee,
          signal: signal ?? () {},
          maintenant: () => horloge().toUtc(),
          portPause: port == null ? null : () => port,
        ),
  );
  _controleur = controleur;
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
        // Libere avec l arbre : la seance de l appel (sa minuterie) ne
        // survit pas au test.
        controleurSessionProvider.overrideWith((Ref ref) {
          ref.onDispose(controleur.liberer);
          return controleur;
        }),
        if (port != null) portPauseSeanceProvider.overrideWithValue(port),
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
      echelleTexte: echelle,
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

PaquetDonnees _paroleDe(String? profil, String prenom, int ms) => PaquetDonnees(
  sujet: sujetProtocolePedagogique,
  charge: messageVersOctets(
    MessagePedagogique(
      type: typeParoleSalle,
      sessionId: 's1',
      emetteurProfilId: 't1',
      charge: profil == null
          ? const <String, dynamic>{}
          : <String, dynamic>{'profil': profil, 'prenom': prenom},
      emisLeUtc: DateTime.utc(2026, 11, 13, 10, 0, 0, ms),
    ),
  ),
  fiable: true,
  emetteurIdentite: 't1',
);

final Finder _alerteIle = find.byKey(BarreSeanceEnDirect.cleAlerte);

Finder _dansIle(String texte) =>
    find.descendant(of: _alerteIle, matching: find.text(texte));

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

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
    // SYNCHRO-SESSION, ligne 3.3 : la salle reduite verifie, comme la salle,
    // que la pause vient de qui conduit (identite et role du jeton signe).
    moteur.publier(<ParticipantSalle>[
      _personne('t1', 'teacher'),
      _personne('e1', 'student', local: true),
    ]);
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
      port: port,
      autres: <Override>[
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

  // SYNCHRO-SESSION (13/11/2026, point 4 du plan) : la recitation arrive dans
  // la salle reduite, par la seance de l appel, comme dans la salle.
  for (final (String nom, ThemeMode mode, AppLocale langue)
      in <(String, ThemeMode, AppLocale)>[
        ('light', ThemeMode.light, AppLocale.fr),
        ('dark', ThemeMode.dark, AppLocale.fr),
        ('arabe', ThemeMode.light, AppLocale.ar),
      ]) {
    testWidgets('salle reduite, eleve ($nom) : « Aicha recite » dans l ile, '
        'puis la marque ; « Un eleve recite » sans prenom', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      final DateTime maintenant = DateTime.now().toUtc();
      final FauxMoteurSalle moteur = await _monter(
        tester,
        horloge: () => maintenant,
        t0: maintenant.subtract(const Duration(minutes: 52)),
        mode: mode,
      );
      moteur
        ..publier(<ParticipantSalle>[
          _personne('t1', 'teacher'),
          _personne('e1', 'student', local: true),
          _personne('e2', 'student'),
        ])
        ..recevoirDonnees(_paroleDe('e2', 'Aicha', 1));
      await _attendre(tester);
      final String titre = t.tc.classe.recitation.actif(prenom: 'Aicha');
      expect(_dansIle(titre), findsOneWidget);
      expect(_dansIle(t.salle.gestes.autreRecite), findsOneWidget);
      // Une seule seance pour la salle et la salle reduite : l alerte est
      // celle de la Dynamique chrono de l appel.
      expect(seanceTenue(_controleur, 's1')!.dynamique.alerte?.titre, titre);
      await stabiliser(tester);
      await _capture(tester, 'salle_reduite_390_recitation_$nom');
      await tester.pump(AppMouvement.alerteChrono);
      await _attendre(tester);
      expect(_alerteIle, findsNothing);
      final SemanticsHandle s = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp(RegExp.escape(titre))), findsWidgets);
      s.dispose();
      moteur.recevoirDonnees(_paroleDe(null, '', 2));
      await _attendre(tester);
      expect(_dansIle(t.salle.gestes.finRecitationTitre), findsOneWidget);
      moteur.recevoirDonnees(_paroleDe('e3', '', 3));
      await _attendre(tester);
      expect(_dansIle(t.salle.dynamique.unEleveRecite), findsOneWidget);
    });
  }

  // SYNCHRO-SESSION (point 4 du plan) : chez qui conduit la seance, les
  // arrivees (+1, +2) arrivent aussi dans la salle reduite.
  testWidgets('salle reduite, enseignant : « Aicha est arrivee », ceux deja '
      'la ne comptent pas', (WidgetTester tester) async {
    final DateTime maintenant = DateTime.now().toUtc();
    final FauxMoteurSalle moteur = await _monter(
      tester,
      horloge: () => maintenant,
      t0: maintenant.subtract(const Duration(minutes: 40)),
      enseignant: true,
    );
    moteur.publier(<ParticipantSalle>[
      _personne('t1', 'teacher', local: true),
      _personne('e1', 'student'),
    ]);
    await _attendre(tester);
    expect(_alerteIle, findsNothing, reason: 'deja la a l entree');
    for (int i = 0; i < 6; i++) {
      await tester.pump(AppMouvement.battementDynamique);
    }
    moteur.publier(<ParticipantSalle>[
      _personne('t1', 'teacher', local: true),
      _personne('e1', 'student'),
      _personne('e2', 'student'),
    ]);
    await _attendre(tester);
    expect(
      _dansIle(t.salle.dynamique.arriveePrenom(prenom: 'Aicha')),
      findsOneWidget,
    );
    await stabiliser(tester);
    await _capture(tester, 'salle_reduite_390_arrivee_light');
    await tester.pump(AppMouvement.alerteArrivees);
    await _attendre(tester);
    expect(_alerteIle, findsNothing);
  });

  // SYNCHRO-SESSION (retour du pilote, 13/11/2026) : a 360 et 390, texte x1,
  // en francais et en arabe, avec zero, une ou deux marques, le micro et le
  // chevron restent sur la rangee du chrono, au bord de fin ; la pastille
  // cede (son point) quand la place manque ; l'alerte se pose dessous sans
  // deplacer les boutons.
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    for (final double largeur in <double>[360, 390]) {
      for (final int marques in <int>[0, 1, 2]) {
        final String cas =
            '${langue.languageCode} ${largeur.toInt()}, $marques marque(s)';
        testWidgets('salle reduite, $cas : une seule rangee, rien ne deborde '
            'ni ne se chevauche', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          final DateTime maintenant = DateTime.now().toUtc();
          final FauxMoteurSalle moteur = await _monter(
            tester,
            horloge: () => maintenant,
            t0: maintenant.subtract(const Duration(minutes: 52)),
            largeur: largeur,
          );
          moteur.publier(<ParticipantSalle>[
            _personne('t1', 'teacher'),
            _personne('e1', 'student', local: true),
            _personne('e2', 'student'),
          ]);
          final Finder micro = find.byKey(BarreSeanceEnDirect.cleMicro);
          final Finder chevron = find.byKey(BarreSeanceEnDirect.cleChevron);
          final Finder chrono = find.byKey(BarreSeanceEnDirect.cleChrono);
          final Finder ile = find.byKey(BarreSeanceEnDirect.cleIle);
          Rect? avantAlerte;
          if (marques >= 1) {
            moteur.recevoirDonnees(_paroleDe('e2', 'Aicha', 1));
            await _attendre(tester);
            // L'alerte depliee (« Aicha recite », deux lignes) se pose
            // dessous, sans deplacer les boutons.
            expect(_alerteIle, findsOneWidget, reason: cas);
            avantAlerte = tester.getRect(chevron);
            expect(
              tester.getRect(_alerteIle).top,
              greaterThanOrEqualTo(avantAlerte.bottom - 0.5),
              reason: cas,
            );
            await tester.pump(AppMouvement.alerteChrono);
            await _attendre(tester);
          }
          if (marques >= 2) {
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
            await tester.pump(AppMouvement.alerteChrono);
            await _attendre(tester);
            await tester.pump(AppMouvement.sonnerieAppelEspace * 3);
          }
          await stabiliser(tester);
          expect(tester.takeException(), isNull, reason: cas);
          expect(_alerteIle, findsNothing, reason: cas);
          final Rect rChrono = tester.getRect(chrono);
          final Rect rMicro = tester.getRect(micro);
          final Rect rChevron = tester.getRect(chevron);
          // Une seule rangee : les boutons sont centres sur le chrono.
          for (final Rect b in <Rect>[rMicro, rChevron]) {
            expect(
              (b.center.dy - rChrono.center.dy).abs(),
              lessThan(1),
              reason: '$cas : $b hors de la rangee du chrono $rChrono',
            );
          }
          if (avantAlerte != null) {
            expect(
              rChevron.top,
              moreOrLessEquals(avantAlerte.top),
              reason: cas,
            );
          }
          // Au bord de fin : le chevron apres le micro, apres le chrono.
          if (langue == AppLocale.ar) {
            expect(rChevron.right, lessThanOrEqualTo(rMicro.left + 0.5));
            expect(rMicro.right, lessThanOrEqualTo(rChrono.left + 0.5));
          } else {
            expect(rChevron.left, greaterThanOrEqualTo(rMicro.right - 0.5));
            expect(rMicro.left, greaterThanOrEqualTo(rChrono.right - 0.5));
          }
          // Rien ne deborde de l'ile ni de l'ecran ; cibles de 48.
          final Rect rIle = tester.getRect(ile);
          for (final Rect r in <Rect>[rChrono, rMicro, rChevron]) {
            expect(
              rIle.inflate(0.5).contains(r.topLeft) &&
                  rIle.inflate(0.5).contains(r.bottomRight),
              isTrue,
              reason: '$cas : $r hors de l ile $rIle',
            );
          }
          // Le chevron touche presque le bord de fin de l'ile (sa marge de
          // fin, 4, et le filet).
          final double auBord = langue == AppLocale.ar
              ? rChevron.left - rIle.left
              : rIle.right - rChevron.right;
          expect(auBord, lessThanOrEqualTo(8), reason: '$cas : $auBord');
          expect(rIle.left, greaterThanOrEqualTo(0), reason: cas);
          expect(rIle.right, lessThanOrEqualTo(largeur), reason: cas);
          expect(rMicro.width, greaterThanOrEqualTo(48), reason: cas);
          expect(rChevron.width, greaterThanOrEqualTo(48), reason: cas);
          // La pastille : son mot, ou son point quand la place manque ; le
          // mot reste lu.
          final SemanticsHandle s = tester.ensureSemantics();
          // Le toucher qui ramene a la salle se lit « Retourner dans la
          // salle », puis le mot de la pastille.
          expect(
            tester
                .getSemantics(find.byKey(BarreSeanceEnDirect.cleRetour))
                .label,
            contains(t.etat.enDirect),
            reason: cas,
          );
          s.dispose();
        });
      }
    }
  }

  testWidgets('salle reduite, 320 texte x2 : le bloc micro et chevron passe '
      'entier a la ligne, jamais un bouton seul', (WidgetTester tester) async {
    final DateTime maintenant = DateTime.now().toUtc();
    final FauxMoteurSalle moteur = await _monter(
      tester,
      horloge: () => maintenant,
      t0: maintenant.subtract(const Duration(minutes: 52)),
      largeur: 320,
      echelle: 2,
    );
    moteur.recevoirDonnees(_paroleDe('e2', 'Aicha', 1));
    await _attendre(tester);
    await tester.pump(AppMouvement.alerteChrono);
    await _attendre(tester);
    expect(tester.takeException(), isNull);
    final Rect rMicro = tester.getRect(
      find.byKey(BarreSeanceEnDirect.cleMicro),
    );
    final Rect rChevron = tester.getRect(
      find.byKey(BarreSeanceEnDirect.cleChevron),
    );
    expect((rMicro.center.dy - rChevron.center.dy).abs(), lessThan(1));
  });
}
