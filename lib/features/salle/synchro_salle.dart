// S1 (24/10/2026, plan de nuit du pilote) : la synchronisation reelle de la
// salle. Ce que l'enseignant ecrit sur la page arrive chez chaque eleve.
//
// Rien de neuf, tout est raccorde : le transport est
// [AdaptateurTransportLiveKit] (canal de donnees du seul moteur de la salle),
// le protocole [ServiceRealtimePedagogique], l'emission [DiffusionOutils],
// la reception [ReceptionOutils], le depot [AnnotationsMemoire] que la surface
// relit deja (`notesDeposeesProvider`). Aucune table : les traits vivent le
// temps de la seance, sur chaque appareil.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset;

import '../../core/observabilite/journal_dev.dart';
import '../../core/observabilite/supervision.dart';
import '../../core/tc_classe/port_rappel_discret.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/evenements_outils.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_outils/reception_outils.dart';
import '../../core/tc_realtime/adaptateur_transport_livekit.dart';
import '../../core/tc_realtime/port_realtime_pedagogique.dart';
import '../../core/tc_realtime/service_realtime_pedagogique.dart';
import '../../core/tc_realtime/types_message.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/video/video_session_provider.dart';
import '../salle_seance/relais_salle.dart';

/// S1 : le type du message du pointeur de l'enseignant (point normalise de
/// la page, canal ephemere). `EvenementPointeur` porte une position dans le
/// texte, pas un point de la page : il reste tel quel.
const String typePointeurSalle = 'tc.salle.pointeur';

/// S0.3 : le type du message qui ouvre ou ferme le tableau blanc pour la
/// classe (canal fiable).
const String typeTableauSalle = 'tc.salle.tableau';

/// Salle en groupe (30/10/2026) : le type du message qui donne la parole a
/// un eleve, ou la reprend (canal fiable). La charge porte le profil de
/// l'eleve, qui est son identite dans la salle, et son prenom.
const String typeParoleSalle = 'tc.salle.parole';

/// FN-018 : ce que fait la synchronisation d'une erreur de l'un de ses flux
/// ([flux] : pointeur, fiable, page, participants).
typedef SignalErreurSynchro = void Function(String flux, Object erreur);

/// FN-018 : la voie par defaut, journal de developpement et supervision. Le
/// signalement ne porte que le nom du flux et le type de l'erreur, jamais
/// d'identite ni de contenu.
void signalerErreurSynchro(String flux, Object erreur) {
  journalDev('synchronisation de la salle, flux $flux : ${erreur.runtimeType}');
  Supervision.signaler(
    categorie: 'salle',
    message: 'Synchronisation de la salle : flux en erreur',
    donnees: <String, Object?>{'flux': flux, 'type': '${erreur.runtimeType}'},
  );
}

/// L'eleve qui a la parole, tel que la classe le recoit.
@immutable
class ParoleSalle {
  /// Cree une parole.
  const ParoleSalle({required this.profilId, required this.prenom});

  /// Son profil, qui est son identite dans la salle.
  final String profilId;

  /// Son prenom, dit par l'enseignant.
  final String prenom;

  @override
  bool operator ==(Object other) =>
      other is ParoleSalle &&
      other.profilId == profilId &&
      other.prenom == prenom;

  @override
  int get hashCode => Object.hash(profilId, prenom);
}

