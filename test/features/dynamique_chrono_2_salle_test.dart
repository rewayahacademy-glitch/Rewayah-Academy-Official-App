// DYNAMIQUE-CHRONO-2 (directeur, 12/11/2026, retours sur la salle, points 5,
// 6, 14 et 15 ; `docs/current/salle/PLAN-RETOURS-2026-11-12.md`) : la
// Dynamique chrono dans la vraie page `/salle` (`SallePage`, faux moteur, page
// 42 du Coran presentee, horloge du chrono injectee, faux port de la pause).
//
// - enseignant 390 et 1440 : la pause proposee (Oui plein, Non lien, un seul
//   bouton plein), Oui demarre, l'alerte de reprise avec l'heure ; serveur
//   ancien : rien ; la pause de priere annoncee ; les arrivees (+2) ;
// - eleve 390 : l'appel recu (alerte, sonnerie repetee, marque jusqu'au
//   toucher), la recitation d'un camarade, la pause relayee puis finie a
//   l'heure (sans message de fin) ; la barre depliee ne coupe pas la mention ;
// - arabe a 390, mouvement reduit.
//
// Avec CAPTURE_DIR, chaque etat est aussi capture (R3, captures de test, pas
// la preuve en production).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/gestes_salle.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/cadre_visage.dart';
import 'package:rewayah_academy/core/widgets/chrono_vivant.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/features/salle/synchro_salle.dart'
    show typeParoleSalle;
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/pilote_dynamique.dart'
    show heureDeLaBarre;
import 'package:rewayah_academy/features/salle_seance/relais_salle.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_enseignant.dart'
    show CapsuleVideoTelephone;
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart'
    show VignetteAimantee;

import '../capture/outil_capture.dart';
import '../support/garde_interface.dart';
import '../support/harnais.dart' show FauxMoteurSalle;
import '../support/salle_chrono.dart';

/// L'horloge du serveur, que le test avance.
class _Horloge {
  _Horloge(this.maintenant);
  DateTime maintenant;
  DateTime call() => maintenant;
}

/// Le port de la pause : il compte les appels et rend l'etat qu'on lui donne.
class _Port implements PortPauseSeance {
  _Port(this.etatCourant);
  PauseSeance etatCourant;
  final List<String> appels = <String>[];
  PauseSeance Function(PauseSeance)? apresDemarrer;

  @override
  Future<PauseSeance> demarrer({
    required String seanceId,
    required String cleIdempotence,
  }) async {
    appels.add('demarrer');
    final PauseSeance Function(PauseSeance)? suite = apresDemarrer;
    if (suite != null) etatCourant = suite(etatCourant);
    return etatCourant;
  }

  @override
  Future<PauseSeance> terminer({
    required String seanceId,
    required String cleIdempotence,
  }) async {
    appels.add('terminer');
    return etatCourant;
  }

  @override
  Future<PauseSeance> refuser({
    required String seanceId,
    required String cleIdempotence,
  }) async {
    appels.add('refuser');
    return etatCourant;
  }

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

/// Les gestes de l'enseignant, sans reseau.
class _Gestes implements PortGestesSalle {
  @override
  Future<void> appliquer(
    String seanceId,
    String eleveId,
    GesteSalle geste,
  ) async {}

  @override
  Future<IssueRecitation> faireReciter(String seanceId, String eleveId) async =>
      IssueRecitation.ouverte;

  @override
  Future<void> terminerRecitation(String seanceId, {String? eleveId}) async {}

  @override
  Future<void> readmettre(String seanceId, String eleveId) async {}

  @override
  Future<List<EleveSorti>> sortis(String seanceId) async =>
      const <EleveSorti>[];
}

final Override _sansReseau = portGestesSalleProvider.overrideWithValue(
  _Gestes(),
);

final Finder _alerte = find.byKey(DynamiqueChrono.cleAlerte);

Finder _dansAlerte(String texte) =>
    find.descendant(of: _alerte, matching: find.text(texte));

/// Les chiffres de la barre repliee (chaque caractere roule a part).
String _chiffres(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(ChronoVivant.cleChiffres).first,
        matching: find.byType(Text),
      ),
    )
    .map((Text e) => e.data ?? '')
    .join();

