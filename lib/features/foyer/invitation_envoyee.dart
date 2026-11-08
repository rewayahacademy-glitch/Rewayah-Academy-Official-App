/// INVITATION-SECOND-ADULTE (07/11/2026) : l'invitation en attente du
/// titulaire, lue et renvoyee.
///
/// `mon_invitation_envoyee()` rend l'adresse, l'echeance et les renvois
/// restants ; `renvoyer_invitation_conjoint(p_cle)` renvoie la meme
/// invitation a la meme adresse, avec un nouveau code (l'ancien ne sert
/// plus), sans changer l'echeance, trois fois au plus (migration
/// 20261111000000). L'echeance court du temps, jamais d'un clic.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/capacites/capacite_indisponible.dart';

/// L'invitation qui attend sa reponse.
@immutable
class InvitationEnAttente {
  /// Cree l'etat.
  const InvitationEnAttente({
    required this.courriel,
    required this.expireLe,
    required this.renvoisRestants,
  });

  /// L'adresse invitee.
  final String courriel;

  /// L'echeance (7 jours apres l'envoi).
  final DateTime expireLe;

  /// Les renvois encore possibles (0 a 3).
  final int renvoisRestants;
}

/// La reponse a un renvoi.
sealed class ResultatRenvoi {
  const ResultatRenvoi();
}

/// L'invitation est repartie, avec un nouveau code.
final class RenvoiFait extends ResultatRenvoi {
  /// Cree la reponse.
  const RenvoiFait(this.renvoisRestants);

  /// Les renvois encore possibles.
  final int renvoisRestants;
}

/// Trois renvois deja faits : rien n'est reparti.
final class RenvoiLimite extends ResultatRenvoi {
  /// Cree la reponse.
  const RenvoiLimite();
}

/// L'invitation a expire, ou n'attend plus : rien n'est reparti.
final class RenvoiPerimee extends ResultatRenvoi {
  /// Cree la reponse.
  const RenvoiPerimee();
}

/// La connexion a coupe : le renvoi n'est pas confirme ; la meme cle rend une
/// nouvelle tentative sure (aucun second e-mail).
final class RenvoiEchecReseau extends ResultatRenvoi {
  /// Cree la reponse.
  const RenvoiEchecReseau();
}

/// La lecture et le renvoi.
abstract interface class PortInvitationEnvoyee {
  /// L'invitation en attente, ou `null` s'il n'y en a pas.
  Future<InvitationEnAttente?> lire();

  /// Renvoie l'invitation en attente.
  Future<ResultatRenvoi> renvoyer(String cle);
}

class _Indisponible implements PortInvitationEnvoyee {
  const _Indisponible();

  @override
  Future<InvitationEnAttente?> lire() => Future<InvitationEnAttente?>.error(
    const CapaciteIndisponible('invitation_envoyee'),
  );

  @override
  Future<ResultatRenvoi> renvoyer(String _) => Future<ResultatRenvoi>.error(
    const CapaciteIndisponible('invitation_envoyee'),
  );
}

/// Le port ; l'application le surcharge avec l'adaptateur Supabase.
final Provider<PortInvitationEnvoyee> portInvitationEnvoyeeProvider =
    Provider<PortInvitationEnvoyee>((Ref _) => const _Indisponible());

/// L'invitation en attente du titulaire ; `null` sans invitation.
final FutureProvider<InvitationEnAttente?> invitationEnvoyeeProvider =
    FutureProvider<InvitationEnAttente?>(
      (Ref ref) => ref.watch(portInvitationEnvoyeeProvider).lire(),
    );

/// Lit la reponse de `mon_invitation_envoyee()`.
InvitationEnAttente? invitationEnAttenteDepuis(Object? brut) {
  if (brut is! Map || brut['etat'] != 'en_attente') return null;
  final Object? courriel = brut['courriel'];
  final DateTime? fin = DateTime.tryParse('${brut['expire_le']}');
  final Object? restants = brut['renvois_restants'];
  if (courriel is! String || fin == null || restants is! num) return null;
  return InvitationEnAttente(
    courriel: courriel,
    expireLe: fin,
    renvoisRestants: restants.toInt(),
  );
}

/// Lit la reponse de `renvoyer_invitation_conjoint`.
ResultatRenvoi resultatRenvoiDepuis(Object? brut) {
  if (brut is! Map) return const RenvoiEchecReseau();
  return switch (brut['etat']) {
    'renvoyee' => RenvoiFait(
      (brut['renvois_restants'] is num)
          ? (brut['renvois_restants'] as num).toInt()
          : 0,
    ),
    'limite' => const RenvoiLimite(),
    'perimee' || 'aucune' => const RenvoiPerimee(),
    _ => const RenvoiEchecReseau(),
  };
}

/// L'adaptateur Supabase.
class InvitationEnvoyeeSupabase implements PortInvitationEnvoyee {
  /// Cree l'adaptateur.
  const InvitationEnvoyeeSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<InvitationEnAttente?> lire() async => invitationEnAttenteDepuis(
    await _client.rpc<Object?>('mon_invitation_envoyee'),
  );

  @override
  Future<ResultatRenvoi> renvoyer(String cle) async {
    try {
      return resultatRenvoiDepuis(
        await _client.rpc<Object?>(
          'renvoyer_invitation_conjoint',
          params: <String, dynamic>{'p_cle': cle},
        ),
      );
    } on Object {
      return const RenvoiEchecReseau();
    }
  }
}
