import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:rewayah_academy/core/tc_classe/port_session_persistante.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/video/ecran_eveille.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

import '../../teaching_core/e/faux/faux_classe.dart';

/// ECRAN-EVEILLE (directeur, 11/11/2026) : « il ne faut pas que l'extinction
/// de l'ecran coupe le reseau ou bien coupe la voix ou le micro ».
void main() {
  group('verrou de l ecran', () {
    test('pris a l entree, rendu a la sortie', () async {
      final _FauxNavigateur nav = _FauxNavigateur();
      final EcranEveille ecran = EcranEveille(nav);

      ecran.tenir();
      await _vider();
      expect(nav.demandes, 1);
      expect(ecran.actif, isTrue);

      ecran.rendre();
      await _vider();
      expect(nav.relaches, 1);
      expect(ecran.actif, isFalse);
      expect(nav.ecoutes, 0, reason: 'plus aucune ecoute de visibilite');
    });

    test('tenir deux fois ne demande qu une fois', () async {
      final _FauxNavigateur nav = _FauxNavigateur();
      final EcranEveille ecran = EcranEveille(nav)
        ..tenir()
        ..tenir();
      await _vider();
      expect(nav.demandes, 1);
      ecran.rendre();
    });

    test(
      'repris au retour de l onglet, apres que le navigateur l a relache',
      () async {
        final _FauxNavigateur nav = _FauxNavigateur();
        final EcranEveille ecran = EcranEveille(nav)..tenir();
        await _vider();

        // L'onglet passe a l'arriere-plan : le navigateur relache le verrou.
        nav.cacher();
        await _vider();
        expect(ecran.actif, isFalse);
        expect(nav.demandes, 1, reason: 'aucune demande pour une page cachee');

        nav.montrer();
        await _vider();
        expect(nav.demandes, 2);
        expect(ecran.actif, isTrue);
        ecran.rendre();
      },
    );

    test('pas repris apres la sortie', () async {
      final _FauxNavigateur nav = _FauxNavigateur();
      final EcranEveille ecran = EcranEveille(nav)..tenir();
      await _vider();
      ecran.rendre();
      nav
        ..cacher()
        ..montrer();
      await _vider();
      expect(nav.demandes, 1);
    });

    test(
      'API absente (vieux Safari) : rien ne leve, rien n est demande',
      () async {
        final _FauxNavigateur nav = _FauxNavigateur(disponible: false);
        final EcranEveille ecran = EcranEveille(nav)..tenir();
        await _vider();
        expect(nav.demandes, 0);
        expect(ecran.tenu, isTrue);
        ecran.rendre();
      },
    );

    test('refus du navigateur : journalise, la seance continue', () async {
      final _FauxNavigateur nav = _FauxNavigateur(refuse: true);
      final EcranEveille ecran = EcranEveille(nav)..tenir();
      await _vider();
      expect(nav.demandes, 1);
      expect(ecran.actif, isFalse);
      ecran.rendre();
    });

    test('hors navigateur : sans effet', () {
      final EcranEveille ecran = EcranEveille(null)
        ..tenir()
        ..rendre();
      expect(ecran.actif, isFalse);
    });
  });

  group('le controleur de seance tient l ecran', () {
    const SessionEnCours cours = SessionEnCours(
      sessionId: 's1',
      groupeId: 'g1',
      libelleGroupe: 'Classe Al-Fatiha',
      eleveId: 'e1',
    );

    ({
      ControleurSessionPersistante controleur,
      _FauxMoteurReprise moteur,
      _FauxNavigateur nav,
      FauxServiceVideoClasse video,
    })
    monter() {
      final _FauxNavigateur nav = _FauxNavigateur();
      final _FauxMoteurReprise moteur = _FauxMoteurReprise();
      final FauxServiceVideoClasse video = FauxServiceVideoClasse(
        acces0: accesDe('student'),
      );
      final ControleurSessionPersistante controleur =
          ControleurSessionPersistante(
            moteur,
            video,
            observeLeCycleDeVie: false,
            ecranEveille: EcranEveille(nav),
          );
      addTearDown(controleur.liberer);
      return (controleur: controleur, moteur: moteur, nav: nav, video: video);
    }

    test('appel confie : ecran tenu ; quitter : ecran rendu', () async {
      final b = monter();
      b.controleur.adopter(cours: cours, acces: accesDe('student'));
      await _vider();
      expect(b.nav.demandes, 1);

      await b.controleur.quitter();
      await _vider();
      expect(b.nav.relaches, 1);
    });

    test('la fin de l appel par le serveur rend aussi l ecran', () async {
      final b = monter();
      b.controleur.adopter(cours: cours, acces: accesDe('student'));
      await _vider();
      b.moteur.poser(EtatSalle.echec);
      await _vider();
      expect(b.nav.relaches, 1);
    });

    test('le moteur recoit une source de jeton neuf tant que l appel est '
        'confie, pour la bonne seance et le bon eleve', () async {
      final b = monter();
      expect(b.moteur.source, isNull);
      b.controleur.adopter(cours: cours, acces: accesDe('student'));
      expect(b.moteur.source, isNotNull);
      await b.moteur.source!();
      expect(b.video.demandes, <String>['s1']);

      await b.controleur.quitter();
      expect(b.moteur.source, isNull);
    });

    test('onglet cache puis revenu (navigateur : hidden, jamais paused) : '
        'le moteur l apprend, et rien n est coupe', () async {
      final b = monter();
      b.controleur.adopter(cours: cours, acces: accesDe('student'));

      // L'ordre que Flutter produit sur le web : resumed, inactive, hidden.
      b.controleur
        ..didChangeAppLifecycleState(AppLifecycleState.inactive)
        ..didChangeAppLifecycleState(AppLifecycleState.hidden);
      expect(b.moteur.premiersPlans, <bool>[false]);
      b.controleur
        ..didChangeAppLifecycleState(AppLifecycleState.inactive)
        ..didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(b.moteur.premiersPlans, <bool>[false, true]);

      expect(b.moteur.departs, 0);
      expect(b.moteur.microDemande, isEmpty, reason: 'aucun micro touche');
      expect(b.moteur.cameraDemandee, isEmpty);
      expect(b.controleur.etatCourant.retourDeSuspension, isFalse);
    });

    test('une fenetre sans le focus (inactive) n est pas un arriere-plan', () {
      final b = monter();
      b.controleur.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(b.moteur.premiersPlans, isEmpty);
    });
  });

  group('reprise : micro et camera rendus, jamais plus', () {
    ({bool micro, bool camera}) apres({
      bool microVoulu = false,
      bool cameraVoulue = false,
      bool peutPublier = true,
      bool peutPublierVideo = true,
      bool microOuvert = false,
      bool cameraOuverte = false,
      bool audioSeul = false,
      bool repliActif = false,
    }) => mediasARestaurer(
      microVoulu: microVoulu,
      cameraVoulue: cameraVoulue,
      peutPublier: peutPublier,
      peutPublierVideo: peutPublierVideo,
      microOuvert: microOuvert,
      cameraOuverte: cameraOuverte,
      audioSeul: audioSeul,
      repliActif: repliActif,
    );

    test('ouverts avant la veille, perdus avec elle : rouverts', () {
      expect(apres(microVoulu: true, cameraVoulue: true), (
        micro: true,
        camera: true,
      ));
    });

    test('un micro ferme par la personne n est jamais rouvert', () {
      expect(apres(cameraVoulue: true).micro, isFalse);
    });

    test('sans le droit du serveur, rien n est rouvert', () {
      expect(
        apres(
          microVoulu: true,
          cameraVoulue: true,
          peutPublier: false,
          peutPublierVideo: false,
        ),
        (micro: false, camera: false),
      );
    });

    test('deja ouverts (la coupure n a rien perdu) : rien a refaire', () {
      expect(
        apres(
          microVoulu: true,
          cameraVoulue: true,
          microOuvert: true,
          cameraOuverte: true,
        ),
        (micro: false, camera: false),
      );
    });

    test(
      'audio seul ou repli du reseau : la camera attend, la voix revient',
      () {
        expect(apres(microVoulu: true, cameraVoulue: true, audioSeul: true), (
          micro: true,
          camera: false,
        ));
        expect(apres(microVoulu: true, cameraVoulue: true, repliActif: true), (
          micro: true,
          camera: false,
        ));
      },
    );
  });

  group('reprise sans geste : seulement les coupures du transport', () {
    test('le SDK a epuise ses essais, le reseau est tombe : reprise', () {
      for (final lk.DisconnectReason? raison in <lk.DisconnectReason?>[
        null,
        lk.DisconnectReason.reconnectAttemptsExceeded,
        lk.DisconnectReason.disconnected,
        lk.DisconnectReason.signalingConnectionFailure,
        lk.DisconnectReason.signalClose,
        lk.DisconnectReason.serverShutdown,
      ]) {
        expect(repriseSansGestePermise(raison), isTrue, reason: '$raison');
      }
    });

    test('une decision du serveur ou de la personne : jamais', () {
      for (final lk.DisconnectReason raison in <lk.DisconnectReason>[
        lk.DisconnectReason.clientInitiated,
        lk.DisconnectReason.participantRemoved,
        lk.DisconnectReason.duplicateIdentity,
        lk.DisconnectReason.roomDeleted,
        lk.DisconnectReason.roomClosed,
      ]) {
        expect(repriseSansGestePermise(raison), isFalse, reason: '$raison');
      }
    });

    test(
      'le delai avant le message reste raisonnable (moins d une minute)',
      () {
        final Duration total = delaisRepriseSansGeste.fold(
          Duration.zero,
          (Duration a, Duration b) => a + b,
        );
        expect(total, lessThan(const Duration(minutes: 1)));
      },
    );

    test('le vrai moteur sait reprendre seul', () {
      expect(LiveKitSessionProvider(), isA<RepriseAutomatique>());
    });
  });
}

