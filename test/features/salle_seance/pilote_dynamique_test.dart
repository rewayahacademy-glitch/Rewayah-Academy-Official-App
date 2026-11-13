// DYNAMIQUE-CHRONO-2 (directeur, 12/11/2026, points 5, 6 et 14 ;
// `docs/current/salle/PLAN-RETOURS-2026-11-12.md`) : la logique de la
// Dynamique chrono, sans widget, horloge injectee.
//
// - file : une alerte a la fois, repli seul, marque laissee, meme famille qui
//   remplace, toucher qui replie ou rouvre ;
// - arrivees : rien pour ceux deja la, +1 puis +2 dans la meme fenetre ;
// - pause proposee : Oui, Non, sans reponse (marque puis rappel, rien envoye),
//   plus de proposition, serveur ancien, echec qui laisse la proposition,
//   pause de priere (avance, decalage, depart seul), fin automatique (une
//   fois, reessai apres un echec), debut et fin dits a tous, reprise passee.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle_seance/marque_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/pilote_dynamique.dart';

class _Commandes implements CommandesPause {
  final List<String> appels = <String>[];
  bool echec = false;

  Future<void> _faire(String nom) {
    appels.add(nom);
    return echec
        ? Future<void>.error(StateError('non confirme'))
        : Future<void>.value();
  }

  @override
  Future<void> demarrer() => _faire('demarrer');

  @override
  Future<void> terminer() => _faire('terminer');

  @override
  Future<void> refuser() => _faire('refuser');
}

