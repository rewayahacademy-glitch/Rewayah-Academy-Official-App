import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'video_session_provider.dart';

/// Le **seul** fichier du produit autorise a importer `livekit_client`.
///
/// La regle vient de l'ADR-001 et elle se verifie d'un `grep` : si un ecran
/// importait le SDK, la promesse de portabilite s'evanouirait, et changer de
/// moteur temps reel demanderait de rouvrir chaque salle.
///
/// Ce que cette classe **ne fait pas**, et c'est l'essentiel (specification
/// sections 2 et 47) : elle ne reimplemente ni WebRTC, ni ICE, ni la
/// reconnexion, ni la gestion des pistes, ni le simulcast. Tout cela existe
/// dans le SDK et y reste. Elle traduit, elle n'invente pas.
class LiveKitSessionProvider implements VideoSessionProvider {
  /// Cree le fournisseur.
  LiveKitSessionProvider();

  lk.Room? _salle;
  lk.EventsListener<lk.RoomEvent>? _ecouteur;
  AccesSalle? _acces;

  final StreamController<EtatSalle> _etats =
      StreamController<EtatSalle>.broadcast();
  final StreamController<List<ParticipantSalle>> _participants =
      StreamController<List<ParticipantSalle>>.broadcast();
  final StreamController<QualiteLien> _qualite =
      StreamController<QualiteLien>.broadcast();

  EtatSalle _etat = EtatSalle.absent;
  bool _audioSeul = false;

  /// La camera etait-elle ouverte avant que le reseau ne la fasse ceder ?
  ///
  /// Sans cette memoire, une degradation couperait l'image **definitivement** :
  /// au retour du reseau, plus rien ne saurait qu'il faut la rouvrir, et
  /// l'usager croirait sa camera cassee.
  bool _cameraAvantDegradation = false;
  bool _degradee = false;

  @override
  EtatSalle get etatCourant => _etat;

  @override
  Stream<EtatSalle> get etats => _etats.stream;

  @override
  Stream<List<ParticipantSalle>> get participants => _participants.stream;

  @override
  Stream<QualiteLien> get qualite => _qualite.stream;

  void _poser(EtatSalle etat) {
    if (_etat == etat) {
      return;
    }
    _etat = etat;
    if (!_etats.isClosed) {
      _etats.add(etat);
    }
  }

  @override
  Future<void> rejoindre(AccesSalle acces) async {
    // Une entree alors qu'une salle est deja ouverte fuirait la precedente :
    // pistes, rendus et ecouteurs resteraient vivants, et l'audio se
    // doublerait. On ferme avant d'ouvrir, toujours.
    await quitter();

    _acces = acces;
    _poser(EtatSalle.connexion);

    // `RoomOptions` se pose au CONSTRUCTEUR : le passer a `connect()` est
    // deprecie depuis livekit_client 2.x et sera ignore un jour.
    final lk.Room salle = lk.Room(
      roomOptions: const lk.RoomOptions(
        // Les deux leviers que la specification section 13 demande d'activer :
        // `adaptiveStream` ajuste la resolution recue a la taille reellement
        // affichee, `dynacast` cesse d'emettre les couches que personne ne
        // regarde. Ce sont eux qui tiennent la promesse « ne pas rendre toutes
        // les videos en haute qualite » sans une ligne de code maison.
        adaptiveStream: true,
        dynacast: true,
        // **Les defauts de capture audio sont conserves volontairement.**
        // La specification section 18 met en garde : une configuration
        // « musicale » desactive l'annulation d'echo, la suppression de bruit
        // et le gain automatique. Pour de la recitation, ou l'intelligibilite
        // prime sur la fidelite, ce serait un contresens -- et le premier
        // cours en environnement bruyant le prouverait.
        defaultAudioCaptureOptions: lk.AudioCaptureOptions(),
      ),
    );
    _salle = salle;

    final lk.EventsListener<lk.RoomEvent> ecouteur = salle.createListener();
    _ecouteur = ecouteur;
    _brancher(ecouteur);

    try {
      await salle.connect(acces.urlServeur, acces.jeton);
    } catch (e) {
      debugPrint('connexion a la salle impossible : $e');
      _poser(EtatSalle.echec);
      await quitter();
      rethrow;
    }

    // La voix d'abord : on ouvre le micro des l'entree quand le jeton
    // l'autorise, la camera seulement si elle est permise ET si l'on n'est pas
    // en mode economie de donnees.
    if (acces.capacites.peutPublier) {
      await reglerMicro(actif: true);
    }
    if (acces.capacites.peutPublierVideo && !_audioSeul) {
      await reglerCamera(actif: true);
    }

    _poser(EtatSalle.connecte);
    _publierParticipants();
  }

