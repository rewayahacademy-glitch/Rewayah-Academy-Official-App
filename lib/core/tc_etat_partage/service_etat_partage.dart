import 'dart:async';

import 'package:flutter/foundation.dart';

import '../tc_realtime/port_realtime_pedagogique.dart';
import '../tc_realtime/port_transport_donnees.dart';
import '../tc_realtime/types_message.dart';
import 'codec_etat_partage.dart';
import 'port_etat_partage.dart';
import 'port_etat_partage_persistant.dart';
import 'reducteur_etat_partage.dart';
import 'shared_content_state.dart';

/// L'etat partage d'une seance : le flux, la publication, la restauration.
///
/// **C'est ici que l'exigence centrale du lot F se tient** : un arrivant tardif
/// ou une reconnexion recupere l'etat COURANT sans dependre de l'historique des
/// messages realtime (spec ligne 1200). Trois mecanismes concourent, et aucun
/// n'est un rejeu de journal :
///
/// 1. **Le backend fait autorite sur le contenu.** [restaurer] lit
///    `PortEtatPartagePersistant`, jamais un tampon de paquets. LiveKit
///    transporte, il ne conserve rien -- le socle le dit deja en clair
///    (`LiveKitSessionProvider._republierContenu`).
/// 2. **Chaque message fiable porte l'etat ENTIER a sa revision**, jamais un
///    delta. Recevoir la revision 9 sans avoir vu 6, 7 ni 8 suffit : 9 est un
///    etat complet. C'est ce qui rend l'historique inutile.
/// 3. **La revision, et elle seule, ordonne.** `ReducteurEtatPartage` refuse
///    toute revision inferieure ou egale a la courante, qu'elle vienne du
///    reseau ou du backend. Duplicata, paquet hors ordre et lecture servie par
///    une replique en retard sont trois noms pour la meme situation.
///
/// ## L'ordre des deux ecritures de [publier]
///
/// **Le backend d'abord, la diffusion ensuite.** L'ordre est porteur
/// d'information, exactement comme `annoncerSortie` avant `quitter()` dans la
/// salle existante :
///
/// - backend puis diffusion : si la diffusion echoue, les connectes sont en
///   retard d'une revision **mais un arrivant tardif obtient la bonne**, et la
///   revision suivante les remet a jour ;
/// - diffusion puis backend : si l'ecriture echoue, les connectes voient un
///   etat qu'aucun arrivant ne verra jamais. La classe diverge en silence.
///
/// Le second cas est le seul des deux qui produise deux verites. On prend le
/// premier.
class ServiceEtatPartage implements PortEtatPartage {
  /// Cree le service pour un transport donne.
  ///
  /// [etatsTransport] est le flux d'etat du transport, pris **a part** du
  /// protocole : `PortRealtimePedagogique` est le contrat canonique de
  /// CONTRACTS section 9 et ne porte pas d'etat de connexion. Lui en ajouter un
  /// ferait diverger le stub d'Agent D du canonique, ce que le controle
  /// pre-merge traite en BLOCKER.
  ServiceEtatPartage({
    required this._realtime,
    required this._persistance,
    required this._etatsTransport,
  });

  final PortRealtimePedagogique _realtime;
  final PortEtatPartagePersistant _persistance;
  final Stream<EtatTransport> _etatsTransport;

  /// Un reducteur par seance : c'est lui qui detient la revision courante.
  final Map<String, ReducteurEtatPartage> _reducteurs =
      <String, ReducteurEtatPartage>{};

  /// Les abonnements ouverts, par seance, pour pouvoir les fermer.
  final Map<String, List<StreamSubscription<Object?>>> _abonnements =
      <String, List<StreamSubscription<Object?>>>{};

  /// **Un seul canal de sortie pour toutes les seances**, filtre a la lecture.
  ///
  /// Une carte de controleurs aurait demande une fermeture par seance, donc un
  /// endroit de plus ou en oublier une. `SharedContentState` porte deja son
  /// `sessionId` : le filtre coute une comparaison de chaines par revision, et
  /// une revision arrive quelques fois par minute.
  final StreamController<SharedContentState> _diffusion =
      StreamController<SharedContentState>.broadcast();

  @override
  Future<SharedContentState?> etatCourant(String sessionId) async {
    final SharedContentState? connu = _reducteur(sessionId).etat;
    if (connu != null) {
      return connu;
    }
    // Rien en memoire : c'est exactement le cas de l'arrivee tardive. On lit le
    // backend, une fois, et on repart de la.
    return restaurer(sessionId);
  }