/// Les pieces de la synchronisation d'une seance, creees a l'entree dans la
/// salle et liberees a la sortie.
class SynchroSalle {
  /// Raccorde la salle [sessionId] au moteur, pour le profil [profilLocalId].
  factory SynchroSalle({
    required VideoSessionProvider moteur,
    required AccesSalle acces,
    required String sessionId,
    required String profilLocalId,
    SignalErreurSynchro signalerErreur = signalerErreurSynchro,
  }) {
    final AdaptateurTransportLiveKit transport = AdaptateurTransportLiveKit(
      moteur: moteur,
      acces: acces,
      profilLocalId: profilLocalId,
    );
    final ServiceRealtimePedagogique realtime = ServiceRealtimePedagogique(
      transport,
    );
    final AnnotationsMemoire depot = AnnotationsMemoire(profilLocalId);
    return SynchroSalle._(
      sessionId: sessionId,
      transport: transport,
      depot: depot,
      diffusion: DiffusionOutils(
        realtime,
        sessionId: sessionId,
        emetteurProfilId: profilLocalId,
      ),
      reception: ReceptionOutils(
        realtime,
        sessionId: sessionId,
        profilLocalId: profilLocalId,
        depot: depot,
      ),
      realtime: realtime,
      moteur: moteur,
      profilLocalId: profilLocalId,
      peutDiffuser: acces.capacites.peutPublierDonnees,
      signalerErreur: signalerErreur,
    );
  }

  SynchroSalle._({
    required this.sessionId,
    required this.depot,
    required this._transport,
    required this._diffusion,
    required this._reception,
    required this._realtime,
    required VideoSessionProvider moteur,
    required this.profilLocalId,
    required this._peutDiffuser,
    required SignalErreurSynchro signalerErreur,
  }) : _moteur = moteur {
    // FN-018 : une erreur d'un flux ne passe plus en silence ; elle est
    // journalisee et dite a la supervision, comme la veille de fraicheur.
    void Function(Object) erreurDe(String flux) =>
        (Object erreur) => signalerErreur(flux, erreur);
    _abonnementPointeur = _realtime
        .messagesEphemeres(sessionId)
        .listen(_recevoirPointeur, onError: erreurDe('pointeur'));
    _abonnementTableau = _realtime.messagesFiables(sessionId).listen((
      MessagePedagogique m,
    ) {
      _recevoirPointeur(m);
      _recevoirTableau(m);
      _recevoirParole(m);
      _recevoirRappel(m);
    }, onError: erreurDe('fiable'));
    if (_peutDiffuser) {
      _abonnementPage = moteur.contenusPresentes.listen(
        (ContenuPresente page) => _pagePresentee = page.estRetire ? null : page,
        onError: erreurDe('page'),
      );
      _abonnementArrivees = moteur.participants.listen(
        _accueillir,
        onError: erreurDe('participants'),
      );
    }
  }

  final VideoSessionProvider _moteur;
  StreamSubscription<ContenuPresente>? _abonnementPage;
  StreamSubscription<List<ParticipantSalle>>? _abonnementArrivees;

  /// La page que l'enseignant presente (il la lit par le meme flux que la
  /// classe), ou `null`.
  ContenuPresente? _pagePresentee;

  /// L'etat du tableau que l'enseignant a diffuse en dernier.
  bool _tableauDiffuse = false;

  /// SYNCHRO-SESSION : le tableau que cet appareil a ouvert pour la classe
  /// (enseignant) ; la page rouverte le reprend.
  bool get tableauDiffuse => _tableauDiffuse;

  /// Les participants vus a la derniere liste, hors soi.
  Set<String> _presents = const <String>{};

  /// Le rejeu (retour du pilote, 24/10) : LiveKit ne garde aucun paquet, un
  /// eleve qui entre apres un tour de page, l'ouverture du tableau ou un
  /// trait ne recevait rien. Quand quelqu'un arrive (ou revient), l'appareil
  /// de l'enseignant renvoie a la classe l'etat courant : la page, le
  /// tableau, puis chaque trait de son depot. La reception ignore ce qu'elle
  /// a deja (meme identifiant de trait, meme page), donc ceux qui etaient la
  /// ne voient rien changer.
  void _accueillir(List<ParticipantSalle> liste) {
    final Set<String> presents = <String>{
      for (final ParticipantSalle p in liste)
        if (!p.estLocal) p.identite,
    };
    final bool arrivee = presents.difference(_presents).isNotEmpty;
    _presents = presents;
    if (arrivee) rejouer();
  }

