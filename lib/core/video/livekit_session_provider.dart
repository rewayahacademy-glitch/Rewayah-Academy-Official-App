import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../observabilite/journal_dev.dart';
import 'diagnostic_transport.dart';
import 'publication_differee.dart';
import 'repli_audio.dart';
import 'service_video.dart';
import 'video_session_provider.dart';

/// Le debit maximal de la video publiee, en bits par seconde : 1,2 Mbit/s
/// pour une capture 720p. Mesure LiveKit du test K4 du directeur du
/// 26/10/2026 (relais TURN des deux cotes, UDP bloque) : la capture 360p du
/// 25/10 n'avait rien gagne sur le retard et degradait l'image ; le 720p de
/// D15 (24/10/2026) est retabli, les couches basses servent les liens
/// faibles.
const int debitMaxVideo = 1200000;

/// Le nombre d'images par seconde maximal de la video publiee (D15, retabli
/// le 26/10/2026).
const int imagesParSecondeMax = 30;

/// Les reglages de la salle pour les reseaux faibles (decision du directeur
/// du 25/10/2026, audit reseau, `docs/current/maquettes/salle/LOT-3-2026-10-25.md`
/// section 7) : capture 720p (retablie le 26/10/2026) en simulcast avec deux
/// couches basses (180p et 360p) pour les liens faibles, 1,2 Mbit/s et 30
/// images par seconde au plus, resolution maintenue quand le reseau
/// faiblit ; `adaptiveStream`
/// pour TOUS les roles (D15 du 24/10/2026, qui le reservait a l'enseignant,
/// est revu le 25/10/2026) et `dynacast`. Micro et camera restent fermes a
/// l'entree : ces reglages ne publient rien.
///
/// **Les defauts de capture audio sont conserves volontairement.** La
/// specification section 18 met en garde : une configuration « musicale »
/// desactive l'annulation d'echo, la suppression de bruit et le gain
/// automatique. Pour de la recitation, ou l'intelligibilite prime sur la
/// fidelite, ce serait un contresens.
///
/// **Voix, revue le 11/11/2026 (cahier de la salle §5, mesures dans
/// `docs/current/salle/MESURES-VOIX.md`).** Trois reglages changent, chacun
/// mesure sur une vraie seance sous pertes :
///
/// - la redondance audio (RED, RFC 2198) est **reellement** active : chaque
///   paquet porte aussi le son du precedent, donc un paquet perdu isole ne
///   s'entend plus. Elle etait demandee (`red: true`) mais jamais obtenue :
///   voir [redPourLeSdk]. Elle ne repare pas deux paquets perdus de suite :
///   sous des pertes en rafales, des mots tombent encore (defaut V-3) ;
/// - 32 kbit/s au lieu de 24 : la recitation porte des consonnes sifflantes
///   et emphatiques que le codec rabote a bas debit ; avec la redondance, la
///   voix coute environ 70 kbit/s, moins que la plus petite couche video ;
/// - plus de DTX : il coupe l'emission pendant les silences et peut rogner
///   l'attaque du mot qui suit. Une recitation ne se rogne pas.
///
/// La voix passe aussi devant la video pour le debit (`bitratePriority`).
lk.RoomOptions optionsSalle() => const lk.RoomOptions(
  adaptiveStream: true,
  dynacast: true,
  defaultAudioCaptureOptions: lk.AudioCaptureOptions(),
  defaultAudioPublishOptions: lk.AudioPublishOptions(
    encoding: lk.AudioEncoding(
      maxBitrate: debitVoix,
      bitratePriority: lk.Priority.high,
      networkPriority: lk.Priority.high,
    ),
    dtx: false,
    red: redPourLeSdk,
  ),
  defaultCameraCaptureOptions: lk.CameraCaptureOptions(
    params: lk.VideoParametersPresets.h720_169,
  ),
  defaultVideoPublishOptions: lk.VideoPublishOptions(
    simulcast: true,
    videoEncoding: lk.VideoEncoding(
      maxBitrate: debitMaxVideo,
      maxFramerate: imagesParSecondeMax,
    ),
    videoSimulcastLayers: <lk.VideoParameters>[
      lk.VideoParametersPresets.h180_169,
      lk.VideoParametersPresets.h360_169,
    ],
    degradationPreference: lk.DegradationPreference.maintainResolution,
  ),
);

/// Le debit de la voix, en bit/s (hors redondance).
const int debitVoix = 32000;

