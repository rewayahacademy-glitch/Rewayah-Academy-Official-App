// L'adaptateur Supabase des annonces de la direction (ANNONCES-SIMPLES,
// migration 20261126900000) : `com_annonce_publics`, `com_annonce_audience`,
// `com_annonce_envoyer`, `com_mes_annonces`, `com_annonce_vue` ; et, depuis
// ANNONCES-SERVEUR (21/11/2026, migration 20261130976000), le fil pagine et
// traduit (`com_mes_annonces(p_limite, p_avant, p_langue, p_fermees)`),
// `com_annonce_fermer` et `com_annonce_rouvrir`.
//
// « Envoyee » ne vient que de l'accuse du serveur. Une RPC absente ou refusee
// se lit comme une capacite indisponible (la migration n'est pas encore
// installee, ou la personne n'est pas de la direction).

import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/communications/communications_supabase.dart';
import '../../core/i18n/strings.g.dart';
import 'port_annonces.dart';
import 'port_annonces_direction.dart';

/// Les annonces de la direction servies par Supabase.
class AnnoncesDirectionSupabase implements PortAnnoncesDirection {
  /// Cree l'adaptateur sur un appel RPC. [langue] rend la langue de
  /// l'interface, demandee au serveur pour le texte des annonces (par defaut
  /// la langue courante de l'application ; le serveur prend celle du compte
  /// quand elle n'est pas `fr`, `en` ou `ar`).
  const AnnoncesDirectionSupabase(this._appel, {this.langue});

  final AppelRpc _appel;

  /// La langue demandee au serveur ; `null` : celle de l'application.
  final String Function()? langue;

  String _langueCourante() =>
      (langue ?? () => LocaleSettings.currentLocale.languageCode)();

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
  Future<PageAnnonces> mesAnnonces({
    int limite = 20,
    DateTime? avant,
    bool fermees = false,
  }) async {
    Object? brut;
    try {
      brut = await _appel('com_mes_annonces', <String, dynamic>{
        'p_limite': limite.clamp(1, 50),
        'p_avant': avant?.toUtc().toIso8601String(),
        'p_langue': _langueCourante(),
        'p_fermees': fermees,
      });
    } on Object catch (e) {
      if (!_estAbsence(e)) {
        if (estRefusOuAbsence(e)) throw AnnoncesDirectionIndisponibles.manque;
        rethrow;
      }
      // La migration 20261130976000 n'est pas encore installee : l'ancien fil
      // (50 annonces, une seule page, sans fermeture ni traduction).
      if (avant != null) return PageAnnonces.vide;
      brut = await _lire('com_mes_annonces', const <String, dynamic>{});
    }
    final Map<String, dynamic> v = objetJson(brut);
    final Object? suite = v['suite'];
    return PageAnnonces(
      annonces: List<AnnonceRecue>.unmodifiable(<AnnonceRecue>[
        for (final Map<String, dynamic> a in listeJson(v['annonces']))
          _annonce(a),
      ]),
      suite: suite is String ? DateTime.tryParse(suite)?.toUtc() : null,
    );
  }

  /// La fonction (ou sa forme) n'existe pas au serveur.
  static bool _estAbsence(Object e) =>
      e is PostgrestException && (e.code == 'PGRST202' || e.code == '42883');

  static AnnonceRecue _annonce(Map<String, dynamic> a) {
    final String? titreOriginal = texteOptionnel(a, 'titre_original');
    final String? texteOriginal = texteOptionnel(a, 'texte_original');
    final String? titreRendu = texteOptionnel(a, 'titre');
    final String? texteRendu = texteOptionnel(a, 'texte');
    // Jamais vide : l'original quand le texte rendu manque, et inversement.
    final String titre = titreRendu ?? titreOriginal ?? texteJson(a, 'titre');
    final String texte = texteRendu ?? texteOriginal ?? texteJson(a, 'texte');
    return AnnonceRecue(
      id: texteJson(a, 'id'),
      titre: titre,
      texte: texte,
      publieeLe: instantJson(a, 'publiee_le'),
      vue: a['vue'] == true,
      titreOriginal: titreOriginal ?? titre,
      texteOriginal: texteOriginal ?? texte,
      langueOriginale: texteOptionnel(a, 'langue_originale'),
      traduite: a['traduite'] == true && texteRendu != null,
      fermee: a['fermee'] == true,
    );
  }

  @override
  Future<void> marquerVue(String id) async {
    if (!estUuid(id)) throw ArgumentError.value(id, 'id');
    await _appel('com_annonce_vue', <String, dynamic>{'p_annonce_id': id});
  }

  @override
  Future<void> fermer(String id) async {
    if (!estUuid(id)) throw ArgumentError.value(id, 'id');
    await _lire('com_annonce_fermer', <String, dynamic>{'p_annonce_id': id});
  }

  @override
  Future<void> rouvrir(String id) async {
    if (!estUuid(id)) throw ArgumentError.value(id, 'id');
    await _lire('com_annonce_rouvrir', <String, dynamic>{'p_annonce_id': id});
  }
}
