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
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/evenements_outils.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_outils/reception_outils.dart';
import '../../core/tc_realtime/adaptateur_transport_livekit.dart';
import '../../core/tc_realtime/port_realtime_pedagogique.dart';
import '../../core/tc_realtime/service_realtime_pedagogique.dart';
import '../../core/video/video_session_provider.dart';

/// S1 : le type du message du pointeur de l'enseignant (point normalise de
/// la page, canal ephemere). `EvenementPointeur` porte une position dans le
/// texte, pas un point de la page : il reste tel quel.
const String typePointeurSalle = 'tc.salle.pointeur';

/// S0.3 : le type du message qui ouvre ou ferme le tableau blanc pour la
/// classe (canal fiable).
const String typeTableauSalle = 'tc.salle.tableau';

/// Les pieces de la synchronisation d'une seance, creees a l'entree dans la
/// salle et liberees a la sortie.
class SynchroSalle {
  /// Raccorde la salle [sessionId] au moteur, pour le profil [profilLocalId].
  factory SynchroSalle({
    required VideoSessionProvider moteur,
    required AccesSalle acces,
    required String sessionId,
    required String profilLocalId,
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
  }) : _moteur = moteur {
    _abonnementPointeur = _realtime
        .messagesEphemeres(sessionId)
        .listen(_recevoirPointeur, onError: (Object _) {});
    _abonnementTableau = _realtime
        .messagesFiables(sessionId)
        .listen(_recevoirTableau, onError: (Object _) {});
    if (_peutDiffuser) {
      _abonnementPage = moteur.contenusPresentes.listen(
        (ContenuPresente page) =>
            _pagePresentee = page.estRetire ? null : page,
        onError: (Object _) {},
      );
      _abonnementArrivees = moteur.participants.listen(
        _accueillir,
        onError: (Object _) {},
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

  /// Le profil de cet appareil.
  final String profilLocalId;

  final ServiceRealtimePedagogique _realtime;
  late final StreamSubscription<MessagePedagogique> _abonnementPointeur;

  /// Le pointeur de l'enseignant tel que la classe le recoit (point
  /// normalise de la page), `null` quand il se leve.
  final ValueNotifier<Offset?> pointeurDistant = ValueNotifier<Offset?>(null);

  void _recevoirPointeur(MessagePedagogique message) {
    if (message.type != typePointeurSalle ||
        message.emetteurProfilId == profilLocalId) {
      return;
    }
    final num? x = message.charge['x'] as num?;
    final num? y = message.charge['y'] as num?;
    pointeurDistant.value = x == null || y == null
        ? null
        : Offset(x.toDouble().clamp(0, 1), y.toDouble().clamp(0, 1));
  }

  /// Le rappel de `diffusionPointeurProvider` : le point part a la classe
  /// sur le canal ephemere (perte acceptee, jamais conserve).
  void Function(Offset?)? get diffuserPointeur => _peutDiffuser
      ? (Offset? point) => unawaited(
          _realtime
              .emettre(
                MessagePedagogique(
                  type: typePointeurSalle,
                  sessionId: sessionId,
                  emetteurProfilId: profilLocalId,
                  charge: point == null
                      ? const <String, dynamic>{}
                      : <String, dynamic>{'x': point.dx, 'y': point.dy},
                  emisLeUtc: DateTime.now().toUtc(),
                ),
                canal: CanalFiabilite.ephemere,
              )
              .catchError(
                (Object e) => journalDev('pointeur non diffuse : $e'),
              ),
        )
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
    await _abonnementPointeur.cancel();
    await _abonnementTableau.cancel();
    await _abonnementPage?.cancel();
    await _abonnementArrivees?.cancel();
    pointeurDistant.dispose();
    tableauOuvert.dispose();
    await _reception.liberer();
    await _transport.liberer();
  }
}