Future<void> _vider() => Future<void>.delayed(Duration.zero);

class _FauxNavigateur implements VerrouEcranNavigateur {
  _FauxNavigateur({this.disponible = true, this.refuse = false});

  @override
  final bool disponible;

  final bool refuse;

  @override
  bool visible = true;

  int demandes = 0;
  int relaches = 0;
  int ecoutes = 0;

  final List<_FauxVerrou> _verrous = <_FauxVerrou>[];

  late final StreamController<void> _visibilite =
      StreamController<void>.broadcast(
        onListen: () => ecoutes++,
        onCancel: () => ecoutes--,
      );

  @override
  Stream<void> get changementsDeVisibilite => _visibilite.stream;

  void cacher() {
    visible = false;
    // Ce que fait tout navigateur : la page cachee perd son verrou.
    for (final _FauxVerrou v in _verrous) {
      v.relache = true;
    }
    _visibilite.add(null);
  }

  void montrer() {
    visible = true;
    _visibilite.add(null);
  }

  @override
  Future<Object> demander() async {
    demandes++;
    if (refuse) throw StateError('NotAllowedError');
    final _FauxVerrou v = _FauxVerrou();
    _verrous.add(v);
    return v;
  }

  @override
  bool estRelache(Object verrou) => (verrou as _FauxVerrou).relache;

  @override
  Future<void> relacher(Object verrou) async {
    relaches++;
    (verrou as _FauxVerrou).relache = true;
  }
}

class _FauxVerrou {
  bool relache = false;
}

class _FauxMoteurReprise extends FauxMoteurClasse
    implements RepriseAutomatique {
  Future<AccesSalle> Function()? source;
  final List<bool> premiersPlans = <bool>[];

  @override
  set sourceJeton(Future<AccesSalle> Function()? source) =>
      this.source = source;

  @override
  void premierPlan({required bool visible}) => premiersPlans.add(visible);
}