  /// Renvoie a la classe la page, le tableau et les traits de la seance
  /// (enseignant seulement).
  @visibleForTesting
  void rejouer() {
    if (!_peutDiffuser) return;
    final ContenuPresente? page = _pagePresentee;
    if (page != null) {
      unawaited(
        _moteur
            .presenterContenu(page)
            .catchError((Object e) => journalDev('page non rejouee : $e')),
      );
    }
    if (_tableauDiffuse) diffuserTableau(ouvert: true);
    if (parole.value case final ParoleSalle p) diffuserParole(p);
    for (final AnnotationLayer couche in depot.couches.toList()) {
      for (final TraitVectoriel trait in couche.traits) {
        diffuser!(
          EvenementTraitTermine(
            coucheId: couche.id,
            trait: trait,
            portee: couche.portee,
          ),
        );
      }
    }
  }

  late final StreamSubscription<MessagePedagogique> _abonnementTableau;

  /// S0.3 : le tableau blanc ouvert par l'enseignant, tel que la classe le
  /// recoit.
  final ValueNotifier<bool> tableauOuvert = ValueNotifier<bool>(false);

  void _recevoirTableau(MessagePedagogique message) {
    if (message.type != typeTableauSalle ||
        message.emetteurProfilId == profilLocalId) {
      return;
    }
    tableauOuvert.value = message.charge['ouvert'] == true;
  }

  /// S0.3 : ouvre ou ferme le tableau pour la classe (enseignant).
  void diffuserTableau({required bool ouvert}) {
    if (!_peutDiffuser) return;
    _tableauDiffuse = ouvert;
    unawaited(
      _realtime
          .emettre(
            MessagePedagogique(
              type: typeTableauSalle,
              sessionId: sessionId,
              emetteurProfilId: profilLocalId,
              charge: <String, dynamic>{'ouvert': ouvert},
              emisLeUtc: DateTime.now().toUtc(),
            ),
            canal: CanalFiabilite.fiable,
          )
          .catchError((Object e) => journalDev('tableau non diffuse : $e')),
    );
  }

  /// Salle en groupe (30/10/2026) : l'eleve qui a la parole, chez tous
  /// (l'enseignant le pose, la classe le recoit), ou `null`.
  final ValueNotifier<ParoleSalle?> parole = ValueNotifier<ParoleSalle?>(null);

  void _recevoirParole(MessagePedagogique message) {
    if (message.type != typeParoleSalle ||
        message.emetteurProfilId == profilLocalId) {
      return;
    }
    final Object? profil = message.charge['profil'];
    final Object? prenom = message.charge['prenom'];
    parole.value = profil is String && profil.isNotEmpty
        ? ParoleSalle(profilId: profil, prenom: prenom is String ? prenom : '')
        : null;
  }

  /// Donne la parole a un eleve pour toute la classe, ou la reprend avec
  /// `null` (enseignant). Ce message ne fait qu'afficher : il n'ouvre ni ne
  /// coupe aucun micro. La fermeture des micros des camarades pendant une
  /// recitation est posee par le serveur (`faireReciter`, droits de la
  /// salle), pas par ce message.
  void diffuserParole(ParoleSalle? eleve) {
    if (!_peutDiffuser) return;
    parole.value = eleve;
    unawaited(
      _realtime
          .emettre(
            MessagePedagogique(
              type: typeParoleSalle,
              sessionId: sessionId,
              emetteurProfilId: profilLocalId,
              charge: eleve == null
                  ? const <String, dynamic>{}
                  : <String, dynamic>{
                      'profil': eleve.profilId,
                      'prenom': eleve.prenom,
                    },
              emisLeUtc: DateTime.now().toUtc(),
            ),
            canal: CanalFiabilite.fiable,
          )
          .catchError((Object e) => journalDev('parole non diffusee : $e')),
    );
  }

  /// Le rappel discret (30/10/2026) : le nombre de rappels recus par cet
  /// appareil. Le paquet est adresse au seul eleve vise (`emettreCible`) :
  /// le recevoir, c'est etre appele. Aucun accuse ne repart.
  final ValueNotifier<int> rappelsRecus = ValueNotifier<int>(0);

