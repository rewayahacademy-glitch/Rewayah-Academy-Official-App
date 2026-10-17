/// BF1-03 : l'invitation d'un comptable par la direction, et son inscription
/// (migration 20261017160200).
///
/// Memes formes que l'invitation d'un enseignant ([Invitation],
/// [ErreurInvitation], [ResultatInvitation]) : l'ecran d'invitation et la
/// verification du code se reutilisent tels quels. Les deux portes restent
/// etanches cote serveur : un code de comptable ne cree jamais un enseignant,
/// ni l'inverse.
///
/// Emettre exige la direction en double verification (aal2) : sinon
/// [NonAutorise].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'port_invitations_enseignant.dart';

/// L'issue de l'inscription d'un comptable sur invitation.
enum ResultatInscriptionComptable {
  /// Le profil comptable est cree, le code consomme.
  consommee,

  /// Code inconnu, revoque, ou emis pour une autre adresse.
  inconnue,

  /// Le code a deja servi.
  dejaUtilisee,

  /// Le code a expire.
  expiree,
}

/// L'inscription d'un comptable invite (session sans profil).
abstract interface class PortInscriptionComptable {
  /// Cree le profil comptable de la session avec [code]. Leve [NonAutorise]
  /// quand la session a deja un profil, [HorsLigne] en cas de panne reseau.
  Future<ResultatInscriptionComptable> inscrire({
    required String code,
    required String prenom,
    required String nom,
    String? genre,
  });
}

/// L'identifiant de la dependance serveur, pour la trace et les tests.
const String dependanceInvitationsComptable = 'BF1-INVITATIONS-COMPTABLE';

/// Le port administration : absent avant le branchement serveur.
final Provider<PortInvitationsEnseignant?> portInvitationsComptableProvider =
    Provider<PortInvitationsEnseignant?>((Ref _) => null);

/// La verification du code par le candidat comptable.
final Provider<PortVerificationInvitation?>
portVerificationInvitationComptableProvider =
    Provider<PortVerificationInvitation?>((Ref _) => null);

/// L'inscription du candidat comptable.
final Provider<PortInscriptionComptable?> portInscriptionComptableProvider =
    Provider<PortInscriptionComptable?>((Ref _) => null);

/// Les invitations de comptable. Sans port : [CapaciteIndisponible].
final FutureProvider<List<Invitation>> invitationsComptableProvider =
    FutureProvider<List<Invitation>>((Ref ref) {
      final PortInvitationsEnseignant? port = ref.watch(
        portInvitationsComptableProvider,
      );
      if (port == null) {
        return Future<List<Invitation>>.error(
          const CapaciteIndisponible(dependanceInvitationsComptable),
        );
      }
      return port.lister();
    }, retry: (int _, Object _) => null);

/// Decode la reponse de `inscrire_comptable_invite`.
ResultatInscriptionComptable resultatInscriptionComptableJson(Object? brut) {
  if (brut is! Map) throw const FormatException('Objet attendu.');
  return switch (brut['resultat']) {
    'consommee' => ResultatInscriptionComptable.consommee,
    'inconnue' => ResultatInscriptionComptable.inconnue,
    'deja_utilisee' => ResultatInscriptionComptable.dejaUtilisee,
    'expiree' => ResultatInscriptionComptable.expiree,
    _ => throw const FormatException('Resultat d inscription inconnu.'),
  };
}