ParticipantSalle _p(
  String id, {
  String role = 'student',
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

final DateTime _t = DateTime.utc(2026, 11, 12, 18);

PauseSeance _programmee({
  DateTime? proposer,
  MotifPause motif = MotifPause.ordinaire,
  int refus = 0,
}) => PauseSeance(
  statut: StatutPause.programmee,
  dureePrevueMinutes: 10,
  debutPrevuUtc: _t,
  proposerAUtc: proposer,
  peutPiloter: true,
  motif: motif,
  refusNombre: refus,
);

PauseSeance _enCours(
  DateTime debut, {
  MotifPause motif = MotifPause.ordinaire,
}) => PauseSeance(
  statut: StatutPause.enCours,
  dureePrevueMinutes: 10,
  debutPrevuUtc: _t,
  debutUtc: debut,
  peutPiloter: true,
  motif: motif,
);

Future<void> _attendre() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('file des alertes', () {
    test('une a la fois ; repli seul ; marque laissee ; puis la suivante', () {
      final PiloteDynamique p = PiloteDynamique();
      const MarqueChrono m = MarqueChrono.evenement(libelle: 'trace');
      p
        ..annoncer(AlerteChrono(id: 'a', titre: 'A', trace: m))
        ..annoncer(AlerteChrono(id: 'b', titre: 'B'));
      expect(p.alerte?.id, 'a');
      p.avancer(AppMouvement.alerteChrono);
      expect(p.alerte?.id, 'b');
      expect(p.marques, <MarqueChrono>[m]);
      p.avancer(AppMouvement.alerteChrono);
      expect(p.alerte, isNull);
      // Une alerte deja montree ne se rejoue pas tant qu'elle est la.
      p
        ..annoncer(AlerteChrono(id: 'c', titre: 'C'))
        ..annoncer(AlerteChrono(id: 'c', titre: 'C'));
      p.avancer(AppMouvement.alerteChrono);
      expect(p.alerte, isNull);
      p.dispose();
    });

    test('une alerte de la meme famille remplace celle montree', () {
      final PiloteDynamique p = PiloteDynamique()
        ..annoncer(AlerteChrono(id: 'r1', titre: 'Aicha recite', groupe: 'g'))
        ..annoncer(AlerteChrono(id: 'x', titre: 'X'))
        ..annoncer(AlerteChrono(id: 'r2', titre: 'Fin', groupe: 'g'));
      expect(p.alerte?.titre, 'Fin');
      p.dispose();
    });

    test('marque datee qui s efface ; toucher : replie, puis rouvre', () {
      final PiloteDynamique p = PiloteDynamique();
      int touchers = 0;
      p
        ..auToucher(() => touchers++)
        ..marquer(
          'm',
          const MarqueChrono.evenement(libelle: 'm'),
          duree: const Duration(seconds: 3),
        );
      expect(p.marques, hasLength(1));
      p.avancer(const Duration(seconds: 3));
      expect(p.marques, isEmpty);
      p.annoncer(
        AlerteChrono(
          id: 'prop',
          titre: 'Pause ?',
          trace: const MarqueChrono.evenement(libelle: 'Pause proposee'),
          rouvrable: true,
        ),
      );
      expect(p.toucher(), isTrue, reason: 'le toucher replie l alerte');
      expect(p.alerte, isNull);
      expect(p.marques.single.libelle, 'Pause proposee');
      expect(p.toucher(), isTrue, reason: 'le toucher rouvre la proposition');
      expect(p.alerte?.titre, 'Pause ?');
      expect(p.marques, isEmpty);
      expect(touchers, 2);
      expect(PiloteDynamique().toucher(), isFalse);
      p.dispose();
    });
  });

  group('arrivees', () {
    test('rien pour ceux deja la ; +1 avec le prenom, puis +2 sans', () {
      final SuiviArrivees suivi = SuiviArrivees();
      final PiloteDynamique p = PiloteDynamique();
      // Avant de se voir soi-meme : rien n'est fixe.
      expect(suivi.observer(<ParticipantSalle>[_p('e0')]), isEmpty);
      expect(
        suivi.observer(<ParticipantSalle>[
          _p('t1', role: 'teacher', local: true),
          _p('e0'),
        ]),
        isEmpty,
      );
      List<String> noms(List<ParticipantSalle> l) => <String>[
        for (final ParticipantSalle x in suivi.observer(
          l,
          ecoule: AppMouvement.calmeEntree,
        ))
          x.nom,
      ];
      annoncerArrivees(
        p,
        noms(<ParticipantSalle>[
          _p('t1', role: 'teacher', local: true),
          _p('e0'),
          _p('e1', nom: 'Yasmine'),
        ]),
      );
      expect(p.alerte?.compte, 1);
      expect(
        p.alerte?.titre,
        t.salle.dynamique.arriveePrenom(prenom: 'Yasmine'),
      );
      p.avancer(const Duration(seconds: 2));
      annoncerArrivees(
        p,
        noms(<ParticipantSalle>[
          _p('t1', role: 'teacher', local: true),
          _p('e0'),
          _p('e1', nom: 'Yasmine'),
          _p('e2', nom: 'Aicha'),
        ]),
      );
      expect(p.alerte?.compte, 2);
      expect(p.alerte?.titre, t.salle.dynamique.arrivees(n: 2));
      // Le temps repart : 2 s plus tard, toujours la.
      p.avancer(const Duration(seconds: 2));
      expect(p.alerte?.compte, 2);
      p.avancer(AppMouvement.alerteArrivees);
      expect(p.alerte, isNull);
      expect(p.marques.single.libelle, t.salle.dynamique.arriveesMarque(n: 2));
      p.avancer(AppMouvement.marqueArrivee);
      expect(p.marques, isEmpty);
      p.dispose();
    });
  });

  group('pause proposee', () {
    late DateTime maintenant;
    late PiloteDynamique dyn;
    late _Commandes cmd;
    late PilotePause pause;

    setUp(() {
      maintenant = _t.subtract(const Duration(minutes: 1));
      dyn = PiloteDynamique();
      cmd = _Commandes();
      pause = PilotePause(
        dynamique: dyn,
        maintenant: () => maintenant,
        commandes: cmd,
      );
    });
    tearDown(() => dyn.dispose());

    test('a proposerA : « Pause de 10 min ? », Oui demarre', () async {
      pause.observer(_programmee(proposer: _t), pilote: true);
      expect(dyn.alerte, isNull);
      maintenant = _t;
      pause.evaluer();
      final AlerteChrono a = dyn.alerte!;
      expect(a.titre, contains('10'));
      expect(a.actions.map((ActionAlerteChrono x) => x.libelle), <String>[
        'Oui',
        'Non',
      ]);
      expect(a.actions.first.principale, isTrue);
      a.actions.first.onPress();
      dyn.choisir(a.id);
      await _attendre();
      expect(cmd.appels, <String>['demarrer']);
      // Le serveur rend la pause en cours : tous l'apprennent, avec l'heure.
      pause.observer(_enCours(_t), pilote: true);
      expect(dyn.alerte?.id, startsWith('pause-debut'));
      expect(dyn.alerte?.titre, contains('Reprise'));
      expect(dyn.aMarque(PilotePause.cleProposee), isFalse);
    });

    test('Non refuse ; la prochaine proposerA vient du serveur ; nulle : plus '
        'rien', () async {
      maintenant = _t;
      pause.observer(_programmee(proposer: _t), pilote: true);
      final AlerteChrono a = dyn.alerte!;
      a.actions.last.onPress();
      dyn.choisir(a.id);
      await _attendre();
      expect(cmd.appels, <String>['refuser']);
      pause.evaluer();
      expect(dyn.alerte, isNull, reason: 'en attente de la reponse du serveur');
      final DateTime rappel = _t.add(const Duration(minutes: 5));
      pause.observer(_programmee(proposer: rappel, refus: 1), pilote: true);
      maintenant = rappel.subtract(const Duration(seconds: 1));
      pause.evaluer();
      expect(dyn.alerte, isNull);
      maintenant = rappel;
      pause.evaluer();
      expect(dyn.alerte?.titre, contains('10'));
      dyn.retirer(dyn.alerte!.id);
      pause.observer(_programmee(refus: 2), pilote: true);
      maintenant = rappel.add(const Duration(minutes: 30));
      pause.evaluer();
      expect(dyn.alerte, isNull);
      expect(dyn.aMarque(PilotePause.cleProposee), isFalse);
    });

    test('sans reponse : marque « Pause proposee », rappel apres 5 min, rien '
        'n est envoye', () {
      maintenant = _t;
      pause.observer(_programmee(proposer: _t), pilote: true);
      expect(dyn.alerte, isNotNull);
      dyn.avancer(AppMouvement.propositionPause);
      expect(dyn.alerte, isNull);
      expect(dyn.aMarque(PilotePause.cleProposee), isTrue);
      expect(dyn.marques.single.libelle, t.salle.dynamique.pauseProposee);
      maintenant = _t.add(const Duration(seconds: 30));
      pause.evaluer();
      maintenant = _t.add(const Duration(minutes: 5, seconds: 29));
      pause.evaluer();
      expect(dyn.alerte, isNull);
      maintenant = _t.add(const Duration(minutes: 5, seconds: 31));
      pause.evaluer();
      expect(dyn.alerte?.titre, contains('10'));
      expect(cmd.appels, isEmpty, reason: 'ne pas repondre n est pas refuser');
    });

    test('echec du serveur : la proposition reste', () async {
      cmd.echec = true;
      maintenant = _t;
      pause.observer(_programmee(proposer: _t), pilote: true);
      final AlerteChrono a = dyn.alerte!;
      a.actions.first.onPress();
      dyn.choisir(a.id);
      await _attendre();
      await _attendre();
      expect(cmd.appels, <String>['demarrer']);
      expect(dyn.alerte?.titre, contains('10'));
    });

    test('serveur ancien (proposerA nul) : aucune proposition', () {
      maintenant = _t.add(const Duration(minutes: 10));
      pause.observer(_programmee(), pilote: true);
      expect(dyn.alerte, isNull);
      expect(dyn.marques, isEmpty);
    });

    test('sans la capacite peutPiloter : jamais de proposition', () {
      maintenant = _t;
      pause.observer(_programmee(proposer: _t), pilote: false);
      expect(dyn.alerte, isNull);
    });

    test(
      'fin automatique a la reprise, une fois ; un echec se reessaie',
      () async {
        cmd.echec = true;
        maintenant = _t;
        pause.observer(_enCours(_t), pilote: true);
        dyn.retirer(dyn.alerte!.id);
        maintenant = _t.add(const Duration(minutes: 10));
        pause.evaluer();
        await _attendre();
        expect(cmd.appels, <String>['terminer']);
        // La barre dit la fin a tous, par l'heure.
        expect(dyn.alerte?.titre, t.salle.dynamique.pauseFinie);
        cmd.echec = false;
        pause.evaluer();
        await _attendre();
        expect(cmd.appels, <String>['terminer', 'terminer']);
        pause.evaluer();
        await _attendre();
        expect(cmd.appels, hasLength(2), reason: 'une seule fin confirmee');
      },
    );

    test('pause de priere : annoncee 3 min avant, decaler refuse, puis depart '
        'seul a l heure', () async {
      final PauseSeance priere = _programmee(
        proposer: _t,
        motif: MotifPause.priere,
      );
      maintenant = _t.subtract(const Duration(minutes: 4));
      pause.observer(priere, pilote: true);
      expect(dyn.alerte, isNull);
      maintenant = _t.subtract(const Duration(minutes: 3));
      pause.evaluer();
      final AlerteChrono a = dyn.alerte!;
      expect(
        a.titre,
        LibellesGroupe.insecable(t.salle.dynamique.priereDans(minutes: 3)),
      );
      expect(
        a.actions.map((ActionAlerteChrono x) => x.libelle).first,
        t.salle.dynamique.commencerMaintenant,
      );
      a.actions.last.onPress();
      dyn.choisir(a.id);
      await _attendre();
      expect(cmd.appels, <String>['refuser']);
      final DateTime plusTard = _t.add(const Duration(minutes: 5));
      pause.observer(
        _programmee(proposer: plusTard, motif: MotifPause.priere),
        pilote: true,
      );
      maintenant = plusTard;
      pause.evaluer();
      await _attendre();
      expect(cmd.appels, <String>['refuser', 'demarrer']);
      pause.observer(
        _enCours(plusTard, motif: MotifPause.priere),
        pilote: true,
      );
      expect(dyn.alerte?.titre, startsWith(t.salle.dynamique.priereNom));
    });
  });

  group('eleve (relais, sans commande)', () {
    test('debut annonce avec l heure ; passee la reprise, « La pause est '
        'finie » sans message de fin', () {
      DateTime maintenant = _t;
      final PiloteDynamique dyn = PiloteDynamique();
      final PilotePause pause = PilotePause(
        dynamique: dyn,
        maintenant: () => maintenant,
      );
      pause.observer(_enCours(_t), pilote: true);
      expect(dyn.alerte?.id, startsWith('pause-debut'));
      dyn.retirer(dyn.alerte!.id);
      maintenant = _t.add(const Duration(minutes: 10, seconds: 1));
      pause.evaluer();
      expect(dyn.alerte?.titre, t.salle.dynamique.pauseFinie);
      expect(
        pauseALInstant(_enCours(_t), maintenant)?.statut,
        StatutPause.prise,
      );
      dyn.dispose();
    });
  });

  test('titre de la recitation : prenom inconnu, « Un eleve recite »', () {
    expect(titreRecitation(''), t.salle.dynamique.unEleveRecite);
    expect(
      titreRecitation('Yasmine'),
      t.tc.classe.recitation.actif(prenom: 'Yasmine'),
    );
  });
}