/// Relecture du 13/11/2026 : tant que la barre est depliee, ni la capsule
/// video de l'enseignant ni sa vignette ne sont rendues ; la barre, la ligne
/// d'etat et ce qui reste visible ne se coupent pas.
void _verifierRienSousLaBarre(WidgetTester tester, String cas) {
  final Finder depliee = find.byKey(DynamiqueChrono.cleDepliee);
  expect(depliee, findsOneWidget, reason: cas);
  expect(find.byType(CapsuleVideoTelephone), findsNothing, reason: cas);
  expect(find.byKey(VignetteAimantee.cle), findsNothing, reason: cas);
  // Tout cadre de visage encore visible (vignette des rangees de l'eleve,
  // grille) : ni sous la barre, ni sur la ligne d'etat.
  final List<Finder> rects = <Finder>[
    depliee,
    find.byKey(LigneEtatSalle.cle),
    for (int k = 0; k < find.byType(CadreVisage).evaluate().length; k++)
      find.byType(CadreVisage).at(k),
  ];
  for (int i = 0; i < rects.length; i++) {
    for (int j = i + 1; j < rects.length; j++) {
      final Rect a = tester.getRect(rects[i]);
      final Rect b = tester.getRect(rects[j]);
      final Rect commun = a.intersect(b);
      expect(
        commun.width > toleranceGarde && commun.height > toleranceGarde,
        isFalse,
        reason: '$cas : ${rects[i]} ($a) coupe ${rects[j]} ($b)',
      );
    }
  }
}

Future<void> _capture(WidgetTester tester, String nom) async {
  if (dossierCapture == null) return;
  await capturer(tester, nom);
}

Future<void> _battre(WidgetTester tester, [int fois = 1]) async {
  for (int i = 0; i < fois; i++) {
    await tester.pump(AppMouvement.battementDynamique);
  }
  await tester.pump(const Duration(milliseconds: 600));
}

ParticipantSalle _personne(
  String id,
  String role, {
  bool local = false,
  String nom = '',
}) => ParticipantSalle(
  identite: id,
  nom: nom,
  role: role,
  estLocal: local,
  micro: false,
  camera: false,
  parle: false,
  qualite: QualiteLien.bonne,
);

PaquetDonnees _paquet(MessagePedagogique m) => PaquetDonnees(
  sujet: sujetProtocolePedagogique,
  charge: messageVersOctets(m),
  fiable: true,
  emetteurIdentite: 't1',
);