  void _brancher(lk.EventsListener<lk.RoomEvent> ecouteur) {
    // Un seul recalcul par evenement, et une seule liste publiee : la
    // specification section 15 interdit un rebuild global a chaque evenement
    // WebRTC. L'agregation se fait donc ici, une fois, plutot que dans chaque
    // widget.
    ecouteur
      ..on<lk.RoomConnectedEvent>((_) {
        _poser(EtatSalle.connecte);
        _publierParticipants();
      })
      ..on<lk.RoomReconnectingEvent>((_) {
        // Une reconnexion n'est PAS une absence (specification section 27) :
        // l'etat de presence continue, c'est la meme session.
        _poser(EtatSalle.reconnexion);
      })
      ..on<lk.RoomReconnectedEvent>((_) {
        _poser(EtatSalle.connecte);
        _publierParticipants();
      })
      ..on<lk.RoomDisconnectedEvent>((_) {
        _poser(EtatSalle.absent);
        _publierParticipants();
      })
      ..on<lk.ParticipantConnectedEvent>((_) => _publierParticipants())
      ..on<lk.ParticipantDisconnectedEvent>((_) => _publierParticipants())
      ..on<lk.TrackPublishedEvent>((_) => _publierParticipants())
      ..on<lk.TrackUnpublishedEvent>((_) => _publierParticipants())
      ..on<lk.TrackSubscribedEvent>((_) => _publierParticipants())
      ..on<lk.TrackUnsubscribedEvent>((_) => _publierParticipants())
      ..on<lk.LocalTrackPublishedEvent>((_) => _publierParticipants())
      ..on<lk.TrackMutedEvent>((_) => _publierParticipants())
      ..on<lk.TrackUnmutedEvent>((_) => _publierParticipants())
      ..on<lk.ActiveSpeakersChangedEvent>((_) => _publierParticipants())
      ..on<lk.ParticipantConnectionQualityUpdatedEvent>((
        lk.ParticipantConnectionQualityUpdatedEvent e,
      ) {
        if (e.participant.identity == _salle?.localParticipant?.identity) {
          final QualiteLien lien = _traduireQualite(e.connectionQuality);
          if (!_qualite.isClosed) {
            _qualite.add(lien);
          }
          unawaited(_degrader(lien));
        }
        _publierParticipants();
      });
  }

  /// La degradation controlee de la specification section 17 : **l'audio ne
  /// cede jamais, la video cede la premiere.**
  ///
  /// Ce n'est pas une mesure maison de la bande passante (section 30
  /// l'interdit) : c'est la lecture du signal que LiveKit publie deja.
  Future<void> _degrader(QualiteLien lien) async {
    final AccesSalle? acces = _acces;
    if (acces == null || !acces.capacites.peutPublierVideo || _audioSeul) {
      return;
    }
    final lk.LocalParticipant? local = _salle?.localParticipant;
    if (local == null) {
      return;
    }

    final bool mauvais = lien == QualiteLien.mediocre || lien == QualiteLien.perdue;

    if (mauvais && !_degradee) {
      _cameraAvantDegradation = local.isCameraEnabled();
      _degradee = true;
      if (_cameraAvantDegradation) {
        await local.setCameraEnabled(false);
        _publierParticipants();
      }
      return;
    }

    if (!mauvais && _degradee) {
      _degradee = false;
      // Restauration PROGRESSIVE : on ne rouvre que ce qui etait ouvert. Une
      // camera que l'usager avait fermee lui-meme doit le rester.
      if (_cameraAvantDegradation) {
        await local.setCameraEnabled(true);
        _publierParticipants();
      }
    }
  }

  QualiteLien _traduireQualite(lk.ConnectionQuality q) => switch (q) {
    lk.ConnectionQuality.excellent => QualiteLien.excellente,
    lk.ConnectionQuality.good => QualiteLien.bonne,
    lk.ConnectionQuality.poor => QualiteLien.mediocre,
    lk.ConnectionQuality.lost => QualiteLien.perdue,
    lk.ConnectionQuality.unknown => QualiteLien.inconnue,
  };