  void _recevoirRappel(MessagePedagogique message) {
    // DYNAMIQUE-CHRONO-2 : la meme lecture que la salle reduite.
    if (!estRappelPour(message, profilLocalId)) return;
    rappelsRecus.value++;
  }

  /// Appelle discretement l'eleve [academyId], dont l'identite dans la salle
  /// est [profilCible] : un paquet fiable adresse a lui seul. Leve
  /// [EchecRappel] quand le jeton n'a pas le canal ; une erreur d'envoi
  /// remonte telle quelle (la cadence la nomme). Le cooldown reste celui de
  /// `RappelDiscretCadence`.
  Future<void> emettreRappel({
    required String academyId,
    required String profilCible,
  }) async {
    if (!_peutDiffuser) {
      throw const EchecRappel(MotifEchecRappel.droitRefuse);
    }
    await _realtime.emettreCible(
      messageRappelDiscret(
        sessionId: sessionId,
        emetteurProfilId: profilLocalId,
        academyId: academyId,
        maintenantUtc: DateTime.now(),
      ),
      destinataireProfilId: profilCible,
      canal: CanalFiabilite.fiable,
    );
  }

  /// Le profil de cet appareil.
  final String profilLocalId;

  final ServiceRealtimePedagogique _realtime;
  late final StreamSubscription<MessagePedagogique> _abonnementPointeur;

  /// Le pointeur de l'enseignant tel que la classe le recoit (point
  /// normalise de la page), `null` quand il se leve.
  final ValueNotifier<Offset?> pointeurDistant = ValueNotifier<Offset?>(null);

  /// GESTES-POINTEUR : le dernier lever recu et la derniere position retenue
  /// (heure d'emission, et heure de reception sur cet appareil). Le canal du
  /// pointeur ne garantit ni la livraison ni l'ordre : une position emise
  /// avant le dernier lever, ou avant la position deja affichee, est ecartee.
  /// La regle ne vaut que le temps d'une peremption : passe ce delai, tout
  /// paquet est accepte (un enseignant revenu sur un autre appareil, dont
  /// l'horloge retarde, n'est jamais ignore).
  ({DateTime emis, DateTime recu})? _dernierLever;
  ({DateTime emis, DateTime recu})? _dernierePosition;

  /// GESTES-POINTEUR : sans nouvelle pendant [AppMouvement.pointeurPerime],
  /// le pointeur s'efface seul (un lever perdu ne le laisse jamais fige).
  Timer? _peremptionPointeur;

  bool _recent(({DateTime emis, DateTime recu})? repere, DateTime maintenant) =>
      repere != null &&
      maintenant.difference(repere.recu) < AppMouvement.pointeurPerime;

  void _recevoirPointeur(MessagePedagogique message) {
    if (message.type != typePointeurSalle ||
        message.emetteurProfilId == profilLocalId) {
      return;
    }
    final num? x = message.charge['x'] as num?;
    final num? y = message.charge['y'] as num?;
    final DateTime emis = message.emisLeUtc;
    final DateTime maintenant = DateTime.now();
    final ({DateTime emis, DateTime recu})? lever = _dernierLever;
    final ({DateTime emis, DateTime recu})? position = _dernierePosition;
    if (x == null || y == null) {
      _dernierLever = (emis: emis, recu: maintenant);
      // Le lever part sur les deux canaux : le second exemplaire, arrive
      // apres une nouvelle position, ne doit pas l'effacer.
      if (_recent(position, maintenant) && position!.emis.isAfter(emis)) {
        return;
      }
      _peremptionPointeur?.cancel();
      pointeurDistant.value = null;
      return;
    }
    if ((_recent(lever, maintenant) && !emis.isAfter(lever!.emis)) ||
        (_recent(position, maintenant) && emis.isBefore(position!.emis))) {
      return;
    }
    _dernierePosition = (emis: emis, recu: maintenant);
    pointeurDistant.value = Offset(
      x.toDouble().clamp(0, 1),
      y.toDouble().clamp(0, 1),
    );
    _peremptionPointeur?.cancel();
    _peremptionPointeur = Timer(AppMouvement.pointeurPerime, () {
      pointeurDistant.value = null;
    });
  }