/// Ce qu'il faut passer a `AudioPublishOptions.red` pour que la redondance
/// audio soit **active**.
///
/// `livekit_client` 2.12.0 inverse ce drapeau : il envoie au serveur
/// `disableRed: publishOptions.red ?? true` (`participant/local.dart`, ligne
/// 190). `red: true` y **desactive** donc la redondance, et la valeur par
/// defaut du SDK aussi. Mesure du 11/11/2026 sur de vraies seances
/// (`docs/current/salle/MESURES-VOIX.md`) : avec `true`, l'auditeur recoit
/// 23 kbit/s et le navigateur reconstruit 6 a 7 % du son sous 10 a 20 % de
/// pertes isolees ; avec `false`, il recoit 67 kbit/s (la voix et sa
/// redondance) et n'en reconstruit plus que 0,1 a 0,2 %.
///
/// Le jour ou le SDK corrige l'inversion, cette constante repasse a `true`,
/// et `tool/salle/mesure_voix.mjs` se rejoue : le debit recu le dit.
const bool redPourLeSdk = false;

/// Vrai quand la camera s'allume d'elle-meme a l'entree : **jamais**, pour
/// aucun role (decision du directeur du 25/10/2026, lot salle 3 §1.1, apres
/// le test K4 : la camera d'un compte enfant s'allumait seule). La camera est
/// fermee a l'entree comme le micro ; un appui volontaire l'allume. Remplace
/// l'exception D14 du 24/10/2026 (eleve dont le tuteur autorisait l'image).
/// [acces] reste en parametre : la regle se lit par role dans les tests.
bool cameraAllumeeALEntree(AccesSalle acces) => false;

/// ECRAN-EVEILLE (directeur, 11/11/2026) : les attentes entre deux essais de
/// reprise sans geste, apres que le SDK a epuise les siens. Environ 30
/// secondes au total : au-dela, la salle dit « connexion perdue » et propose
/// « Reessayer », comme avant. Une page cachee qui epuise ces essais attend
/// son retour au premier plan et recommence, au lieu d'abandonner.
const List<Duration> delaisRepriseSansGeste = <Duration>[
  Duration.zero,
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 16),
];

/// Marge sous laquelle un jeton est tenu pour expire : LiveKit le refuserait
/// pendant la connexion.
const Duration margeJetonReprise = Duration(seconds: 30);

/// Vrai quand une deconnexion non voulue peut se reprendre sans geste.
///
/// Seulement les coupures du transport (reseau, signalisation, essais du SDK
/// epuises, serveur qui redemarre). **Jamais** une decision : participant
/// retire par l'enseignant, salle fermee ou supprimee, meme compte ouvert
/// ailleurs, sortie voulue. Reprendre la, ce serait rentrer contre la
/// decision du serveur.
bool repriseSansGestePermise(lk.DisconnectReason? raison) => switch (raison) {
  null ||
  lk.DisconnectReason.unknown ||
  lk.DisconnectReason.disconnected ||
  lk.DisconnectReason.signalingConnectionFailure ||
  lk.DisconnectReason.reconnectAttemptsExceeded ||
  lk.DisconnectReason.signalClose ||
  lk.DisconnectReason.serverShutdown ||
  lk.DisconnectReason.stateMismatch ||
  lk.DisconnectReason.migration ||
  lk.DisconnectReason.joinFailure => true,
  _ => false,
};