  @override
  Stream<SharedContentState> suivre(String sessionId) {
    late final StreamController<SharedContentState> sortie;
    StreamSubscription<SharedContentState>? amont;
    // Monotonie garantie **par abonne** : un abonnement qui vient de naitre ne
    // doit jamais voir la classe reculer, meme si sa lecture de depart croise
    // une revision plus recente arrivee entre-temps.
    int dernierRendu = -1;

    void relayer(SharedContentState etat) {
      if (sortie.isClosed || etat.revision <= dernierRendu) {
        return;
      }
      dernierRendu = etat.revision;
      sortie.add(etat);
    }

    sortie = StreamController<SharedContentState>(
      onListen: () {
        _brancher(sessionId);
        // On s'abonne AVANT de lire l'etat de depart : une revision qui arrive
        // pendant la lecture du backend est alors relayee, pas perdue.
        amont = _diffusion.stream
            .where((SharedContentState e) => e.sessionId == sessionId)
            // Le flux se termine quand le service est libere -- pas avant.
            .listen(relayer, onDone: sortie.close);
        unawaited(
          _demarrer(sessionId, relayer, (Object e, StackTrace pile) {
            if (!sortie.isClosed) {
              sortie.addError(e, pile);
            }
          }),
        );
      },
      // **Annuler l'amont, sans fermer la sortie ici.** Mesure faite :
      // `close()` appele depuis `onCancel` rend un futur qui n'aboutit qu'une
      // fois `onCancel` termine, et l'attendre bloque indefiniment. Une Classe
      // Live quittee ne se fermerait jamais.
      onCancel: () => amont?.cancel(),
    );
    return sortie.stream;
  }

  /// Lit l'etat de depart et le relaie, ou fait remonter l'echec a l'abonne.
  ///
  /// **L'echec de restauration se DIT.** « Rien n'est presente » et « je n'ai
  /// pas pu lire » conduisent a deux ecrans differents, et le second a son
  /// libelle (`t.tc.realtime.etat.restauration_impossible`). Laisser l'erreur
  /// s'echapper d'un `unawaited` la rendrait invisible a l'ecran et bruyante
  /// dans la zone.
  ///
  /// TC-Z-SUIVI : ce libelle, comme
  /// `t.tc.realtime.transport.partage_indisponible`, n'est encore affiche par
  /// aucun ecran de la Classe Live -- le lot F les a produits pour que E les
  /// pose dans sa coque, mais E ne l'a pas fait. A cabler avant Etape 8.
  Future<void> _demarrer(
    String sessionId,
    void Function(SharedContentState) relayer,
    void Function(Object, StackTrace) enEchec,
  ) async {
    try {
      final SharedContentState? depart = await etatCourant(sessionId);
      if (depart != null) {
        relayer(depart);
      }
    } catch (e, pile) {
      enEchec(e, pile);
    }
  }

  @override
  Future<void> publier(SharedContentState etat) async {
    final ReducteurEtatPartage reducteur = _reducteur(etat.sessionId);
    final SharedContentState? precedent = reducteur.etat;
    if (etat.revision <= reducteur.revisionCourante) {
      // La course perdue est un cas normal, pas une panne : l'appelant relit
      // l'etat courant et repart de la. `SharedContentState.suivante()` lui
      // interdit de choisir lui-meme un numero, c'est donc qu'il travaillait
      // sur un etat perime.
      throw EchecEtatPartage(
        MotifEchecEtatPartage.revisionObsolete,
        revisionStockee: reducteur.revisionCourante,
      );
    }

    // 1. Le durable. Il peut refuser : la monotonie y est une contrainte
    //    serveur, pas une convention entre clients.
    final SharedContentState stocke = await _persistance.enregistrer(etat);

    // 2. Les abonnes locaux, par le meme chemin que les recepteurs distants :
    //    un seul chemin de rendu, donc aucune divergence possible entre ce que
    //    l'enseignant croit montrer et ce que la classe voit. Le transport ne
    //    relivre pas ses propres paquets a l'emetteur, c'est donc ici que cela
    //    se fait.
    reducteur.appliquer(stocke);
    _diffuser(stocke);

    // 3. Les autres appareils. Un echec ici laisse l'etat durable EN PLACE :
    //    les connectes sont en retard d'une revision, un arrivant tardif a la
    //    bonne, et une reconnexion les resynchronise. On leve malgre tout --
    //    un appelant qui croirait avoir diffuse est ce qu'on veut eviter.
    await _realtime.emettre(
      _messageRevision(stocke, _causeDe(precedent, stocke)),
      canal: CanalFiabilite.fiable,
    );
  }

  @override
  Future<SharedContentState?> restaurer(String sessionId) async {
    final SharedContentState? depuisBackend = await _persistance.lire(
      sessionId,
    );
    final ReducteurEtatPartage reducteur = _reducteur(sessionId);
    final ResultatRevision suite = reducteur.restaurer(depuisBackend);
    if (suite.aChange && suite.etat != null) {
      _diffuser(suite.etat!);
    }
    return reducteur.etat;
  }