  /// L'heure d'emission d'un paquet du pointeur : strictement croissante sur
  /// cet appareil, pour que l'ordre se lise meme a deux paquets dans la meme
  /// milliseconde.
  DateTime _heurePointeur() {
    DateTime maintenant = DateTime.now().toUtc();
    final DateTime? dernier = _derniereEmissionPointeur;
    if (dernier != null && !maintenant.isAfter(dernier)) {
      maintenant = DateTime.fromMillisecondsSinceEpoch(
        dernier.millisecondsSinceEpoch + 1,
        isUtc: true,
      );
    }
    return _derniereEmissionPointeur = maintenant;
  }

  DateTime? _derniereEmissionPointeur;

  Future<void> _emettrePointeur(Offset? point, CanalFiabilite canal) =>
      _realtime
          .emettre(
            MessagePedagogique(
              type: typePointeurSalle,
              sessionId: sessionId,
              emetteurProfilId: profilLocalId,
              charge: point == null
                  ? const <String, dynamic>{}
                  : <String, dynamic>{'x': point.dx, 'y': point.dy},
              emisLeUtc: _heurePointeur(),
            ),
            canal: canal,
          )
          .catchError((Object e) => journalDev('pointeur non diffuse : $e'));

  /// Le rappel de `diffusionPointeurProvider`.
  ///
  /// Une position part sur le canal ephemere : pas de retransmission, pas de
  /// file, seule la derniere compte (la cadence est celle de
  /// `CadencePointeur`). Le lever (`null`) part **sur les deux canaux** :
  /// l'ephemere pour arriver tout de suite, le fiable pour arriver a coup
  /// sur. Un lever perdu laissait le pointeur fige chez l'eleve (defaut P-1).
  void Function(Offset?)? get diffuserPointeur => _peutDiffuser
      ? (Offset? point) {
          unawaited(_emettrePointeur(point, CanalFiabilite.ephemere));
          if (point == null) {
            unawaited(_emettrePointeur(null, CanalFiabilite.fiable));
          }
        }
      : null;

  /// La seance synchronisee.
  final String sessionId;

  /// Le depot local de la seance, que la surface relit.
  final AnnotationsMemoire depot;

  final AdaptateurTransportLiveKit _transport;
  final DiffusionOutils _diffusion;
  final ReceptionOutils _reception;
  final bool _peutDiffuser;

  /// Le rappel de `diffusionEcritureProvider` : l'evenement part a la classe
  /// (enseignant, jeton `can_publish_data`) ; un echec se journalise, le trait
  /// reste chez son auteur et la surface le marque non partage (TB-11b).
  void Function(EvenementOutil)? get diffuser => _peutDiffuser
      ? (EvenementOutil evenement) => unawaited(
          _diffusion
              .emettre(evenement)
              .catchError(
                (Object e) => journalDev('ecriture non diffusee : $e'),
              ),
        )
      : null;

  /// Libere la reception et le transport.
  @mustCallSuper
  Future<void> liberer() async {
    _peremptionPointeur?.cancel();
    // SYNCHRO-SESSION : tout se coupe tout de suite (la seance vit avec
    // l'appel : a sa fin, plus rien ne doit ecouter le moteur), puis on
    // attend que chaque fin soit faite.
    final List<Future<void>> fins = <Future<void>>[
      _abonnementPointeur.cancel(),
      _abonnementTableau.cancel(),
      ?_abonnementPage?.cancel(),
      ?_abonnementArrivees?.cancel(),
      _reception.liberer(),
    ];
    pointeurDistant.dispose();
    tableauOuvert.dispose();
    parole.dispose();
    rappelsRecus.dispose();
    await Future.wait(fins);
    await _transport.liberer();
  }
}