/// Ce qu'une reprise rouvre : **seulement ce que la personne avait ouvert**,
/// seulement avec le droit du serveur, et seulement si c'est ferme
/// maintenant. Rien n'est jamais ferme ici : ce calcul ne fait que rendre.
///
/// - micro : voulu ouvert, droit de publier (jeton ET permission courante du
///   serveur), et ferme maintenant (piste perdue avec la coupure, ou arretee
///   par le systeme pendant la veille) ;
/// - camera : de meme, sauf en « audio seul » ou pendant un repli du reseau,
///   qui la rendra lui-meme a son heure.
({bool micro, bool camera}) mediasARestaurer({
  required bool microVoulu,
  required bool cameraVoulue,
  required bool peutPublier,
  required bool peutPublierVideo,
  required bool microOuvert,
  required bool cameraOuverte,
  required bool audioSeul,
  required bool repliActif,
}) => (
  micro: microVoulu && peutPublier && !microOuvert,
  camera:
      cameraVoulue &&
      peutPublierVideo &&
      !cameraOuverte &&
      !audioSeul &&
      !repliActif,
);

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
class LiveKitSessionProvider
    implements
        VideoSessionProvider,
        MotifEchecSalle,
        RepriseAutomatique,
        DroitsPublicationVivants {
  /// Cree le fournisseur. [retablirPublication] est l'appel au serveur du
  /// filet de MICRO-AVANT-ENSEIGNANT ([FiletPublication]) ; sans lui, seul le
  /// webhook du serveur rend ses droits a l'eleve.
  LiveKitSessionProvider({
    Future<void> Function(AccesSalle acces)? retablirPublication,
  }) : _filetPublication = FiletPublication(
         retablirPublication ?? (AccesSalle _) async {},
       );

  /// MICRO-AVANT-ENSEIGNANT (11/11/2026) : voir [_permissionsChangees].
  final FiletPublication _filetPublication;
  final StreamController<AccesSalle> _accesMisAJour =
      StreamController<AccesSalle>.broadcast();

  @override
  Stream<AccesSalle> get accesMisAJour => _accesMisAJour.stream;

  /// MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026) : le serveur change les
  /// droits de publication du participant local (il les rend a l'eleve quand
  /// son enseignant entre). Les capacites lues par les ecrans suivent ce que
  /// LiveKit accorde ; rien ne s'ouvre seul : le micro reste ferme tant que
  /// l'eleve ne l'ouvre pas lui-meme.
  void _permissionsChangees(lk.ParticipantPermissionsUpdatedEvent e) {
    if (e.participant is! lk.LocalParticipant) {
      return;
    }
    _accorderAuxPermissions(e.permissions);
  }

  /// Aligne l'acces lu par les ecrans sur ce que LiveKit accorde vraiment au
  /// participant local ([p]) : a chaque changement annonce par le serveur, et
  /// apres une reprise sans geste (ECRAN-EVEILLE), ou la salle est rouverte
  /// avec le jeton de l'entree, qui peut etre un jeton differe alors que le
  /// droit avait ete rendu depuis.
  ///
  /// Quand le droit de publier est la, le micro et la camera **voulus** avant
  /// une coupure sont rendus ([_restaurerMedias]) : rien ne s'ouvre que la
  /// personne n'avait ouvert elle-meme dans cette seance.
  void _accorderAuxPermissions(lk.ParticipantPermissions p) {
    final AccesSalle? acces = _acces;
    if (acces == null) {
      return;
    }
    final AccesSalle? neuf = accesApresPermissions(
      acces,
      peutPublier: p.canPublish,
      // Sans liste de sources, LiveKit autorise toutes les sources.
      camera:
          p.canPublish &&
          (p.canPublishSources.isEmpty ||
              p.canPublishSources.any((s) => s.name == 'CAMERA')),
    );
    if (neuf != null) {
      _acces = neuf;
      if (!_accesMisAJour.isClosed) {
        _accesMisAJour.add(neuf);
      }
      _publierParticipants();
    }
    if (p.canPublish) {
      unawaited(_restaurerMedias());
    }
  }

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

  /// Le repli audio seul, avec hysteresis (lot salle 3, 25/10/2026).
  final RepliAudio _repli = RepliAudio();

  /// Le battement du repli (11/11/2026) : voir [_battreRepli].
  Timer? _battementRepli;

  /// ECRAN-EVEILLE (11/11/2026) : le micro que la personne a voulu ouvert.
  ///
  /// Pose par [reglerMicro] (son geste), remis a faux quand le serveur coupe
  /// ce micro (geste « couper le micro » de l'enseignant) et a la sortie.
  /// C'est ce qu'une reprise rend, et rien d'autre : un micro ferme par la
  /// personne n'est jamais rouvert. La camera a deja sa memoire,
  /// [_cameraAvantDegradation].
  bool _microVoulu = false;

  /// La source d'un jeton neuf pour une reprise sans geste
  /// ([RepriseAutomatique.sourceJeton]).
  Future<AccesSalle> Function()? _sourceJeton;

  /// Change a chaque sortie : une reprise en route se tait si la salle a ete
  /// quittee ou rejointe a nouveau entre-temps.
  int _generation = 0;

  bool _repriseEnCours = false;

  /// Vrai quand l'application est au premier plan (voir [premierPlan]).
  bool _auPremierPlan = true;

  /// Reveille une reprise qui attend entre deux essais.
  Completer<void>? _reveil;

  /// Le diagnostic du transport de l'entree en cours (lot salle 3).
  DiagnosticTransport? _diagnostic;

  /// La derniere qualite du lien local, pour ne relire le transport qu'aux
  /// changements.
  QualiteLien? _dernierLien;

  @override
  EtatSalle get etatCourant => _etat;

  @override
  Stream<EtatSalle> get etats => _etats.stream;

  /// La derniere liste publiee, rendue a tout nouvel abonne.
  List<ParticipantSalle>? _derniersParticipants;

  @override
  Stream<List<ParticipantSalle>> get participants async* {
    // Meme regle que [contenusPresentes] (31/10/2026) : la salle rouverte
    // depuis la barre « Seance toujours en direct » doit retrouver qui est
    // la et si son micro est ouvert, sans attendre le prochain evenement.
    final List<ParticipantSalle>? derniers = _derniersParticipants;
    if (derniers != null) {
      yield derniers;
    }
    yield* _participants.stream;
  }

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

  bool _ouverteAilleurs = false;

  /// Ce que devient la salle apres une deconnexion non voulue, selon la
  /// raison donnee par LiveKit. UX-038 : le meme compte a ouvert la salle
  /// ailleurs ; l'etat reste `echec`, le motif le dit a la salle.
  @visibleForTesting
  static ({EtatSalle etat, bool ailleurs}) issueDeconnexion(
    lk.DisconnectReason? raison,
  ) => (
    etat: switch (raison) {
      lk.DisconnectReason.clientInitiated => EtatSalle.absent,
      // 30/10/2026 : l'enseignant a fait sortir ce participant.
      lk.DisconnectReason.participantRemoved => EtatSalle.retire,
      _ => EtatSalle.echec,
    },
    ailleurs: raison == lk.DisconnectReason.duplicateIdentity,
  );

  @override
  bool get ouverteAilleurs => _ouverteAilleurs;

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
    _ouverteAilleurs = false;
    _poser(EtatSalle.connexion);

    // `RoomOptions` se pose au CONSTRUCTEUR : le passer a `connect()` est
    // deprecie depuis livekit_client 2.x et sera ignore un jour.
    final lk.Room salle = lk.Room(roomOptions: optionsSalle());
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
    // est retiree le 25/10/2026 par le directeur (lot salle 3 §1.1) : **aucune
    // activation de camera n'est tentee a l'entree**, pour aucun role et sur
    // aucun appareil (l'essai sur un poste sans camera faisait naitre le
    // bandeau « Aucune camera n'est trouvee »). [cameraAllumeeALEntree] le dit.
    _poser(EtatSalle.connecte);
    // Lot salle 3 (audit reseau du 25/10/2026) : le diagnostic du transport,
    // sans identite (nom de salle opaque), rien de visible en salle.
    final DiagnosticTransport diagnostic = DiagnosticTransport(
      salleOpaque: acces.nomSalle,
    );
    _diagnostic = diagnostic;
    unawaited(diagnostic.lireTransports(salle, 'connexion'));
    _battementRepli?.cancel();
    _battementRepli = Timer.periodic(
      RepliAudio.intervalleBattement,
      (Timer _) => unawaited(_battreRepli()),
    );
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
        // ECRAN-EVEILLE : une piste perdue pendant la coupure est rendue.
        unawaited(_restaurerMedias());
      })
      ..on<lk.RoomDisconnectedEvent>((lk.RoomDisconnectedEvent e) {
        // Lot salle 3 (audit reseau du 25/10/2026) : `quitter` cesse
        // d'ecouter avant de fermer ; une deconnexion recue ici n'est donc
        // pas voulue (reseau, serveur, salle fermee). Elle passe en echec
        // avec sa raison : la salle dit « La connexion au cours est
        // perdue » et propose « Reessayer » (nouveau jeton), jamais un ecran
        // « Connexion » fige.
        final lk.DisconnectReason? raison = e.reason;
        signalerTransport('deconnexion', <String, Object?>{
          'salle': _acces?.nomSalle,
          'raison': raison?.name ?? 'inconnue',
        });
        final ({EtatSalle etat, bool ailleurs}) issue = issueDeconnexion(
          raison,
        );
        _ouverteAilleurs = issue.ailleurs;
        // ECRAN-EVEILLE (11/11/2026) : le SDK a epuise ses propres essais
        // (une dizaine, environ 45 secondes), souvent parce que l'ecran
        // s'est eteint. Avant de dire « connexion perdue », le moteur
        // reprend lui-meme l'appel, sans geste ([_reprendreSansGeste]).
        if (issue.etat == EtatSalle.echec &&
            repriseSansGestePermise(raison) &&
            _acces != null) {
          _poser(EtatSalle.reconnexion);
          unawaited(_reprendreSansGeste());
          return;
        }
        _poser(issue.etat);
        _publierParticipants();
      })
      ..on<lk.ParticipantConnectedEvent>((_) => _publierParticipants())
      ..on<lk.ParticipantDisconnectedEvent>((_) => _publierParticipants())
      ..on<lk.TrackPublishedEvent>((_) => _publierParticipants())
      ..on<lk.TrackUnpublishedEvent>((_) => _publierParticipants())
      ..on<lk.TrackSubscribedEvent>((lk.TrackSubscribedEvent e) {
        _diagnostic?.suivrePiste(e.track);
        _publierParticipants();
      })
      ..on<lk.TrackUnsubscribedEvent>((_) => _publierParticipants())
      ..on<lk.LocalTrackPublishedEvent>((lk.LocalTrackPublishedEvent e) {
        final lk.Track? piste = e.publication.track;
        if (piste != null) _diagnostic?.suivrePiste(piste);
        _publierParticipants();
      })
      ..on<lk.TrackMutedEvent>((lk.TrackMutedEvent e) {
        _retenirCoupure(e);
        _publierParticipants();
      })
      ..on<lk.TrackUnmutedEvent>((_) => _publierParticipants())
      ..on<lk.ActiveSpeakersChangedEvent>((_) => _publierParticipants())
      ..on<lk.DataReceivedEvent>(_recevoirDonnees)
      ..on<lk.ParticipantPermissionsUpdatedEvent>(_permissionsChangees)
      ..on<lk.ParticipantConnectionQualityUpdatedEvent>((
        lk.ParticipantConnectionQualityUpdatedEvent e,
      ) {
        if (e.participant.identity == _salle?.localParticipant?.identity) {
          final QualiteLien lien = _traduireQualite(e.connectionQuality);
          // Lot salle 3 : le transport se relit a chaque changement de
          // qualite (paire de candidats, aller-retour, pertes).
          final lk.Room? salle = _salle;
          if (salle != null && lien != _dernierLien) {
            _dernierLien = lien;
            unawaited(
              _diagnostic?.lireTransports(salle, 'qualite:${lien.name}'),
            );
          }
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
  ///
  /// Lot salle 3 (audit reseau du 25/10/2026, decision du pilote) : repli en
  /// deux paliers avec hysteresis ([RepliAudio]). Lien mediocre : videos
  /// recues en couche basse, camera locale coupee. Lien perdu : videos recues
  /// desabonnees (seule la voix circule). Retour apres deux bonnes mesures
  /// consecutives, jamais sur une seule : pas de clignotement. Un « audio
  /// seul » demande par l'usager ([reglerAudioSeul]) prime : on n'y touche
  /// pas.
  Future<void> _degrader(QualiteLien lien) async {
    final NiveauRepli avant = _repli.niveau;
    final NiveauRepli apres = _repli.mesurer(lien);
    await _appliquerRepli(avant, apres);
  }

  /// Le battement du repli : tant que l'image est suspendue, la derniere
  /// qualite connue est rejouee, sinon un lien redevenu bon et stable ne
  /// ramenerait jamais l'image (voir [RepliAudio]).
  Future<void> _battreRepli() async {
    if (!_repli.videoSuspendue) {
      return;
    }
    final NiveauRepli avant = _repli.niveau;
    final NiveauRepli apres = _repli.battre();
    await _appliquerRepli(avant, apres);
  }

  Future<void> _appliquerRepli(NiveauRepli avant, NiveauRepli apres) async {
    if (avant == apres || _audioSeul) {
      return;
    }
    final lk.Room? salle = _salle;
    if (salle == null) {
      return;
    }
    final lk.LocalParticipant? local = salle.localParticipant;
    final bool peutMontrer = _acces?.capacites.peutPublierVideo ?? false;

    // La camera locale : coupee des le premier palier, rouverte au retour
    // seulement si elle etait ouverte (une camera fermee par l'usager le
    // reste).
    if (local != null && peutMontrer) {
      if (avant == NiveauRepli.aucun) {
        _cameraAvantDegradation = local.isCameraEnabled();
        if (_cameraAvantDegradation) {
          await local.setCameraEnabled(false);
        }
      } else if (apres == NiveauRepli.aucun && _cameraAvantDegradation) {
        await local.setCameraEnabled(true);
      }
    }

    // Les videos recues : couche basse, puis plus rien, puis le retour.
    for (final lk.RemoteParticipant distant
        in salle.remoteParticipants.values) {
      for (final lk.RemoteTrackPublication<lk.RemoteVideoTrack> piste
          in distant.videoTrackPublications) {
        switch (apres) {
          case NiveauRepli.audioSeul:
            await piste.unsubscribe();
          case NiveauRepli.videoBasse:
            await piste.subscribe();
            await piste.setVideoQuality(lk.VideoQuality.LOW);
          case NiveauRepli.aucun:
            await piste.subscribe();
            await piste.setVideoQuality(lk.VideoQuality.HIGH);
        }
      }
    }
    journalDev('salle : repli ${avant.name} -> ${apres.name}');
    _publierParticipants();
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
        // Directeur, 26/10/2026 : le jeton ne porte aucun nom ; l'identite
        // (le profil) n'est jamais un nom a afficher. L'annuaire de la
        // seance nomme la personne.
        nom: p.name,
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
    _derniersParticipants = liste;
    _participants.add(liste);
    // MICRO-AVANT-ENSEIGNANT : l'enseignant est la et mon droit est encore
    // ferme ? Le filet le redemande au serveur.
    _filetPublication.observer(
      acces: _acces,
      enseignantPresent: enseignantDansLaSalle(liste),
    );
  }

  @override
  Future<void> reglerMicro({required bool actif}) async {
    final lk.LocalParticipant? local = _salle?.localParticipant;
    if (local == null || !(_acces?.capacites.peutPublier ?? false)) {
      return;
    }
    try {
      await local.setMicrophoneEnabled(actif);
    } catch (e) {
      // SITUATIONS-GRAVES (11/11/2026) : le navigateur refuse le micro
      // (permission, micro pris, aucun micro). Rien n'est ouvert : la
      // reprise ne doit pas le retenter seule, et l'ecran nomme la cause.
      if (actif) _microVoulu = false;
      _publierParticipants();
      rethrow;
    }
    // ECRAN-EVEILLE : le geste fait foi pour toute reprise a venir.
    _microVoulu = actif;
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

  // ---------------------------------------------------------------------
  // ECRAN-EVEILLE (directeur, 11/11/2026) : reprise sans geste.
  // ---------------------------------------------------------------------

  @override
  set sourceJeton(Future<AccesSalle> Function()? source) =>
      _sourceJeton = source;

  @override
  void premierPlan({required bool visible}) {
    _auPremierPlan = visible;
    if (!visible) {
      // Rien n'est coupe en arriere-plan : ni micro, ni son recu, ni
      // connexion. Le navigateur peut suspendre la camera ; la voix, non.
      return;
    }
    _reveiller();
    unawaited(_reprendreAuRetour());
  }

  void _reveiller() {
    final Completer<void>? reveil = _reveil;
    _reveil = null;
    if (reveil != null && !reveil.isCompleted) {
      reveil.complete();
    }
  }

  /// Attend [delai], ou le retour au premier plan s'il vient avant ; sans
  /// delai, attend seulement ce retour.
  Future<void> _attendre(Duration? delai) async {
    final Completer<void> reveil = Completer<void>();
    _reveil = reveil;
    final Timer? minuterie = delai == null
        ? null
        : Timer(delai, () {
            if (!reveil.isCompleted) reveil.complete();
          });
    await reveil.future;
    minuterie?.cancel();
    if (identical(_reveil, reveil)) _reveil = null;
  }

  /// Le serveur a coupe un micro ou une camera (geste de l'enseignant) :
  /// la reprise ne doit pas le rouvrir.
  ///
  /// Le SDK n'emet `TrackMutedEvent` pour une piste locale que sur une
  /// coupure demandee (par nous ou par le serveur), jamais quand le systeme
  /// arrete la piste pendant la veille (celle-la est depubliee). Nos propres
  /// coupures de camera pour le repli ou l'audio seul se reconnaissent a
  /// leur etat : elles ne touchent pas a la memoire.
  void _retenirCoupure(lk.TrackMutedEvent e) {
    if (e.participant is! lk.LocalParticipant) {
      return;
    }
    switch (e.publication.source) {
      case lk.TrackSource.microphone:
        _microVoulu = false;
      case lk.TrackSource.camera:
        if (_repli.niveau == NiveauRepli.aucun && !_audioSeul) {
          _cameraAvantDegradation = false;
        }
      default:
        break;
    }
  }

  /// Rend au micro et a la camera l'etat voulu ([mediasARestaurer]).
  Future<void> _restaurerMedias() async {
    final lk.LocalParticipant? local = _salle?.localParticipant;
    final AccesSalle? acces = _acces;
    if (local == null || acces == null) {
      return;
    }
    final bool serveurPermet = local.permissions.canPublish;
    final ({bool micro, bool camera}) aRouvrir = mediasARestaurer(
      microVoulu: _microVoulu,
      cameraVoulue: _cameraAvantDegradation,
      peutPublier: acces.capacites.peutPublier && serveurPermet,
      peutPublierVideo: acces.capacites.peutPublierVideo && serveurPermet,
      microOuvert: local.isMicrophoneEnabled(),
      cameraOuverte: local.isCameraEnabled(),
      audioSeul: _audioSeul,
      repliActif: _repli.niveau != NiveauRepli.aucun,
    );
    // Par les memes chemins que le geste ([reglerMicro], [reglerCamera]) :
    // un seul endroit ouvre le micro, et il relit le droit du jeton.
    try {
      if (aRouvrir.micro) {
        await reglerMicro(actif: aRouvrir.micro);
      }
      if (aRouvrir.camera) {
        await reglerCamera(actif: aRouvrir.camera);
      }
    } catch (e) {
      // Un micro que le navigateur refuse de rouvrir sans geste : le bouton
      // de la salle le dit (micro coupe), la personne le rouvre d'un appui.
      journalDev('reprise : micro ou camera non rouverts ($e)');
    }
    if (aRouvrir.micro || aRouvrir.camera) {
      journalDev(
        'reprise : micro ${aRouvrir.micro}, camera ${aRouvrir.camera} rendus',
      );
      _publierParticipants();
    }
  }

  /// Au retour au premier plan, l'appel encore ouvert : le son recu reprend,
  /// micro et camera retrouvent leur etat voulu, et une piste que le systeme
  /// a rendue muette pendant la veille (iPhone) est relancee.
  Future<void> _reprendreAuRetour() async {
    final lk.Room? salle = _salle;
    if (salle == null || _repriseEnCours) {
      return;
    }
    if (_etat != EtatSalle.connecte &&
        _etat != EtatSalle.retabli &&
        _etat != EtatSalle.instable) {
      // `reconnexion` : le SDK reprend deja ; la restauration suivra
      // `retabli` (voir le gestionnaire de `RoomReconnectedEvent`).
      return;
    }
    try {
      await salle.startAudio();
    } catch (e) {
      journalDev('reprise : son recu non relance ($e)');
    }
    await _restaurerMedias();
    await _relancerPistesMuettes();
  }

  /// Relance une piste locale encore publiee mais que le systeme a rendue
  /// muette (`MediaStreamTrack.muted`) pendant la veille.
  Future<void> _relancerPistesMuettes() async {
    final lk.LocalParticipant? local = _salle?.localParticipant;
    if (local == null) {
      return;
    }
    for (final lk.LocalTrackPublication<lk.LocalTrack> pub
        in local.trackPublications.values) {
      final lk.LocalTrack? piste = pub.track;
      if (piste == null || pub.muted) {
        continue;
      }
      final bool voulue = switch (pub.source) {
        lk.TrackSource.microphone => _microVoulu,
        lk.TrackSource.camera => _cameraAvantDegradation,
        _ => false,
      };
      if (!voulue || piste.mediaStreamTrack.muted != true) {
        continue;
      }
      try {
        await piste.restartTrack();
        journalDev('reprise : piste ${pub.source.name} relancee');
      } catch (e) {
        journalDev('reprise : piste ${pub.source.name} non relancee ($e)');
      }
    }
  }

  /// Le SDK a abandonne : le moteur rouvre lui-meme une salle, avec le meme
  /// jeton tant qu'il vaut, sinon un jeton neuf ([sourceJeton]). Le contenu
  /// presente, la memoire du micro et de la camera sont gardes. Apres
  /// [delaisRepriseSansGeste], et seulement alors, l'etat passe a `echec`
  /// et la salle propose « Reessayer ».
  Future<void> _reprendreSansGeste() async {
    if (_repriseEnCours) {
      return;
    }
    _repriseEnCours = true;
    final int generation = _generation;
    try {
      await _fermerSalleSeule();
      int essai = 0;
      while (generation == _generation) {
        if (essai >= delaisRepriseSansGeste.length) {
          if (_auPremierPlan) {
            break;
          }
          // Page cachee : on attend son retour, puis on recommence.
          await _attendre(null);
          essai = 0;
          continue;
        }
        await _attendre(delaisRepriseSansGeste[essai]);
        essai++;
        if (generation != _generation) {
          return;
        }
        final ({AccesSalle? acces, bool definitif}) jeton =
            await _jetonPourReprise();
        if (generation != _generation) {
          return;
        }
        if (jeton.definitif) {
          break;
        }
        final AccesSalle? acces = jeton.acces;
        if (acces != null && await _connecterSansGeste(acces, generation)) {
          return;
        }
      }
      if (generation == _generation) {
        journalDev('reprise sans geste abandonnee');
        _poser(EtatSalle.echec);
      }
    } finally {
      _repriseEnCours = false;
    }
  }

  /// Le jeton d'un essai : celui de l'entree s'il vaut encore, sinon un neuf.
  /// `definitif` quand le serveur refuse pour une autre raison que le reseau
  /// (seance close, acces retire) : on n'insiste pas.
  Future<({AccesSalle? acces, bool definitif})> _jetonPourReprise() async {
    final AccesSalle? courant = _acces;
    if (courant == null) {
      return (acces: null, definitif: true);
    }
    if (courant.expireLe.isAfter(DateTime.now().add(margeJetonReprise))) {
      return (acces: courant, definitif: false);
    }
    final Future<AccesSalle> Function()? source = _sourceJeton;
    if (source == null) {
      return (acces: null, definitif: true);
    }
    try {
      return (acces: await source(), definitif: false);
    } on EchecSalle catch (echec) {
      return (acces: null, definitif: echec.motif != MotifRefusSalle.reseau);
    } catch (e) {
      journalDev('reprise : jeton neuf impossible ($e)');
      return (acces: null, definitif: false);
    }
  }

  /// Ferme la salle tombee sans rien oublier de la seance (contenu, acces,
  /// memoire du micro) : ce n'est pas une sortie.
  Future<void> _fermerSalleSeule() async {
    _battementRepli?.cancel();
    _battementRepli = null;
    final lk.EventsListener<lk.RoomEvent>? ecouteur = _ecouteur;
    _ecouteur = null;
    await ecouteur?.dispose();
    final DiagnosticTransport? diagnostic = _diagnostic;
    _diagnostic = null;
    _dernierLien = null;
    await diagnostic?.arreter();
    final lk.Room? salle = _salle;
    _salle = null;
    if (salle != null) {
      try {
        await salle.disconnect();
      } catch (e) {
        journalDev('reprise : fermeture imparfaite : $e');
      }
      await salle.dispose();
    }
  }

  /// Un essai de reprise. Vrai quand l'appel est repris (ou que la salle a
  /// ete quittee entre-temps : il n'y a plus rien a reprendre).
  Future<bool> _connecterSansGeste(AccesSalle acces, int generation) async {
    final lk.Room salle = lk.Room(roomOptions: optionsSalle());
    try {
      await salle.connect(acces.urlServeur, acces.jeton);
    } catch (e) {
      journalDev('reprise : essai manque ($e)');
      await salle.dispose();
      return false;
    }
    if (generation != _generation) {
      try {
        await salle.disconnect();
      } catch (_) {
        // Deja fermee : rien a faire.
      }
      await salle.dispose();
      return true;
    }
    _salle = salle;
    _acces = acces;
    final lk.EventsListener<lk.RoomEvent> ecouteur = salle.createListener();
    _ecouteur = ecouteur;
    _brancher(ecouteur);
    // MICRO-AVANT-ENSEIGNANT : la salle rouverte dit ce que le serveur
    // accorde maintenant (le jeton de l'entree peut etre un jeton differe) ;
    // les ecrans le lisent, et le filet redemande le droit si l'enseignant
    // est la.
    if (salle.localParticipant case final lk.LocalParticipant moi) {
      _accorderAuxPermissions(moi.permissions);
    }
    _repli.remettre();
    final DiagnosticTransport diagnostic = DiagnosticTransport(
      salleOpaque: acces.nomSalle,
    );
    _diagnostic = diagnostic;
    unawaited(diagnostic.lireTransports(salle, 'reprise'));
    _battementRepli = Timer.periodic(
      RepliAudio.intervalleBattement,
      (Timer _) => unawaited(_battreRepli()),
    );
    // `retabli`, comme apres une reprise du SDK : la salle et la barre
    // « Seance toujours en direct » le lisent deja.
    _poser(EtatSalle.retabli);
    _publierParticipants();
    await _restaurerMedias();
    unawaited(_republierContenu());
    return true;
  }

  @override
  Future<void> quitter() async {
    // ECRAN-EVEILLE : une reprise en route se tait, et la memoire du micro
    // ne survit pas a la seance.
    _generation++;
    _microVoulu = false;
    _reveiller();
    _filetPublication.arreter();
    _battementRepli?.cancel();
    _battementRepli = null;
    // L'ordre compte : on cesse d'ecouter AVANT de fermer, sinon la fermeture
    // republie des etats dans des controleurs qu'on s'apprete a vider.
    final lk.EventsListener<lk.RoomEvent>? ecouteur = _ecouteur;
    _ecouteur = null;
    await ecouteur?.dispose();

    final DiagnosticTransport? diagnostic = _diagnostic;
    _diagnostic = null;
    _dernierLien = null;
    await diagnostic?.arreter();

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
    _derniersParticipants = null;
    _repli.remettre();
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
    await _accesMisAJour.close();
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
      final LiveKitSessionProvider moteur = LiveKitSessionProvider(
        // MICRO-AVANT-ENSEIGNANT : le filet passe par le service video, lu
        // au moment de l'appel (un test peut le remplacer).
        retablirPublication: (AccesSalle acces) async {
          final ServiceVideo service = ref.read(serviceVideoProvider);
          if (service case final RetablissementPublication filet) {
            await filet.retablirPublication(acces);
          }
        },
      );
      ref.onDispose(() => unawaited(moteur.liberer()));
      return moteur;
    });
