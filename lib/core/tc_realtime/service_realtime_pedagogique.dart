import 'dart:async';
import 'dart:collection';

import 'codec_message_pedagogique.dart';
import 'port_realtime_pedagogique.dart';
import 'port_transport_donnees.dart';
import 'types_message.dart';

/// Le protocole pedagogique pose au-dessus d'un transport quelconque.
///
/// **C'est le coeur du lot F, et il ne connait pas LiveKit.** Il ne voit qu'un
/// [PortTransportDonnees] : deux canaux, un sujet, des octets, des
/// destinataires. C'est ce qui permet de le prouver entierement sans SDK
/// (`TransportMemoire`), de le brancher partiellement sur le moteur existant
/// (`AdaptateurTransportLiveKit`), et de le brancher completement le jour ou le
/// socle aura la primitive demandee dans `TC_CONTRACT_REQUEST_F.md` -- **sans
/// qu'une ligne de ce fichier change**.
///
/// ## La separation des canaux, qui est la raison d'etre du lot
///
/// Elle n'est pas une preference : elle est **structurelle**, et elle se lit
/// dans trois differences de traitement.
///
/// | | [messagesFiables] | [messagesEphemeres] |
/// |---|---|---|
/// | Ce qui y passe | support, position, plage, mode, eleve actif, trait termine, rappel | pointeur, apercu de trait |
/// | Doublon | **ecarte** | laisse passer |
/// | Perte | interdite (le transport garantit) | **acceptee** |
/// | Memoire tenue | empreintes des derniers messages | aucune |
///
/// Un paquet de pointeur ne doit **jamais** emprunter le canal fiable : trente
/// paquets par seconde avec garantie de livraison encombreraient le canal qui
/// porte les tours de page, et la mission nomme cela une faute.
///
/// ## Ce que ce service ne fait pas
///
/// Il n'**ordonne** rien. L'ordre de l'etat partage est porte par
/// `SharedContentState.revision` et tranche par `ReducteurEtatPartage` : un
/// transport n'a pas a connaitre la semantique de ce qu'il porte, et le jour ou
/// Agent D ajoutera un type, aucune ligne d'ici ne changera.
class ServiceRealtimePedagogique implements PortRealtimePedagogique {
  /// Cree le protocole au-dessus d'un transport.
  ///
  /// Le transport est positionnel, comme les trente et un services du depot qui
  /// prennent leur client en premier argument.
  ServiceRealtimePedagogique(this._transport);

  final PortTransportDonnees _transport;

  @override
  Stream<MessagePedagogique> messagesFiables(String sessionId) =>
      _lire(sessionId, CanalFiabilite.fiable, ecarterDoublons: true);

  @override
  Stream<MessagePedagogique> messagesEphemeres(String sessionId) =>
      _lire(sessionId, CanalFiabilite.ephemere, ecarterDoublons: false);

  /// Le filtrage commun aux deux canaux.
  ///
  /// La memoire des doublons est **creee ici, donc par abonnement** : deux
  /// ecrans qui suivent la meme seance ne se volent pas leurs messages. Un
  /// filtre partage entre abonnes ferait disparaitre un message chez le second
  /// parce que le premier l'a deja vu.
  ///
  /// **Un controleur explicite, et non un generateur `async*`.** Mesure faite :
  /// un `async*` suspendu dans un `await for` sur un flux qui ne livre rien ne
  /// peut pas etre annule -- l'annulation attend que le generateur reprenne, ce
  /// qui n'arrive jamais. Une Classe Live quittee pendant un silence resterait
  /// bloquee a la fermeture. Le socle a fait la meme decouverte pour la
  /// presence : le commentaire de `presenceSeanceProvider` documente une boucle
  /// `async*` qui continuait a tourner apres la sortie de salle.
  Stream<MessagePedagogique> _lire(
    String sessionId,
    CanalFiabilite canal, {
    required bool ecarterDoublons,
  }) {
    final _MemoireDoublons vus = _MemoireDoublons();
    late final StreamController<MessagePedagogique> sortie;
    StreamSubscription<PaquetRealtime>? amont;

    void recevoir(PaquetRealtime paquet) {
      // Le sujet d'abord : le canal de donnees porte aussi `contenu-presente`,
      // le protocole coranique du socle. Un recepteur qui ne filtrerait pas
      // lirait un paquet etranger comme un ordre pedagogique.
      if (paquet.sujet != sujetProtocolePedagogique || paquet.canal != canal) {
        return;
      }
      final MessagePedagogique? message = messageDepuisOctets(paquet.charge);
      // Un paquet illisible ne casse rien : il vient d'une version
      // d'application qu'on ne controle pas.
      if (message == null || message.sessionId != sessionId) {
        return;
      }
      if (ecarterDoublons && !vus.retenir(empreinteMessage(message))) {
        return;
      }
      if (!sortie.isClosed) {
        sortie.add(message);
      }
    }

    sortie = StreamController<MessagePedagogique>(
      onListen: () {
        // `onDone` ferme la sortie quand le transport se ferme : c'est ce qui
        // termine proprement le flux a la sortie de salle.
        amont = _transport.paquets().listen(recevoir, onDone: sortie.close);
      },
      onCancel: () => amont?.cancel(),
    );
    return sortie.stream;
  }

