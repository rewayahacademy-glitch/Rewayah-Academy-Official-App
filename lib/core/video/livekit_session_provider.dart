import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../observabilite/journal_dev.dart';
import 'video_session_provider.dart';

/// Le debit maximal de la couche 720p, en bits par seconde (D15) : environ
/// 1,8 Mbit/s envoyes pour les trois couches, 1,2 recus pour une video agrandie.
const int debitMax720p = 1200000;

/// D15 (S0.2) : `adaptiveStream` seulement chez l'enseignant.
bool adaptiveStreamPour(AccesSalle acces) => acces.role == 'teacher';

/// Vrai quand la camera s'allume d'elle-meme a l'entree : **jamais**, pour
/// aucun role (decision du directeur du 25/10/2026, lot salle 3 §1.1, apres
/// le test K4 : la camera d'un compte enfant s'allumait seule). La camera est
/// fermee a l'entree comme le micro ; un appui volontaire l'allume. Remplace
/// l'exception D14 du 24/10/2026 (eleve dont le tuteur autorisait l'image).
/// [acces] reste en parametre : la regle se lit par role dans les tests.
bool cameraAllumeeALEntree(AccesSalle acces) => false;

/// La seule implementation du contrat, et le seul endroit ou le SDK est
/// **traduit**.
///
/// La regle de l'ADR-001 porte sur le peripherique, pas sur le nombre de
/// fichiers : `livekit_client` ne s'importe que sous `lib/core/video/`, jamais
/// dans `lib/features/`. Deux fichiers l'importent donc, et c'est correct --
/// celui-ci et `pre_vol.dart`, qui enumere le materiel par `lk.Hardware`.
///
/// **Ce commentaire disait « le seul fichier du produit autorise a importer
/// livekit_client », et c'etait faux depuis le lot N2** : `pre_vol.dart:3`
/// l'importait deja. Corrige le 20 septembre 2026 plutot que de deplacer le
/// pre-vol : le SDK y fait exactement ce qu'on lui demande partout ailleurs --
/// enumerer six plateformes a notre place -- et le reecrire serait le seul vrai
/// moyen de trahir l'ADR-001. Ce qui compte se verifie toujours d'un `grep` :
/// aucun `import 'package:livekit_client` hors de `lib/core/video/`.
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
  final StreamController<ContenuPresente> _contenus =
      StreamController<ContenuPresente>.broadcast();
  final StreamController<PaquetDonnees> _donnees =
      StreamController<PaquetDonnees>.broadcast();

  EtatSalle _etat = EtatSalle.absent;
  bool _audioSeul = false;

  /// Le dernier contenu presente, cote emetteur comme cote recepteur.
  ///
  /// **C'est la totalite de l'etat pedagogique qui survit a une coupure.** Il
  /// vit ici et non dans l'etat d'un ecran parce que ce provider vit aussi
  /// longtemps que l'application, la ou un `State` meurt a chaque demontage :
  /// une rotation d'appareil suffirait a perdre la page ouverte devant la
  /// classe. Il n'est efface que par une sortie volontaire, jamais par une
  /// deconnexion.
  ContenuPresente? _dernierContenu;

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

  @override
  Stream<ContenuPresente> get contenusPresentes async* {
    // Le dernier contenu connu d'abord, le flux ensuite : un abonne qui arrive
    // apres le tour de page -- ecran remonte, onglet reveille -- doit retrouver
    // la page ouverte, et pas une salle vide. Un `StreamController.broadcast`
    // ne rejoue rien, c'est donc ici que cela se fait, une fois, plutot que
    // dans chaque ecran.
    final ContenuPresente? dernier = _dernierContenu;
    if (dernier != null) {
      yield dernier;
    }
    yield* _contenus.stream;
  }

  @override
  Stream<PaquetDonnees> get donneesRecues => _donnees.stream;

  @override
  AccesSalle? get accesCourant => _acces;

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
      roomOptions: lk.RoomOptions(
        // Les deux leviers que la specification section 13 demande d'activer :
        // `adaptiveStream` ajuste la resolution recue a la taille reellement
        // affichee, `dynacast` cesse d'emettre les couches que personne ne
        // regarde. Ce sont eux qui tiennent la promesse « ne pas rendre toutes
        // les videos en haute qualite » sans une ligne de code maison.
        //
        // D15 (S0.2, tranche par le pilote le 24/10/2026) : `adaptiveStream`
        // est coupe chez qui n'est pas enseignant. Sur Flutter web, il ne
        // remonte pas toujours la taille reelle du rendu, et la video agrandie
        // de l'enseignant restait floue ; `setVideoQuality` n'y peut rien, car
        // le SDK garde la plus petite des deux demandes (livekit_client 2.12,
        // `remote.dart:298-303`). L'eleve ne recoit qu'un flux utile, celui de
        // l'enseignant, plafonne a 1,2 Mbit/s ([debitMax720p]) ; l'enseignant,
        // qui recoit jusqu'a six flux, le garde.
        adaptiveStream: adaptiveStreamPour(acces),
        dynacast: true,
        // **Les defauts de capture audio sont conserves volontairement.**
        // La specification section 18 met en garde : une configuration
        // « musicale » desactive l'annulation d'echo, la suppression de bruit
        // et le gain automatique. Pour de la recitation, ou l'intelligibilite
        // prime sur la fidelite, ce serait un contresens -- et le premier
        // cours en environnement bruyant le prouverait.
        defaultAudioCaptureOptions: const lk.AudioCaptureOptions(),
        // D15 (24/10/2026, decision du pilote) : l'image paraissait « 240p »
        // avec les reglages par defaut, parce que les petites vignettes ne
        // demandaient que la couche basse. Publication 720p en trois couches
        // (180p, 360p, 720p), 720p plafonne a 1,2 Mbit/s ; `adaptiveStream`
        // reste chez l'enseignant (voir plus haut).
        defaultCameraCaptureOptions: const lk.CameraCaptureOptions(
          params: lk.VideoParametersPresets.h720_169,
        ),
        defaultVideoPublishOptions: const lk.VideoPublishOptions(
          videoEncoding: lk.VideoEncoding(
            maxBitrate: debitMax720p,
            maxFramerate: 30,
          ),
          videoSimulcastLayers: <lk.VideoParameters>[
            lk.VideoParametersPresets.h180_169,
            lk.VideoParametersPresets.h360_169,
          ],
        ),
      ),
    );
    _salle = salle;

    final lk.EventsListener<lk.RoomEvent> ecouteur = salle.createListener();
    _ecouteur = ecouteur;
    _brancher(ecouteur);

    try {
      await salle.connect(acces.urlServeur, acces.jeton);
    } catch (e) {
      journalDev('connexion a la salle impossible : $e');
      _poser(EtatSalle.echec);
      await quitter();
      rethrow;
    }

    // **Rien ne publie a l'entree, et c'est un invariant, pas une preference.**
    // Le catalogue d'ecrans le porte depuis la refonte et la fiche produit
    // l'ecrit deux fois : « a l'entree en seance, le micro ne publie rien tant
    // que l'eleve n'a pas tape dessus une fois », et « micro et camera de
    // l'enseignant demarrent egalement desactives ». La regle vaut pour les
    // quatre roles.
    //
    // Le lot N2 ouvrait ici le micro -- « la voix d'abord » -- et cette ligne
    // etait fausse : aucun ecran n'existait alors pour l'exercer, donc rien ne
    // l'a signalee. Ouvrir un micro sans geste, dans une maison ou un enfant
    // recite, est exactement ce que la regle empeche.
    //
    // L'exception D14 du 24/10/2026 (l'eleve autorise entrait camera allumee)
    // est retiree le 25/10/2026 par le directeur (lot salle 3 §1.1) : la
    // camera est fermee a l'entree pour tous les roles ; [cameraAllumeeALEntree]
    // le dit et ses tests le gardent.
    _poser(EtatSalle.connecte);
    if (cameraAllumeeALEntree(acces)) {
      try {
        await salle.localParticipant?.setCameraEnabled(true);
        _cameraAvantDegradation = true;
      } catch (e) {
        // Camera refusee par le navigateur ou occupee : l'eleve reste en
        // salle, camera coupee ; la salle dit la phrase du navigateur (D14).
        journalDev('camera de l eleve non allumee a l entree : $e');
        _erreurCameraEntree = '$e';
      }
    }
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
        // `retabli` et non `connecte` : le protocole exige que le retour d'une
        // coupure se distingue d'une premiere connexion, faute de quoi l'ecran
        // ne peut ni le dire ni rien en deduire.
        _poser(EtatSalle.retabli);
        _publierParticipants();
        // **La reconnexion sans perte de l'etat pedagogique.** Le serveur n'a
        // garde aucun paquet de donnees : si l'on presentait, il faut le
        // republier, sinon les eleves qui se reconnectent restent sur une salle
        // sans page. Un recepteur, lui, garde simplement ce qu'il avait.
        unawaited(_republierContenu());
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
      ..on<lk.DataReceivedEvent>(_recevoirDonnees)
      ..on<lk.ParticipantConnectionQualityUpdatedEvent>((
        lk.ParticipantConnectionQualityUpdatedEvent e,
      ) {
        if (e.participant.identity == _salle?.localParticipant?.identity) {
          final QualiteLien lien = _traduireQualite(e.connectionQuality);
          if (!_qualite.isClosed) {
            _qualite.add(lien);
          }
          _direLeLien(lien);
          unawaited(_degrader(lien));
        }
        _publierParticipants();
      });
  }

  /// Traduit la qualite du lien en etat de salle, quand elle change d'etage.
  ///
  /// La qualite voyage deja par son propre flux ; cet etat-la existe pour une
  /// autre raison : le protocole impose cinq etats de salle, dont « instable »,
  /// et un ecran qui devrait croiser lui-meme un etat et une qualite finirait
  /// par les afficher en contradiction.
  void _direLeLien(QualiteLien lien) {
    final bool mauvais =
        lien == QualiteLien.mediocre || lien == QualiteLien.perdue;
    if (mauvais) {
      // Jamais depuis `reconnexion` ni `echec` : ces deux etats en disent plus,
      // et les ecraser par un avertissement serait une regression d'information.
      if (_etat == EtatSalle.connecte || _etat == EtatSalle.retabli) {
        _poser(EtatSalle.instable);
      }
      return;
    }
    if (_etat == EtatSalle.instable) {
      _poser(EtatSalle.connecte);
    }
  }

  /// Lit un paquet du canal de donnees.
  ///
  /// **Un paquet illisible ne casse rien.** Il vient du reseau, donc d'une
  /// version d'application qu'on ne controle pas : le rattraper ici evite qu'un
  /// client plus recent ne fasse tomber le canal d'un client plus ancien pour
  /// tout le reste de la seance.
  void _recevoirDonnees(lk.DataReceivedEvent evenement) {
    final String sujet = evenement.topic ?? '';
    // Tout paquet est relaye sur le canal generalise, avant le traitement
    // specifique du socle qui suit : voir `TC_CONTRACT_REQUEST_F.md` §1.
    if (!_donnees.isClosed) {
      _donnees.add(
        paquetDepuisLeReseau(
          sujetRecu: sujet,
          charge: evenement.data,
          emetteurIdentite: evenement.participant?.identity,
        ),
      );
    }
    if (sujet != sujetContenuPresente) {
      return;
    }
    try {
      final Object? decode = jsonDecode(utf8.decode(evenement.data));
      if (decode is! Map<String, dynamic>) {
        return;
      }
      final ContenuPresente contenu = ContenuPresente.depuisJson(decode);
      // Un canal non fiable peut livrer un paquet apres un plus recent : sans
      // ce test, la classe reculerait d'une page sans que personne n'ait rien
      // demande.
      if (_dernierContenu case final ContenuPresente connu
          when contenu.emisLe.isBefore(connu.emisLe)) {
        return;
      }
      _dernierContenu = contenu;
      if (!_contenus.isClosed) {
        _contenus.add(contenu);
      }
    } catch (e) {
      journalDev('contenu presente illisible : $e');
    }
  }

  @override
  Future<void> presenterContenu(ContenuPresente contenu) async {
    final AccesSalle? acces = _acces;
    if (acces == null || !acces.capacites.peutPublierDonnees) {
      // Refus silencieux : un eleve ne presente pas. Lever ici obligerait
      // chaque appelant a rattraper une exception qui ne dit rien de plus que
      // ce que ses capacites disaient deja.
      return;
    }
    _dernierContenu = contenu;
    // Le presentateur lit son propre contenu par le meme flux que la classe :
    // un seul chemin de rendu, donc aucune divergence entre ce qu'il croit
    // montrer et ce qui est montre.
    if (!_contenus.isClosed) {
      _contenus.add(contenu);
    }
    await _envoyerContenu(contenu);
  }

  /// Republie le contenu courant apres une reconnexion, si l'on presente.
  Future<void> _republierContenu() async {
    final ContenuPresente? contenu = _dernierContenu;
    if (contenu == null || !(_acces?.capacites.peutPublierDonnees ?? false)) {
      return;
    }
    await _envoyerContenu(contenu);
  }

  /// Pose le paquet sur le canal de donnees.
  ///
  /// `reliable` parce qu'une page perdue est une classe qui ne suit plus : le
  /// mode non fiable convient a un curseur qui bouge trente fois par seconde,
  /// pas a un tour de page qui arrive une fois par minute.
  Future<void> _envoyerContenu(ContenuPresente contenu) async {
    final lk.LocalParticipant? local = _salle?.localParticipant;
    if (local == null) {
      return;
    }
    try {
      await local.publishData(
        utf8.encode(jsonEncode(contenu.versJson())),
        reliable: true,
        topic: sujetContenuPresente,
      );
    } catch (e) {
      // Un paquet perdu n'interrompt pas un cours : l'enseignant tournera la
      // page a nouveau, et la reconnexion republie de toute facon.
      journalDev('contenu presente non publie : $e');
    }
  }

  @override
  Future<void> publierDonnees({
    required String sujet,
    required List<int> charge,
    required bool fiable,
    List<String> destinataires = const <String>[],
  }) async {
    final AccesSalle? acces = _acces;
    if (acces == null) {
      throw const EchecPublicationDonnees(MotifEchecPublication.horsSalle);
    }
    if (!acces.capacites.peutPublierDonnees) {
      throw const EchecPublicationDonnees(MotifEchecPublication.droitRefuse);
    }
    final lk.LocalParticipant? local = _salle?.localParticipant;
    if (local == null) {
      throw const EchecPublicationDonnees(MotifEchecPublication.horsSalle);
    }
    try {
      await local.publishData(
        charge,
        reliable: fiable,
        topic: sujetSurLeReseau(sujet, fiable: fiable),
        destinationIdentities: destinataires.isEmpty ? null : destinataires,
      );
    } catch (e) {
      throw EchecPublicationDonnees(MotifEchecPublication.transport, '$e');
    }
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

    final bool mauvais =
        lien == QualiteLien.mediocre || lien == QualiteLien.perdue;

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

  String? _erreurCameraEntree;

  @override
  String? get erreurCameraEntree => _erreurCameraEntree;

  /// Pose un refus de camera sans navigateur (tests).
  @visibleForTesting
  set erreurCameraEntreePourTest(String? erreur) =>
      _erreurCameraEntree = erreur;

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
    _erreurCameraEntree = null;
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
    for (final lk.RemoteParticipant distant
        in salle.remoteParticipants.values) {
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
  Widget? renduVideo(String identite) {
    final lk.Room? salle = _salle;
    if (salle == null) {
      return null;
    }

    final lk.Participant? qui = _participant(salle, identite);
    if (qui == null) {
      return null;
    }

    // Une publication coupee garde sa piste : sans le test de `muted`, une
    // camera fermee afficherait sa derniere image figee, ce qui est pire
    // qu'un fond vide -- l'usager croirait etre vu.
    for (final lk.TrackPublication<lk.Track> publication
        in qui.videoTrackPublications) {
      final lk.Track? piste = publication.track;
      if (piste is lk.VideoTrack && !publication.muted) {
        // `cover` et non `contain` : une vignette de visage doit remplir son
        // cadre. Le miroir reste sur `auto`, qui retourne la seule image
        // locale -- se voir a l'envers de son miroir est desorientant.
        return lk.VideoTrackRenderer(piste, fit: lk.VideoViewFit.cover);
      }
    }
    return null;
  }

  /// Retrouve un participant par son identite, soi-meme comprise.
  lk.Participant? _participant(lk.Room salle, String identite) {
    final lk.LocalParticipant? moi = salle.localParticipant;
    if (moi != null && moi.identity == identite) {
      return moi;
    }
    for (final lk.RemoteParticipant autre in salle.remoteParticipants.values) {
      if (autre.identity == identite) {
        return autre;
      }
    }
    return null;
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
        journalDev('deconnexion imparfaite : $e');
      }
      await salle.dispose();
    }

    _acces = null;
    _degradee = false;
    _cameraAvantDegradation = false;
    // Le refus de camera ne vaut que pour la seance ou il a eu lieu (revue de
    // la PR 54) : le moteur vit toute l'application, et `rejoindre` passe par
    // ici avant chaque entree.
    _erreurCameraEntree = null;
    // **Ici, et seulement ici.** Quitter est un acte volontaire : la seance est
    // finie pour soi. Une deconnexion, elle, laisse le contenu en place --
    // c'est toute la difference entre « la seance est terminee » et « le
    // reseau a lache ».
    _dernierContenu = null;
    _poser(EtatSalle.absent);
  }

  @override
  Future<void> liberer() async {
    await quitter();
    await _etats.close();
    await _participants.close();
    await _qualite.close();
    await _contenus.close();
    await _donnees.close();
  }
}

/// Le moteur temps reel de l'application.
///
/// **Un seul pour tout le produit, et c'est delibere** : une seance a lieu dans
/// une salle a la fois (ADR-010 refuse deja un profil present dans deux
/// seances). Deux moteurs vivants doubleraient l'audio sans qu'aucune erreur ne
/// s'affiche, le pire des defauts possibles ici.
///
/// Il vit aussi longtemps que l'application, et c'est sans danger : hors salle
/// il ne detient ni piste, ni rendu, ni ecouteur -- `quitter()` les libere
/// tous. Les ecrans, eux, s'abonnent et se desabonnent.
///
/// Ce provider vit dans ce fichier parce que le construire ailleurs
/// demanderait d'importer `LiveKitSessionProvider` depuis un second endroit, et
/// c'est precisement le nombre d'endroits qui compte : un seul, verifiable d'un
/// `grep`.
final Provider<VideoSessionProvider> moteurSalleProvider =
    Provider<VideoSessionProvider>((Ref ref) {
      final LiveKitSessionProvider moteur = LiveKitSessionProvider();
      ref.onDispose(() => unawaited(moteur.liberer()));
      return moteur;
    });
