import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'port_rappel_discret.dart';

/// Ce qui fait reellement voyager un rappel jusqu'a un participant.
///
/// **Une fonction, et non un port de plus.** Le transport cible existe au
/// contrat -- `PortRealtimePedagogique.emettreCible` d'Agent F -- mais sa charge
/// utile, `MessagePedagogique`, **n'a de signature nulle part** : ni la section 9
/// ni la section 17 de `TEACHING_CORE_CONTRACTS.md` n'en donnent les champs.
/// Agent D a du en ecrire un double local et l'a declare.
///
/// Agent E n'en ecrit pas un **troisieme**. Il reduit son besoin a ce qu'il est
/// reellement : « fais parvenir a cette personne, dans cette seance, le fait que
/// le professeur l'appelle ». Deux identifiants, aucune charge. Agent Z branche
/// `emettreCible` derriere cette ligne le jour ou la forme canonique existe, et
/// **un seul endroit changera**. Voir `TC_CONTRACT_REQUEST_E.md` section 4.
///
/// Leve pour signaler un echec. **Ne rend rien** : un transport qui rendrait un
/// accuse ferait naitre la boucle de notifications que la spec interdit.
///
/// TC-Z-SUIVI : `t.tc.classe.rappel.recu` (« Le professeur vous appelle »,
/// lu par l'eleve qui recoit le rappel) n'est encore affiche par aucun ecran --
/// ce fichier ne construit que le cote emetteur.
typedef TransportRappel = Future<void> Function({
  required String sessionId,
  required String academyId,
});

/// Le transport par defaut : **aucun**.
///
/// Il echoue explicitement plutot que de faire semblant. C'est la regle du
/// depot -- « un bouton qui ne peut pas aboutir n'est pas rendu, et une action
/// qui n'aboutit pas le dit ». Un transport muet ferait croire a l'enseignant
/// que l'eleve a ete appele.
Future<void> transportRappelAbsent({
  required String sessionId,
  required String academyId,
}) => Future<void>.error(const EchecRappel(MotifEchecRappel.transport));

/// Combien de temps un eleve reste a l'abri d'un second rappel.
///
/// **Court**, dit la spec section 10.2 : assez pour empecher le martelement,
/// assez peu pour qu'un professeur qui appelle deux fois de suite un enfant
/// distrait ne soit pas bloque. Quarante-cinq secondes est la duree d'une
/// recitation courte.
const Duration cooldownRappelDiscret = Duration(seconds: 45);

/// Le rappel discret, avec son cooldown.
///
/// **Toute la logique de refus est ici, aucune n'est dans l'ecran.** L'interface
/// lit [cooldownRestant] pour desactiver l'action ; elle ne compte pas le temps
/// elle-meme, sans quoi deux comptes finiraient par diverger.
///
/// Le cooldown est porte **par (seance, eleve)** et non par enseignant : appeler
/// Amina ne doit pas empecher d'appeler Ilyas une seconde plus tard.
class RappelDiscretCadence implements PortRappelDiscret {
  /// Cree le service.
  ///
  /// [maintenant] est injecte pour que le cooldown se teste sans attendre :
  /// c'est le meme principe que `calculeeAUtc` dans `SessionClockVM` -- une
  /// horloge qu'on ne peut pas remplacer rend une regle invisible.
  RappelDiscretCadence({
    this.transport = transportRappelAbsent,
    this.cooldown = cooldownRappelDiscret,
    DateTime Function()? maintenant,
  }) : _maintenant = maintenant ?? DateTime.now;

  /// Ce qui fait voyager le rappel. Par defaut : rien, et il le dit.
  final TransportRappel transport;

  @override
  final Duration cooldown;

  final DateTime Function() _maintenant;

  /// Le dernier rappel **reussi** par cle de cooldown.
  ///
  /// Reussi seulement : un envoi qui echoue ne doit pas bloquer la nouvelle
  /// tentative, sinon une coupure reseau d'une seconde couterait quarante-cinq
  /// secondes de silence a l'eleve.
  final Map<String, DateTime> _derniers = <String, DateTime>{};

  static String _cle(String sessionId, String academyId) =>
      '$sessionId/$academyId';

  @override
  Duration? cooldownRestant({
    required String sessionId,
    required String academyId,
  }) {
    final DateTime? dernier = _derniers[_cle(sessionId, academyId)];
    if (dernier == null) {
      return null;
    }
    final Duration ecoule = _maintenant().difference(dernier);
    if (ecoule.isNegative || ecoule >= cooldown) {
      return null;
    }
    return cooldown - ecoule;
  }

  @override
  Future<void> rappeler({
    required String sessionId,
    required String academyId,
  }) async {
    if (cooldownRestant(sessionId: sessionId, academyId: academyId) != null) {
      throw const EchecRappel(MotifEchecRappel.cooldown);
    }
    try {
      await transport(sessionId: sessionId, academyId: academyId);
    } on EchecRappel {
      // Deja nomme par le transport : le renvoyer tel quel plutot que de le
      // reemballer, sinon le motif « droit refuse » deviendrait « transport ».
      rethrow;
    } catch (_) {
      throw const EchecRappel(MotifEchecRappel.transport);
    }
    // **Apres l'envoi, jamais avant** : un cooldown pose en amont punirait une
    // tentative qui n'a atteint personne.
    _derniers[_cle(sessionId, academyId)] = _maintenant();
  }
}

/// Le rappel discret employe par l'application.
///
/// Le transport reste [transportRappelAbsent] tant qu'Agent Z n'a pas branche
/// `PortRealtimePedagogique.emettreCible` : l'action existe, elle est cadencee,
/// et elle **dit** qu'elle n'aboutit pas. C'est la difference entre un lot
/// partiel declare et un lot qui ment.
final Provider<PortRappelDiscret> portRappelDiscretProvider =
    Provider<PortRappelDiscret>((Ref ref) => RappelDiscretCadence());