  /// Ferme tous les abonnements et le flux de sortie.
  ///
  /// Appele a la **sortie volontaire** de la classe, jamais a une deconnexion :
  /// c'est la distinction que le socle tient deja entre `quitter()` et une
  /// coupure reseau, et l'oublier ferait perdre l'etat pedagogique a chaque
  /// passage sous un tunnel.
  Future<void> liberer() async {
    for (final List<StreamSubscription<Object?>> abonnements
        in _abonnements.values) {
      for (final StreamSubscription<Object?> a in abonnements) {
        await a.cancel();
      }
    }
    _abonnements.clear();
    _reducteurs.clear();
    await _diffusion.close();
  }

  ReducteurEtatPartage _reducteur(String sessionId) => _reducteurs.putIfAbsent(
    sessionId,
    () => ReducteurEtatPartage(sessionId: sessionId),
  );

  void _diffuser(SharedContentState etat) {
    if (!_diffusion.isClosed) {
      _diffusion.add(etat);
    }
  }

  /// Branche les deux sources d'une seance, une seule fois.
  void _brancher(String sessionId) {
    if (_abonnements.containsKey(sessionId)) {
      return;
    }
    _abonnements[sessionId] = <StreamSubscription<Object?>>[
      _realtime.messagesFiables(sessionId).listen((MessagePedagogique m) {
        if (m.type != typeRevisionEtatPartage) {
          return;
        }
        final SharedContentState? candidat = etatDepuisJson(m.charge);
        // Un etat illisible -- charge tronquee, mode d'affichage inconnu d'une
        // version plus ancienne -- garde l'etat courant. Il ne fait jamais
        // basculer la classe dans un mode qu'elle n'a pas demande.
        if (candidat == null) {
          return;
        }
        final ResultatRevision suite = _reducteur(sessionId)
            .appliquer(candidat);
        if (suite.aChange && suite.etat != null) {
          _diffuser(suite.etat!);
        }
      }),
      // **Le seul declencheur de restauration, et il est nomme.** Le socle
      // distingue deja `retabli` de `connecte` pour cette raison exacte : sans
      // lui, un retour de coupure serait indiscernable d'une premiere
      // connexion. `instable` n'en est pas un : la seance continue.
      _etatsTransport
          .where((EtatTransport e) => e == EtatTransport.retabli)
          .listen((_) {
            // L'echec d'une restauration apres reconnexion remonte aux abonnes
            // plutot que de s'echapper d'un `unawaited`. Le lien vient de revenir :
            // la revision suivante remettra la classe a jour de toute facon, mais
            // l'ecran doit pouvoir dire qu'il ne sait pas ou en est le cours.
            unawaited(
              restaurer(sessionId).catchError((Object e, StackTrace pile) {
                if (!_diffusion.isClosed) {
                  _diffusion.addError(e, pile);
                }
                return null;
              }),
            );
          }),
    ];
  }

  MessagePedagogique _messageRevision(
    SharedContentState etat,
    CauseRevision cause,
  ) => MessagePedagogique(
    type: typeRevisionEtatPartage,
    sessionId: etat.sessionId,
    emetteurProfilId: etat.updatedBy,
    charge: <String, dynamic>{...etatVersJson(etat), 'cause': cause.valeurSql},
    emisLeUtc: etat.updatedAtUtc,
  );
}

/// Deduit ce qui a motive une revision, en comparant les deux etats.
///
/// **Informatif, jamais decisionnel.** L'etat transporte est complet : un
/// recepteur qui ignorerait la cause resterait correct. Elle est deduite plutot
/// que demandee a l'appelant parce que `PortEtatPartage.publier` ne prend qu'un
/// etat (CONTRACTS section 9) : lui ajouter un parametre ferait diverger le
/// stub des consommateurs du contrat canonique.
///
/// [CauseRevision.restauration] est le repli quand rien de visible n'a change :
/// une revision poussee sans difference est une republication.
@visibleForTesting
CauseRevision causeDeRevision(
  SharedContentState? avant,
  SharedContentState apres,
) => _causeDe(avant, apres);

CauseRevision _causeDe(SharedContentState? avant, SharedContentState apres) {
  if (avant == null ||
      avant.resourceId != apres.resourceId ||
      avant.resourceVersionId != apres.resourceVersionId) {
    return CauseRevision.support;
  }
  if (avant.displayMode != apres.displayMode) {
    return CauseRevision.mode;
  }
  if (avant.contentPosition != apres.contentPosition) {
    return CauseRevision.position;
  }
  if (avant.contentRange != apres.contentRange) {
    return CauseRevision.plage;
  }
  if (!listEquals(avant.hiddenRanges, apres.hiddenRanges)) {
    return CauseRevision.masquage;
  }
  if (!listEquals(avant.semanticMarkers, apres.semanticMarkers)) {
    return CauseRevision.marqueurs;
  }
  if (avant.groupResumePosition != apres.groupResumePosition) {
    return CauseRevision.reprise;
  }
  return CauseRevision.restauration;
}
