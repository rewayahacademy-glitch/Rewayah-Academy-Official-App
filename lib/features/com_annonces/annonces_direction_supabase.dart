// L'adaptateur Supabase des annonces de la direction (ANNONCES-SIMPLES,
// migration 20261126700000) : `com_annonce_publics`, `com_annonce_audience`,
// `com_annonce_envoyer`, `com_mes_annonces`, `com_annonce_vue`.
//
// « Envoyee » ne vient que de l'accuse du serveur. Une RPC absente ou refusee
// se lit comme une capacite indisponible (la migration n'est pas encore
// installee, ou la personne n'est pas de la direction).

import '../../core/communications/communications_supabase.dart';
import 'port_annonces.dart';
import 'port_annonces_direction.dart';

/// Les annonces de la direction servies par Supabase.
class AnnoncesDirectionSupabase implements PortAnnoncesDirection {
  /// Cree l'adaptateur sur un appel RPC.
  const AnnoncesDirectionSupabase(this._appel);

  final AppelRpc _appel;

  Future<Object?> _lire(String fonction, Map<String, dynamic> p) async {
    try {
      return await _appel(fonction, p);
    } on Object catch (e) {
      if (estRefusOuAbsence(e)) throw AnnoncesDirectionIndisponibles.manque;
      rethrow;
    }
  }

  static int _entier(Object? v) => v is num ? v.toInt() : 0;

  @override
  Future<List<PublicAnnonce>> publics() async {
    final Map<String, dynamic> v = objetJson(
      await _lire('com_annonce_publics', const <String, dynamic>{}),
    );
    return List<PublicAnnonce>.unmodifiable(<PublicAnnonce>[
      for (final Map<String, dynamic> p in listeJson(v['publics']))
        PublicAnnonce(
          code: texteJson(p, 'code'),
          destinataires: _entier(p['destinataires']),
        ),
    ]);
  }

  @override
  Future<AudienceAnnonce> audience(Set<String> publics) async {
    final Map<String, dynamic> v = objetJson(
      await _lire('com_annonce_audience', <String, dynamic>{
        'p_publics': (publics.toList()..sort()),
      }),
    );
    final Map<String, dynamic> c = v['courriel'] is Map
        ? objetJson(v['courriel'])
        : const <String, dynamic>{};
    return AudienceAnnonce(
      destinataires: _entier(v['destinataires']),
      raison: switch (v['raison']) {
        'personne' => RaisonVide.personne,
        'cote_inconnu' => RaisonVide.coteInconnu,
        _ => null,
      },
      courriel: EstimationCourriel(
        adresses: _entier(c['adresses']),
        jours: _entier(c['jours']),
        parJour: _entier(c['par_jour']),
      ),
    );
  }

  @override
  Future<AnnonceConfirmee> envoyer({
    required EnvoiAnnonce envoi,
    required String cleIdempotence,
  }) async {
    final Map<String, dynamic> accuse = objetJson(
      await _appel('com_annonce_envoyer', <String, dynamic>{
        'p_publics': (envoi.publics.toList()..sort()),
        'p_titre': envoi.titre.trim(),
        'p_texte': envoi.texte.trim(),
        'p_programmee_le': envoi.programmeeLe?.toUtc().toIso8601String(),
        'p_courriel': envoi.courriel,
        'p_cle_idempotence': cleServeur(cleIdempotence),
      }),
    );
    return AnnonceConfirmee(
      id: texteJson(accuse, 'id'),
      etat: accuse['etat'] == 'planifiee'
          ? EtatAnnonce.planifiee
          : EtatAnnonce.publiee,
      le: instantJson(accuse, 'le'),
    );
  }

  @override
  Future<List<AnnonceRecue>> mesAnnonces() async {
    final Map<String, dynamic> v = objetJson(
      await _lire('com_mes_annonces', const <String, dynamic>{}),
    );
    return List<AnnonceRecue>.unmodifiable(<AnnonceRecue>[
      for (final Map<String, dynamic> a in listeJson(v['annonces']))
        AnnonceRecue(
          id: texteJson(a, 'id'),
          titre: texteJson(a, 'titre'),
          texte: texteJson(a, 'texte'),
          publieeLe: instantJson(a, 'publiee_le'),
          vue: a['vue'] == true,
        ),
    ]);
  }

  @override
  Future<void> marquerVue(String id) async {
    if (!estUuid(id)) throw ArgumentError.value(id, 'id');
    await _appel('com_annonce_vue', <String, dynamic>{'p_annonce_id': id});
  }
}
