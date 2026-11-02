// I1 (02/11/2026) : l'adaptateur Supabase des invitations des familles
// importees, sur `invitations_familles_importees`,
// `envoyer_invitation_famille_importee` et
// `envoyer_invitations_familles_importees` (migration 20261105300000).
//
// Les issues metier arrivent dans la reponse (statut), jamais en exception ;
// 42501 dit « non autorise ».

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/recrutement/port_invitations_enseignant.dart'
    show HorsLigne, NonAutorise;
import 'familles_importees.dart';

/// Les invitations des familles importees servies par Supabase.
class FamillesImporteesSupabase implements PortFamillesImportees {
  /// Cree l'adaptateur sur le client de l'application.
  const FamillesImporteesSupabase(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> _appel(
    String fonction, [
    Map<String, dynamic>? params,
  ]) async {
    final Object? brut;
    try {
      brut = await _client.rpc<Object?>(fonction, params: params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const NonAutorise();
      rethrow;
    } on FormatException {
      rethrow;
    } on Exception {
      throw const HorsLigne();
    }
    if (brut is! Map) throw const FormatException('Objet attendu.');
    return Map<String, dynamic>.from(brut);
  }

  @override
  Future<FamillesImportees> lister() async {
    final Map<String, dynamic> r = await _appel(
      'invitations_familles_importees',
    );
    return famillesImporteesJson(r);
  }

  @override
  Future<ResultatEnvoiFoyer> envoyer(String foyer) async {
    final Map<String, dynamic> r = await _appel(
      'envoyer_invitation_famille_importee',
      <String, dynamic>{'p_foyer': foyer},
    );
    return switch (r['statut']) {
      'en_file' => ResultatEnvoiFoyer.enFile,
      'deja_en_file' => ResultatEnvoiFoyer.dejaEnFile,
      'compte_cree' => ResultatEnvoiFoyer.compteCree,
      'introuvable' => ResultatEnvoiFoyer.introuvable,
      _ => throw const FormatException('Statut d envoi inconnu.'),
    };
  }

  @override
  Future<ResultatEnvoiTous> envoyerATous(int attendu) async {
    final Map<String, dynamic> r = await _appel(
      'envoyer_invitations_familles_importees',
      <String, dynamic>{'p_attendu': attendu},
    );
    return switch (r['statut']) {
      'en_file' => EnvoiTousEnFile((r['envoyees'] as num).toInt()),
      'nombre_change' => EnvoiTousNombreChange((r['a_envoyer'] as num).toInt()),
      _ => throw const FormatException('Statut d envoi inconnu.'),
    };
  }
}

/// La reponse de `invitations_familles_importees`.
FamillesImportees famillesImporteesJson(Map<String, dynamic> r) {
  final Object? foyers = r['foyers'];
  if (foyers is! List) throw const FormatException('Liste attendue.');
  return FamillesImportees(
    aEnvoyer: (r['a_envoyer'] as num?)?.toInt() ?? 0,
    foyers: List<FoyerImporte>.unmodifiable(<FoyerImporte>[
      for (final Object? f in foyers)
        if (f is Map) foyerImporteJson(Map<String, dynamic>.from(f)),
    ]),
  );
}

/// Un foyer de la liste.
FoyerImporte foyerImporteJson(Map<String, dynamic> f) => FoyerImporte(
  id: f['id'] as String,
  email: f['email'] as String,
  personnes: (f['personnes'] as num?)?.toInt() ?? 0,
  etat: switch (f['etat']) {
    'a_envoyer' => EtatInvitationFamille.aEnvoyer,
    'en_file' => EtatInvitationFamille.enFile,
    'envoyee' => EtatInvitationFamille.envoyee,
    'echec' => EtatInvitationFamille.echec,
    'compte_cree' => EtatInvitationFamille.compteCree,
    _ => throw const FormatException('Etat d invitation inconnu.'),
  },
  envoyeeLe: f['envoyee_le'] is String
      ? DateTime.tryParse(f['envoyee_le'] as String)?.toLocal()
      : null,
);
