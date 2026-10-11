/// CAP29-G : relie le « Presenter » de la Bibliotheque en seance
/// (`BibliothequeSeance`, TB-8) au port du support actif.
///
/// Deux temps, comme le contrat TB-8 :
/// 1. le futur ne reussit que si la personne **a la capacite** de presenter
///    (lue sur le serveur, jamais deduite d'un role) ; sinon il echoue et la
///    classe garde le support d'avant ;
/// 2. l'activation rendue ne part qu'a l'appel : si l'enseignant a renonce
///    entre-temps, rien n'est presente. La reponse du serveur (refus, conflit
///    de revision, droits echus) est rangee dans [PresentationPort.dernier],
///    que la salle lit pour le dire.
///
/// La salle continue : aucun import de `core/video`, la connexion n'est pas
/// touchee.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/tc_bibliotheque/content_position.dart';
import '../../../core/tc_bibliotheque/library_resource.dart';
import '../../../core/tc_bibliotheque/port_support_actif.dart';
import '../../salle_seance/bibliotheque_seance.dart' show PresenterSupport;

/// La presentation d'une seance sur le port.
class PresentationPort {
  /// Cree la presentation de [seanceId].
  PresentationPort({
    required this.port,
    required this.seanceId,
    required this.revision,
  });

  /// Le port.
  final PortSupportActif port;

  /// La seance.
  final String seanceId;

  /// La revision du support actif vue par l'enseignant.
  final int Function() revision;

  /// La derniere reponse du serveur (`null` : rien n'est parti, ou pas de
  /// reponse encore).
  final ValueNotifier<ResultatActivation?> dernier =
      ValueNotifier<ResultatActivation?>(null);

  /// Vrai quand une presentation a echoue faute de reponse (reseau).
  final ValueNotifier<bool> nonConfirmee = ValueNotifier<bool>(false);

  String _cle = const Uuid().v4();

  /// Le rappel a passer a `BibliothequeSeance`, ou `null` quand la personne
  /// ne peut pas presenter (la salle garde alors l'ancien selecteur).
  Future<PresenterSupport?> pourSeance() async {
    final CapacitesSupportActif c = await port.capacites(seanceId);
    if (!c.peutPresenter) return null;
    return (LibraryResource ressource, ContentPosition? position) async {
      // Temps 1 : la capacite est relue ; elle peut avoir ete retiree.
      final CapacitesSupportActif frais = await port.capacites(seanceId);
      if (!frais.peutPresenter) throw StateError('presentation refusee');
      // Temps 2 : l'activation ne part que si la salle l'appelle.
      return () => unawaited(_activer(ressource, position));
    };
  }

  Future<void> _activer(
    LibraryResource ressource,
    ContentPosition? position,
  ) async {
    nonConfirmee.value = false;
    try {
      final ResultatActivation r = await port.activer(
        seanceId: seanceId,
        resourceId: ressource.id,
        revisionAttendue: revision(),
        cle: _cle,
        position: position,
      );
      if (r is ActivationFaite) _cle = const Uuid().v4();
      dernier.value = r;
    } on Object {
      // Non confirme : la meme cle sera reprise a la prochaine tentative.
      nonConfirmee.value = true;
    }
  }
}