  @override
  Future<void> emettre(
    MessagePedagogique message, {
    required CanalFiabilite canal,
  }) => _transport.envoyer(
    sujet: sujetProtocolePedagogique,
    charge: messageVersOctets(message),
    canal: canal,
  );

  @override
  Future<void> emettreCible(
    MessagePedagogique message, {
    required String destinataireProfilId,
    required CanalFiabilite canal,
  }) => _transport.envoyer(
    sujet: sujetProtocolePedagogique,
    charge: messageVersOctets(message),
    canal: canal,
    destinataires: <String>[destinataireProfilId],
  );

  /// Les capacites projetees pour l'appelant.
  ///
  /// **Aucune des quatre valeurs n'est decidee ici.** Elles derivent des
  /// drapeaux que `autoriser_jeton_video()` a calcules en base et que
  /// `create-room-token` a signes -- jamais d'un role lu cote client.
  ///
  /// [sessionId] n'est pas consulte, et c'est volontaire : un transport sert
  /// **une** salle, celle dont le jeton a ete emis, et projeter les capacites
  /// d'une autre seance depuis ce jeton-la n'aurait aucun sens. Le parametre
  /// reste pour respecter le contrat canonique (CONTRACTS section 9) et pour
  /// que l'implementation serveur a venir puisse, elle, l'utiliser.
  ///
  /// **La disponibilite du transport entre dans le calcul.** Annoncer
  /// « peut piloter le support » sur un transport qui n'a pas de primitive
  /// d'envoi ferait afficher a Agent E des commandes qui ne font rien -- une
  /// classe qui ne suit pas sans qu'aucun message ne le dise. On declare le
  /// manque, on ne fabrique pas une capacite qu'on n'a pas.
  @override
  Future<CapacitesPedagogiques> capacites(String sessionId) async {
    final CapacitesTransport? signees = _transport.capacites;
    if (signees == null) {
      // `null` n'est pas « tout est permis » : c'est « aucun droit connu ».
      return const CapacitesPedagogiques(
        peutPiloterSupport: false,
        peutAnnoter: false,
        peutEmettreNudge: false,
        estObservateurSilencieux: true,
      );
    }
    final bool peutEmettre =
        signees.peutPublierDonnees &&
        _transport.disponibilite == DisponibiliteTransport.complet;
    return CapacitesPedagogiques(
      peutPiloterSupport: peutEmettre,
      peutAnnoter: peutEmettre,
      peutEmettreNudge: peutEmettre,
      // Invisible dans la liste, ou sans droit de publier quoi que ce soit :
      // tuteur, controleur, admin incognito. L'admin qui « rejoint la classe »
      // publie sa voix, il n'est donc pas silencieux (decision D-15).
      estObservateurSilencieux: signees.invisible || !signees.peutPublier,
    );
  }
}

/// La memoire des messages deja rendus, pour ecarter un paquet livre deux fois.
///
/// ponytail: fenetre glissante de [_plafond] empreintes, jamais un journal
/// complet. Plafond connu : un duplicata qui arriverait apres [_plafond] autres
/// messages fiables passerait. Pour un canal qui porte des tours de page et des
/// rappels -- de l'ordre de quelques messages par minute -- cela represente des
/// heures. Voie de sortie si cela ne suffisait plus : un numero de sequence
/// dans l'enveloppe, ce qui demande un amendement du contrat, pas une astuce
/// locale.
class _MemoireDoublons {
  static const int _plafond = 256;

  final Set<String> _vus = <String>{};
  final Queue<String> _ordre = Queue<String>();

  /// Retient une empreinte. Rend `false` si elle etait deja connue.
  bool retenir(String empreinte) {
    if (!_vus.add(empreinte)) {
      return false;
    }
    _ordre.add(empreinte);
    if (_ordre.length > _plafond) {
      _vus.remove(_ordre.removeFirst());
    }
    return true;
  }
}