  /// Lit le role depuis les metadonnees du jeton.
  ///
  /// Elles sont signees par le backend : un participant ne peut pas s'attribuer
  /// le role d'enseignant en les modifiant, LiveKit refuserait le jeton.
  String _roleDe(lk.Participant p) {
    final String? brut = p.metadata;
    if (brut == null || brut.isEmpty) {
      return '';
    }
    try {
      final Object? decode = jsonDecode(brut);
      if (decode is Map<String, dynamic>) {
        return decode['role'] as String? ?? '';
      }
    } catch (_) {
      // Une metadonnee illisible n'est pas un incident : le role sert au
      // placement visuel, pas a une decision de securite.
    }
    return '';
  }

  ParticipantSalle _traduire(lk.Participant p, {required bool local}) =>
      ParticipantSalle(
        identite: p.identity,
        nom: p.name.isNotEmpty ? p.name : p.identity,
        role: _roleDe(p),
        estLocal: local,
        micro: p.isMicrophoneEnabled(),
        camera: p.isCameraEnabled(),
        parle: p.isSpeaking,
        qualite: _traduireQualite(p.connectionQuality),
      );

  void _publierParticipants() {
    final lk.Room? salle = _salle;
    if (salle == null || _participants.isClosed) {
      return;
    }
    final List<ParticipantSalle> liste = <ParticipantSalle>[
      if (salle.localParticipant case final lk.LocalParticipant moi)
        _traduire(moi, local: true),
      for (final lk.RemoteParticipant autre in salle.remoteParticipants.values)
        _traduire(autre, local: false),
    ];
    _participants.add(liste);
  }

  @override
  Future<void> reglerMicro({required bool actif}) async {
    final lk.LocalParticipant? local = _salle?.localParticipant;
    if (local == null || !(_acces?.capacites.peutPublier ?? false)) {
      return;
    }
    await local.setMicrophoneEnabled(actif);
    _publierParticipants();
  }

  @override
  Future<void> reglerCamera({required bool actif}) async {
    final lk.LocalParticipant? local = _salle?.localParticipant;
    // Le jeton fait foi. Tenter quand meme ne servirait qu'a produire une
    // erreur serveur : le refus est deja inscrit dans les capacites signees.
    if (local == null || !(_acces?.capacites.peutPublierVideo ?? false)) {
      return;
    }
    if (actif && _audioSeul) {
      return;
    }
    await local.setCameraEnabled(actif);
    // Un geste explicite de l'usager redefinit ce que la degradation devra
    // restaurer : sans cela, un retour de reseau rouvrirait une camera qu'il
    // venait de fermer.
    _cameraAvantDegradation = actif;
    _publierParticipants();
  }

  @override
  Future<void> reglerAudioSeul({required bool actif}) async {
    _audioSeul = actif;
    final lk.Room? salle = _salle;
    if (salle == null) {
      return;
    }

    if (actif) {
      await salle.localParticipant?.setCameraEnabled(false);
    } else if (_acces?.capacites.peutPublierVideo ?? false) {
      await salle.localParticipant?.setCameraEnabled(_cameraAvantDegradation);
    }

    // Cesser de RECEVOIR la video, et pas seulement d'en emettre : c'est la
    // moitie du gain. Une salle de six coute autant en reception qu'en
    // emission, et c'est la reception qui vide un forfait mobile.
    for (final lk.RemoteParticipant distant in salle.remoteParticipants.values) {
      for (final lk.RemoteTrackPublication<lk.RemoteVideoTrack> piste
          in distant.videoTrackPublications) {
        if (actif) {
          await piste.unsubscribe();
        } else {
          await piste.subscribe();
        }
      }
    }
    _publierParticipants();
  }

  @override
  Future<void> quitter() async {
    // L'ordre compte : on cesse d'ecouter AVANT de fermer, sinon la fermeture
    // republie des etats dans des controleurs qu'on s'apprete a vider.
    final lk.EventsListener<lk.RoomEvent>? ecouteur = _ecouteur;
    _ecouteur = null;
    await ecouteur?.dispose();

    final lk.Room? salle = _salle;
    _salle = null;
    if (salle != null) {
      try {
        await salle.disconnect();
      } catch (e) {
        debugPrint('deconnexion imparfaite : $e');
      }
      await salle.dispose();
    }

    _acces = null;
    _degradee = false;
    _cameraAvantDegradation = false;
    _poser(EtatSalle.absent);
  }

  @override
  Future<void> liberer() async {
    await quitter();
    await _etats.close();
    await _participants.close();
    await _qualite.close();
  }
}
