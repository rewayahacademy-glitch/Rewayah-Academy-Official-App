import 'package:supabase_flutter/supabase_flutter.dart';

import 'invitation_conjoint.dart';

/// La reprise du foyer, servie par les RPC `etat_reprise_foyer`,
/// `deposer_reprise_foyer` et `refuser_reprise_foyer` (migrations 0098 et
/// 0099, EA-BR-27 et EA-BR-28 ; lot N2, FA3). La decision de
/// l'administration est deja branchee (`portReprisesAdminProvider`).
///
/// Les statuts et les dates sont ceux du serveur, jamais calcules (F17). Un
/// depot ou un refus idempotent par la cle ; une coupure ne confirme rien
/// (D5).
class RepriseFoyerSupabase implements PortRepriseFoyer {
  /// Cree l'adaptateur sur le client de l'application.
  const RepriseFoyerSupabase(this._client);

  final SupabaseClient _client;

  /// La reponse brute de `etat_reprise_foyer`, lue une fois pour les deux
  /// vues (demandeur et titulaire).
  Future<Object?> lireBrut() => _client.rpc<Object?>('etat_reprise_foyer');

  @override
  Future<ResultatReprise> deposer({required String cle}) =>
      _geste('deposer_reprise_foyer', cle);

  @override
  Future<ResultatReprise> refuser({required String cle}) =>
      _geste('refuser_reprise_foyer', cle);

  Future<ResultatReprise> _geste(String fonction, String cle) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        fonction,
        params: <String, dynamic>{'p_cle': cle},
      );
      if (reponse is Map && reponse['statut'] == 'enregistree') {
        return const RepriseEnregistree();
      }
      return const RepriseEchecReseau();
    } on PostgrestException {
      // Le serveur refuse (pas eligible, demande deja ouverte, redepot
      // differe) : jamais lu comme un geste enregistre. Faute d'un resultat
      // « refuse » dans le port, le geste n'est pas confirme.
      return const RepriseEchecReseau();
    } on Object {
      return const RepriseEchecReseau();
    }
  }
}

/// Ce que le second adulte lit de sa demande (`type = demande`), ou aucune.
EtatReprise etatRepriseDepuis(Object? reponse) {
  if (reponse is! Map || reponse['type'] != 'demande') {
    return const RepriseAucune();
  }
  final StatutReprise? statut = switch (reponse['statut']) {
    'deposee' => StatutReprise.deposee,
    'refusee_par_titulaire' => StatutReprise.refuseeParTitulaire,
    'attente_administration' => StatutReprise.attenteAdministration,
    'validee' => StatutReprise.validee,
    'refusee' => StatutReprise.refusee,
    _ => null,
  };
  if (statut == null) return const RepriseAucune();
  return RepriseDemande(
    statut: statut,
    deposeeLe: _date(reponse['deposee_le']),
    examenPossibleLe: _date(reponse['examen_possible_le']),
    redepotPossibleLe: _date(reponse['redepot_possible_le']),
  );
}

/// Ce que le titulaire lit de la demande qui le concerne (`type =
/// titulaire`), ou `null` quand aucune demande ne l'attend.
DemandeRepriseRecue? demandeRepriseDepuis(Object? reponse) {
  if (reponse is! Map || reponse['type'] != 'titulaire') return null;
  return switch (reponse['statut']) {
    'a_refuser' => const RepriseARefuser(),
    'refusee_par_vous' => const RepriseRefuseeParVous(),
    _ => null,
  };
}

DateTime? _date(Object? valeur) =>
    valeur is String ? DateTime.tryParse(valeur)?.toLocal() : null;