PaquetDonnees _relaisPause(PauseSeance p) => PaquetDonnees(
  sujet: sujetPauseSalle,
  charge: utf8.encode(jsonEncode(chargePause(p))),
  fiable: true,
  emetteurIdentite: 't1',
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final (Size taille, double densite) in <(Size, double)>[
    (const Size(390, 844), 2),
    (const Size(1440, 900), 1),
  ]) {
    final int l = taille.width.toInt();
    testWidgets(
      'enseignant $l : « Pause de 10 min ? », Oui plein et Non lien ; '
      'Oui demarre, puis « Pause de 10 min. Reprise a ... »',
      (WidgetTester tester) async {
        final _Horloge h = _Horloge(DateTime.now().toUtc());
        final _Port port =
            _Port(
                PauseSeance(
                  statut: StatutPause.programmee,
                  dureePrevueMinutes: 10,
                  debutPrevuUtc: h.maintenant.add(const Duration(minutes: 2)),
                  proposerAUtc: h.maintenant.add(const Duration(minutes: 2)),
                  peutPiloter: true,
                ),
              )
              ..apresDemarrer = (PauseSeance p) => PauseSeance(
                statut: StatutPause.enCours,
                dureePrevueMinutes: 10,
                debutPrevuUtc: p.debutPrevuUtc,
                debutUtc: h.maintenant,
                peutPiloter: true,
              );
        await monterSalleChrono(
          tester,
          role: 'teacher',
          taille: taille,
          densite: densite,
          horloge: h.call,
          portPause: port,
          pause: () => port.etatCourant,
          maintenant: h.maintenant,
        );
        expect(_alerte, findsNothing);
        h.maintenant = h.maintenant.add(const Duration(minutes: 2));
        await _battre(tester);
        expect(tester.takeException(), isNull);
        expect(_alerte, findsOneWidget);
        expect(_dansAlerte(t.salle.dynamique.oui), findsOneWidget);
        expect(_dansAlerte(t.salle.dynamique.non), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
        if (l == 390) {
          // Les commandes au toucher (la capsule viendrait avec elles) :
          // rien ne passe sous la barre depliee ni sur la ligne d'etat.
          await tester.tapAt(const Offset(195, 700));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          _verifierRienSousLaBarre(tester, 'enseignant 390, proposition');
        }
        await _capture(tester, 'enseignant_${l}_proposition_light');
        await tester.tap(_dansAlerte(t.salle.dynamique.oui));
        await tester.pump();
        await tester.pump();
        await _battre(tester);
        expect(port.appels, <String>['demarrer']);
        // L'heure exacte de reprise, dans l'heure de qui regarde.
        expect(
          find.descendant(
            of: _alerte,
            matching: find.textContaining(
              heureDeLaBarre(h.maintenant.add(const Duration(minutes: 10))),
            ),
          ),
          findsOneWidget,
        );
        // La barre prend la couleur de la pause, avec son mot, et ses
        // chiffres comptent jusqu'a la reprise (pas le reste de la seance).
        expect(find.text(t.salle.seance.chrono.pause), findsWidgets);
        expect(_chiffres(tester), '10:00');
        if (l == 1440) await _capture(tester, 'enseignant_1440_pause_light');
        // L'alerte se replie seule.
        await tester.pump(AppMouvement.alerteChrono);
        await _battre(tester);
        expect(_alerte, findsNothing);
        if (l == 390) {
          // Repliee, la capsule revient avec les commandes.
          await tester.tapAt(const Offset(195, 700));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.byType(CapsuleVideoTelephone), findsOneWidget);
        }
      },
    );
  }

  testWidgets('enseignant 390, serveur ancien (proposerA nul) : aucune '
      'proposition, le lien de la pause reste', (WidgetTester tester) async {
    final _Horloge h = _Horloge(DateTime.now().toUtc());
    final _Port port = _Port(
      PauseSeance(
        statut: StatutPause.programmee,
        dureePrevueMinutes: 10,
        debutPrevuUtc: h.maintenant,
        peutPiloter: true,
      ),
    );
    await monterSalleChrono(
      tester,
      role: 'teacher',
      taille: const Size(390, 844),
      horloge: h.call,
      portPause: port,
      pause: () => port.etatCourant,
      maintenant: h.maintenant,
    );
    h.maintenant = h.maintenant.add(const Duration(minutes: 20));
    await _battre(tester, 3);
    expect(_alerte, findsNothing);
    expect(port.appels, isEmpty);
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    testWidgets('enseignant 390 ${langue.languageCode} : la pause de priere '
        'annoncee d avance, puis « dans 3 min »', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      final _Horloge h = _Horloge(DateTime.now().toUtc());
      final DateTime heure = h.maintenant.add(const Duration(minutes: 10));
      final _Port port = _Port(
        PauseSeance(
          statut: StatutPause.programmee,
          dureePrevueMinutes: 10,
          debutPrevuUtc: heure,
          proposerAUtc: heure,
          peutPiloter: true,
          motif: MotifPause.priere,
        ),
      );
      await monterSalleChrono(
        tester,
        role: 'teacher',
        taille: const Size(390, 844),
        densite: 2,
        horloge: h.call,
        portPause: port,
        pause: () => port.etatCourant,
        maintenant: h.maintenant,
      );
      await tester.tap(find.byKey(DynamiqueChrono.cleDeplier).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining(t.salle.dynamique.priereNom), findsOneWidget);
      await _capture(
        tester,
        'enseignant_390_priere_${langue.languageCode == 'fr' ? 'light' : 'ar'}',
      );
      await tester.pump(AppMouvement.dynamiqueChronoDepliee);
      await tester.pump(const Duration(milliseconds: 600));
      h.maintenant = heure.subtract(const Duration(minutes: 3));
      await _battre(tester);
      expect(_alerte, findsOneWidget);
      expect(
        _dansAlerte(t.salle.dynamique.commencerMaintenant),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
      // A l'heure, elle demarre seule.
      h.maintenant = heure;
      await _battre(tester);
      expect(port.appels, contains('demarrer'));
    });
  }

  testWidgets('enseignant 390 : deux eleves arrivent, « +2 » ; ceux deja la '
      'ne comptent pas ; pas de son', (WidgetTester tester) async {
    int sons = 0;
    final FauxMoteurSalle moteur = await monterSalleChrono(
      tester,
      role: 'teacher',
      taille: const Size(390, 844),
      densite: 2,
      autres: <Override>[
        signalRappelProvider.overrideWithValue(() => sons++),
        _sansReseau,
      ],
      moderer: true,
    );
    expect(_alerte, findsNothing, reason: 'deja la a l entree');
    await _battre(tester, 6);
    moteur.publier(<ParticipantSalle>[
      _personne('t1', 'teacher', local: true),
      _personne('e1', 'student'),
      _personne('e2', 'student', nom: 'Aicha'),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      _dansAlerte(t.salle.dynamique.arriveePrenom(prenom: 'Aicha')),
      findsOneWidget,
    );
    moteur.publier(<ParticipantSalle>[
      _personne('t1', 'teacher', local: true),
      _personne('e1', 'student'),
      _personne('e2', 'student', nom: 'Aicha'),
      _personne('e3', 'student', nom: 'Omar'),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_dansAlerte(t.salle.dynamique.arrivees(n: 2)), findsOneWidget);
    expect(
      find.descendant(
        of: _alerte,
        matching: find.byKey(DynamiqueChrono.cleCompte),
      ),
      findsOneWidget,
    );
    await _capture(tester, 'enseignant_390_arrivees_light');
    expect(sons, 0);
    await tester.pump(AppMouvement.alerteArrivees);
    await _battre(tester);
    expect(_alerte, findsNothing);
  });

  testWidgets('eleve 390 : l appel recu dans la barre, sonnerie repetee '
      'arretee au toucher, marque jusqu au toucher de la barre', (
    WidgetTester tester,
  ) async {
    int sons = 0;
    final FauxMoteurSalle moteur = await monterSalleChrono(
      tester,
      role: 'student',
      taille: const Size(390, 844),
      densite: 2,
      autres: <Override>[signalRappelProvider.overrideWithValue(() => sons++)],
    );
    moteur.recevoirDonnees(
      _paquet(
        messageRappelDiscret(
          sessionId: 's1',
          emetteurProfilId: 't1',
          academyId: 'RA-26-e1',
          maintenantUtc: DateTime.now(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_dansAlerte(t.salle.gestes.appelRecuTitre), findsOneWidget);
    expect(sons, 1);
    await _capture(tester, 'eleve_390_appel_light');
    // Un toucher de l'ecran arrete la sonnerie.
    await tester.tapAt(const Offset(195, 600));
    await tester.pump(AppMouvement.sonnerieAppelEspace * 3);
    expect(sons, 1);
    await tester.pump(AppMouvement.alerteChrono);
    await _battre(tester);
    expect(_alerte, findsNothing);
    // La marque reste (lue), jusqu'au toucher de la barre.
    final SemanticsHandle s = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(t.salle.gestes.appelRecuTitre),
      findsOneWidget,
    );
    await tester.tap(find.byKey(DynamiqueChrono.cleDeplier).first);
    await tester.pump();
    await tester.pump(AppMouvement.dynamiqueChronoDepliee);
    await _battre(tester);
    expect(find.bySemanticsLabel(t.salle.gestes.appelRecuTitre), findsNothing);
    s.dispose();
  });

  testWidgets('eleve 390 : « Aicha recite », votre micro est ferme ; la '
      'marque reste ; « Un eleve recite » sans prenom', (
    WidgetTester tester,
  ) async {
    final FauxMoteurSalle moteur = await monterSalleChrono(
      tester,
      role: 'student',
      taille: const Size(390, 844),
      densite: 2,
    );
    void parole(String? profil, String prenom, int ms) =>
        moteur.recevoirDonnees(
          _paquet(
            MessagePedagogique(
              type: typeParoleSalle,
              sessionId: 's1',
              emetteurProfilId: 't1',
              charge: profil == null
                  ? const <String, dynamic>{}
                  : <String, dynamic>{'profil': profil, 'prenom': prenom},
              emisLeUtc: DateTime.utc(2026, 11, 12, 10, 0, 0, ms),
            ),
          ),
        );
    parole('e2', 'Aicha', 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      _dansAlerte(t.tc.classe.recitation.actif(prenom: 'Aicha')),
      findsOneWidget,
    );
    expect(_dansAlerte(t.salle.gestes.autreRecite), findsOneWidget);
    await _capture(tester, 'eleve_390_recitation_light');
    await tester.pump(AppMouvement.alerteChrono);
    await _battre(tester);
    final SemanticsHandle s = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(t.tc.classe.recitation.actif(prenom: 'Aicha')),
      findsOneWidget,
    );
    parole(null, '', 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_dansAlerte(t.salle.gestes.finRecitationTitre), findsOneWidget);
    parole('e3', '', 3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_dansAlerte(t.salle.dynamique.unEleveRecite), findsOneWidget);
    s.dispose();
  });

  testWidgets('eleve 390 : la pause relayee, « Reprise a ... » ; passee '
      'l heure, « La pause est finie » sans message de fin', (
    WidgetTester tester,
  ) async {
    final _Horloge h = _Horloge(DateTime.now().toUtc());
    final FauxMoteurSalle moteur = await monterSalleChrono(
      tester,
      role: 'student',
      taille: const Size(390, 844),
      densite: 2,
      horloge: h.call,
      maintenant: h.maintenant,
    );
    moteur.recevoirDonnees(
      _relaisPause(
        PauseSeance(
          statut: StatutPause.enCours,
          dureePrevueMinutes: 10,
          debutUtc: h.maintenant,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_alerte, findsOneWidget);
    // Les commandes au toucher (la vignette de l'enseignant vient avec elles).
    await tester.tapAt(const Offset(195, 700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    _verifierRienSousLaBarre(tester, 'eleve 390, pause');
    expect(find.text(t.salle.seance.chrono.pause), findsWidgets);
    final DateTime reprise = h.maintenant.add(const Duration(minutes: 10));
    await tester.pump(AppMouvement.alerteChrono);
    await _battre(tester);
    // Relecture du 13/11/2026 : « Pause 09:41 », le compte a rebours de la
    // pause ; le lecteur d'ecran dit la pause et l'heure de reprise.
    h.maintenant = h.maintenant.add(const Duration(seconds: 19));
    await _battre(tester, 2);
    expect(_chiffres(tester), '09:41');
    final SemanticsHandle s = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byKey(ChronoSalle.cleAnnonce)).label,
      t.salle.seance.pause.annonceEnCours(heure: heureDeLaBarre(reprise)),
    );
    s.dispose();
    // Depliee : l'heure exacte de reprise et le reste de la seance, en clair.
    await tester.tap(find.byKey(DynamiqueChrono.cleDeplier).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.text(t.salle.seance.pause.repriseA(heure: heureDeLaBarre(reprise))),
      findsOneWidget,
    );
    expect(find.byKey(ChronoSalle.cleResteSeance), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(ChronoSalle.cleResteSeance)).data,
      startsWith(t.salle.seance.chrono.reste),
    );
    await _capture(tester, 'eleve_390_pause_light');
    await tester.pump(AppMouvement.dynamiqueChronoDepliee);
    await _battre(tester);
    h.maintenant = reprise.add(const Duration(seconds: 1));
    await _battre(tester, 2);
    expect(_dansAlerte(t.salle.dynamique.pauseFinie), findsOneWidget);
    expect(find.text(t.salle.seance.chrono.pause), findsNothing);
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    testWidgets('eleve 390 ${langue.languageCode} : la barre depliee ne coupe '
        'pas la mention permanente ni le mot d etat', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      await monterSalleChrono(
        tester,
        role: 'student',
        taille: const Size(390, 844),
        densite: 2,
        etatEleve: EtatPresence.enRetard,
      );
      await tester.tap(find.byKey(DynamiqueChrono.cleDeplier).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      final Rect depliee = tester.getRect(
        find.byKey(DynamiqueChrono.cleDepliee),
      );
      for (final Finder f in <Finder>[
        find.byType(PermanentNotice),
        find.byKey(LigneEtatSalle.cleMot),
      ]) {
        expect(f, findsOneWidget);
        final Rect r = tester.getRect(f);
        final Rect commun = depliee.intersect(r);
        expect(
          commun.width > toleranceGarde && commun.height > toleranceGarde,
          isFalse,
          reason: 'la barre depliee $depliee coupe $f ($r)',
        );
        expect(f.hitTestable(), findsOneWidget, reason: '$f cache');
      }
      await _capture(
        tester,
        'eleve_390_depliee_mention_${langue.languageCode == 'fr' ? 'light' : 'ar'}',
      );
    });
  }

  testWidgets('mouvement reduit : l arrivee se lit d emblee, sans roulement', (
    WidgetTester tester,
  ) async {
    final FauxMoteurSalle moteur = await monterSalleChrono(
      tester,
      role: 'teacher',
      taille: const Size(390, 844),
      mouvementReduit: true,
      moderer: true,
      autres: <Override>[_sansReseau],
    );
    await _battre(tester, 6);
    moteur.publier(<ParticipantSalle>[
      _personne('t1', 'teacher', local: true),
      _personne('e1', 'student'),
      _personne('e2', 'student'),
      _personne('e3', 'student'),
    ]);
    await tester.pump();
    await tester.pump();
    expect(_dansAlerte(t.salle.dynamique.arrivees(n: 2)), findsOneWidget);
    expect(
      find.descendant(of: _alerte, matching: find.text('2')),
      findsOneWidget,
    );
  });

  testWidgets('sombre : eleve 390, appel recu', (WidgetTester tester) async {
    final FauxMoteurSalle moteur = await monterSalleChrono(
      tester,
      role: 'student',
      taille: const Size(390, 844),
      densite: 2,
      theme: ThemeMode.dark,
      autres: <Override>[signalRappelProvider.overrideWithValue(() {})],
    );
    moteur.recevoirDonnees(
      _paquet(
        messageRappelDiscret(
          sessionId: 's1',
          emetteurProfilId: 't1',
          academyId: 'RA-26-e1',
          maintenantUtc: DateTime.now(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_alerte, findsOneWidget);
    await _capture(tester, 'eleve_390_appel_dark');
  });
}
