import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/strings.g.dart';
import 'offre_horaire.dart' show LangueCours, PublicOffre, ReglesAcademie;
import 'port_offres_admin.dart';

/// Adaptateur PostgREST du port d'administration des offres vitrine (L2-05).
///
/// Lit `offres_horaires` (la policy `offres_horaires_vitrine` rend tout a
/// l'administration, brouillons et offres retirees comprises) et appelle les
/// trois RPC de `0043` : `creer_offre_horaire`, `publier_offre_horaire`,
/// `retirer_offre_horaire`. Le serveur reste la barriere : ce client n'ecrit
/// aucune table.
class OffresAdminSupabase implements PortOffresAdmin {
  /// Cree l'adaptateur.
  const OffresAdminSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ReglesCreationOffre> reglesCreation() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('langues_cours')
        .select('code, nom_humain')
        .eq('actif', true)
        .order('ordre', ascending: true);
    Map<String, dynamic> regles = const <String, dynamic>{};
    try {
      final Object? brut = await _client.rpc<Object?>('regles_academie');
      if (brut is Map<String, dynamic>) regles = brut;
    } on Object {
      // Les regles par defaut de `ReglesAcademie` valent mieux qu'un
      // formulaire inaccessible ; le serveur valide de toute facon.
    }
    return ReglesCreationOffre(
      langues: lignes.map(LangueCours.depuisJson).toList(growable: false),
      regles: ReglesAcademie.depuisJson(regles),
    );
  }

  @override
  Future<List<OffreAdmin>> lister() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('offres_horaires')
        .select(
          'id, type_public, langue_code, fuseau_iana, jours, heure_locale, '
          'duree_minutes, etat, retrait_motif, langues_cours(nom_humain)',
        );
    final List<OffreAdmin> offres = lignes
        .map(_depuisLigne)
        .toList(growable: false);
    int rang(EtatOffreAdmin e) => switch (e) {
      EtatOffreAdmin.publiee => 0,
      EtatOffreAdmin.brouillon => 1,
      EtatOffreAdmin.retiree => 2,
    };
    return List<OffreAdmin>.of(offres)..sort((OffreAdmin a, OffreAdmin b) {
      final int c = rang(a.etat).compareTo(rang(b.etat));
      return c != 0 ? c : a.heureLocale.compareTo(b.heureLocale);
    });
  }

  OffreAdmin _depuisLigne(Map<String, dynamic> ligne) {
    final Object? langue = ligne['langues_cours'];
    final String nom = langue is Map<String, dynamic>
        ? langue['nom_humain'] as String? ?? ''
        : '';
    final List<int> jours =
        ((ligne['jours'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic v) => (v as num).toInt())
            .toList()
          ..sort();
    return OffreAdmin(
      id: ligne['id'] as String,
      public: PublicOffre.depuisSql(ligne['type_public'] as String?),
      langueCode: ligne['langue_code'] as String? ?? '',
      langueNom: nom.isEmpty ? (ligne['langue_code'] as String? ?? '') : nom,
      fuseauIana: ligne['fuseau_iana'] as String? ?? '',
      jours: jours,
      heureLocale: (ligne['heure_locale'] as num?)?.toInt() ?? 0,
      dureeMinutes: (ligne['duree_minutes'] as num?)?.toInt() ?? 0,
      etat: EtatOffreAdmin.depuisSql(ligne['etat'] as String?),
      motifRetrait: ligne['retrait_motif'] as String?,
    );
  }

  @override
  Future<String> creer({
    required String typePublic,
    required String langueCode,
    required String fuseauIana,
    required List<int> jours,
    required int heureLocale,
    int? dureeMinutes,
  }) async {
    try {
      final Object? id = await _client.rpc<Object?>(
        'creer_offre_horaire',
        params: <String, dynamic>{
          'p_type_public': typePublic,
          'p_langue_code': langueCode,
          'p_fuseau_iana': fuseauIana,
          'p_jours': jours,
          'p_heure_locale': heureLocale,
          'p_duree_minutes': ?dureeMinutes,
        },
      );
      return id! as String;
    } on PostgrestException catch (e) {
      throw OffreAdminRefusee(messageLisible(e));
    }
  }

  @override
  Future<void> publier(String offreId) async {
    try {
      await _client.rpc<void>(
        'publier_offre_horaire',
        params: <String, dynamic>{'p_offre_id': offreId},
      );
    } on PostgrestException catch (e) {
      throw OffreAdminRefusee(messageLisible(e));
    }
  }

  @override
  Future<void> retirer(String offreId, {required String motif}) async {
    try {
      await _client.rpc<void>(
        'retirer_offre_horaire',
        params: <String, dynamic>{'p_offre_id': offreId, 'p_motif': motif},
      );
    } on PostgrestException catch (e) {
      throw OffreAdminRefusee(messageLisible(e));
    }
  }
}

/// Traduit un `raise exception` de `0043` en phrase lisible, dans la langue
/// de l'interface. Un message inconnu est rendu tel quel : mieux vaut le dire
/// que l'avaler.
String messageLisible(PostgrestException e) {
  final String m = e.message;
  final s = t.admin.offres.serveur;
  if (m.contains('reservee a l\'administration') ||
      m.contains('reserve a l\'administration')) {
    return s.reserve;
  }
  if (m.contains('deja publiee')) return s.dejaPubliee;
  if (m.contains('deja retiree')) return s.dejaRetiree;
  if (m.contains('introuvable')) return s.introuvable;
  if (m.contains('motif est requis')) return s.motifRequis;
  if (m.contains('jours invalides')) return s.joursInvalides;
  if (m.contains('seances par semaine')) return s.nombreJours;
  if (m.contains('fuseau IANA inconnu')) return s.fuseauInconnu;
  if (m.contains('public inconnu')) return s.publicInconnu;
  if (e.code == '23505' || m.contains('offres_horaires_motif_unique')) {
    return s.doublon;
  }
  return m;
}
