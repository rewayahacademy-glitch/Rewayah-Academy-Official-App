// L'adaptateur Supabase de la bibliotheque, cote administration (CAP-29),
// sur les RPC `library_admin_capacites`, `library_get_catalogue`,
// `library_get_catalogue_facettes`, `library_get_detail` et
// `admin_library_review_rights`, plus le depot R2 de la fonction Edge
// `bibliotheque-upload` ([BibliothequeUploadSupabase]).
//
// Le serveur rend aujourd'hui `peutImporter`, `peutPublier` et
// `peutAttribuer` a faux : les ecritures sans RPC (brouillon, publication,
// attribution, retrait) restent fermees, jamais simulees. Le controle de
// publication n'a pas de RPC : tous ses criteres se lisent « inconnu » et la
// version n'est pas publiable.

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/strings.g.dart';
import 'bibliotheque_upload_supabase.dart';
import 'modeles_bibliotheque_admin.dart';
import 'port_bibliotheque_admin.dart';

/// La bibliotheque d'administration servie par Supabase.
class BibliothequeAdminSupabase implements PortBibliothequeAdmin {
  /// Cree l'adaptateur sur le client de l'application ; [depot] porte le
  /// flux R2 (par defaut, sur le meme client).
  BibliothequeAdminSupabase(this._client, {BibliothequeUploadSupabase? depot})
    : _depot = depot ?? BibliothequeUploadSupabase(_client);

  final SupabaseClient _client;
  final BibliothequeUploadSupabase _depot;

  Future<Map<String, dynamic>> _rpc(
    String fonction, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      final Object? v = await _client.rpc<Object?>(fonction, params: params);
      if (v is! Map) throw const FormatException('Objet attendu.');
      return Map<String, dynamic>.from(v);
    } on PostgrestException catch (e) {
      throw switch (e.code) {
        '42501' => const BibliothequeNonAutorisee(),
        'P0002' => const BibliothequeIntrouvable(),
        _ => e,
      };
    } on FormatException {
      rethrow;
    } on Exception {
      throw const BibliothequeHorsLigne();
    }
  }

  @override
  Future<CapacitesBibliotheque> capacites() async {
    final Map<String, dynamic> c = await _rpc('library_admin_capacites');
    return CapacitesBibliotheque(
      peutLire: c['peutLire'] == true,
      peutImporter: c['peutImporter'] == true,
      peutPublier: c['peutPublier'] == true,
      peutAttribuer: c['peutAttribuer'] == true,
    );
  }

  @override
  Future<FacettesCatalogue> facettes() async {
    final Map<String, dynamic> f = await _rpc('library_get_catalogue_facettes');
    return FacettesCatalogue(
      niveaux: _textes(f['niveaux']),
      langues: _textes(f['langues']),
    );
  }

  @override
  Future<PageSupports> lister({
    FiltreCatalogue filtre = const FiltreCatalogue(),
    String? curseur,
    int limite = 25,
  }) async {
    final String recherche = filtre.recherche.trim();
    final Map<String, dynamic> page = await _rpc(
      'library_get_catalogue',
      <String, dynamic>{
        'p_filtre': <String, dynamic>{
          'etat': filtre.etat.name,
          if (filtre.type != null) 'type': filtre.type!.valeurSql,
          if (filtre.niveau != null) 'niveau': filtre.niveau,
          if (filtre.langue != null) 'langue': filtre.langue,
          if (recherche.isNotEmpty) 'recherche': recherche,
        },
        'p_curseur': curseur,
        'p_limite': limite,
      },
    );
    final Object? elements = page['elements'];
    if (elements is! List) throw const FormatException('Liste attendue.');
    return PageSupports(
      elements: List<SupportAdmin>.unmodifiable(<SupportAdmin>[
        for (final Object? e in elements) supportCatalogueJson(_objet(e)),
      ]),
      curseur: page['curseur'] is String ? page['curseur'] as String : null,
    );
  }

  @override
  Future<FicheSupport> fiche(String supportId) async => ficheSupportJson(
    await _rpc('library_get_detail', <String, dynamic>{
      'p_resource_id': supportId,
    }),
    acteur: t.admin.journal.roleAdmin,
  );

  @override
  Future<ResultatEcriture> revoirDroits({
    required String supportId,
    required String versionId,
    required SaisieDroits saisie,
    required int revisionAttendue,
  }) async {
    final Map<String, dynamic> r = await _rpc(
      'admin_library_review_rights',
      <String, dynamic>{
        'p_resource_id': supportId,
        'p_resource_version_id': versionId,
        'p_saisie': <String, dynamic>{
          'sourceTitre': saisie.sourceTitre ?? '',
          'titulaire': saisie.titulaire ?? '',
          'attribution': saisie.attribution ?? '',
          'preuveFournie': saisie.preuveFournie,
          'usages': <String>[for (final UsageDroit u in saisie.usages) u.name],
          'expireLeUtc': saisie.expireLeUtc?.toUtc().toIso8601String(),
          'approuver': saisie.approuver,
        },
        'p_revision_attendue': revisionAttendue,
      },
    );
    final int revision = (r['revision'] as num?)?.toInt() ?? revisionAttendue;
    return r['resultat'] == 'EcritureFaite'
        ? EcritureFaite(revision: revision)
        : const EcritureEnConflit();
  }

  @override
  Future<IntentionUpload> demanderUpload({
    required String supportId,
    required FichierADeposer fichier,
    FinaliteUpload finalite = FinaliteUpload.support,
  }) => _depot.demanderUpload(
    supportId: supportId,
    fichier: fichier,
    finalite: finalite,
  );

  @override
  Stream<ProgressionUpload> deposer({
    required String uploadId,
    Uint8List? octets,
  }) => _depot.deposer(uploadId: uploadId, octets: octets);

  @override
  Future<void> annulerUpload(String uploadId) => _depot.annulerUpload(uploadId);

  @override
  Future<ControleVersion> controler(String versionId) async => ControleVersion(
    criteres: <CritereControle>[
      for (final CleCritere cle in CleCritere.values)
        CritereControle(cle: cle, etat: EtatCritere.inconnu),
    ],
    publiable: false,
  );

  // Ecritures sans RPC serveur : fermees, comme les capacites rendues.

  @override
  Future<String> creerBrouillon(NouveauSupport saisie) =>
      Future<String>.error(const BibliothequeNonAutorisee());

  @override
  Future<ResultatEcriture> mettreAJour({
    required String supportId,
    required ModificationSupport modification,
    required int revisionAttendue,
  }) => Future<ResultatEcriture>.error(const BibliothequeNonAutorisee());

  @override
  Future<String> nouvelleVersion(String supportId) =>
      Future<String>.error(const BibliothequeNonAutorisee());

  @override
  Future<ResultatPublication> publier({
    required String supportId,
    required String versionId,
    required int revisionAttendue,
    required String cle,
  }) => Future<ResultatPublication>.error(const BibliothequeNonAutorisee());

  @override
  Future<PageClasses> classes({
    required String supportId,
    String? curseur,
    int limite = 25,
  }) => Future<PageClasses>.error(const BibliothequeNonAutorisee());

  @override
  Future<ResultatEcriture> attribuer({
    required String supportId,
    required Set<String> classeIds,
    required bool epingler,
    required int revisionAttendue,
  }) => Future<ResultatEcriture>.error(const BibliothequeNonAutorisee());

  @override
  Future<ResultatEcriture> retirer({
    required String supportId,
    required String motif,
    required int revisionAttendue,
  }) => Future<ResultatEcriture>.error(const BibliothequeNonAutorisee());
}

/// Une ligne du catalogue rendue par `library_get_catalogue`.
SupportAdmin supportCatalogueJson(Map<String, dynamic> m) => SupportAdmin(
  id: _texte(m, 'id'),
  titre: _texte(m, 'titre'),
  type: _type(m['type']),
  langue: _texte(m, 'langue'),
  categorie: _texte(m, 'categorie'),
  niveau: m['niveau'] is String ? m['niveau'] as String : null,
  numeroVersion: (m['numeroVersion'] as num?)?.toInt(),
  statutVersion: StatutVersionRessource.depuisSql(
    m['statutVersion'] as String?,
  ),
  revueDroits: _revue(m['revueDroits']),
  visibilite: _acces(m['visibilite']),
  modifieLeUtc: _instant(m['modifieLeUtc']) ?? _absent('modifieLeUtc'),
  retire: m['retire'] == true,
);

/// La fiche rendue par `library_get_detail`. [acteur] nomme l'auteur des
/// evenements : le serveur ne rend que l'action et sa date.
FicheSupport ficheSupportJson(
  Map<String, dynamic> m, {
  required String acteur,
}) {
  final Map<String, dynamic> s = _objet(m['support']);
  final List<Map<String, dynamic>> versionsJson = <Map<String, dynamic>>[
    for (final Object? v in _liste(m['versions'])) _objet(v),
  ];
  final List<VersionSupport> versions = <VersionSupport>[
    for (final Map<String, dynamic> v in versionsJson)
      VersionSupport(
        id: _texte(v, 'id'),
        numero: (v['numeroVersion'] as num).toInt(),
        statut: StatutVersionRessource.depuisSql(v['statut'] as String?),
        revueDroits: _revueDeDroits(v['droits']),
        publieeLeUtc: _instant(v['publieeLeUtc']),
        empreinte: v['empreinte'] is String ? v['empreinte'] as String : null,
      ),
  ];
  final Object? droitsDernier = versionsJson.isEmpty
      ? null
      : versionsJson.first['droits'];
  final Object? niveaux = s['niveaux'];
  final Map<String, dynamic> c = m['capacites'] is Map
      ? _objet(m['capacites'])
      : const <String, dynamic>{};
  final VersionSupport? derniere = versions.isEmpty ? null : versions.first;
  return FicheSupport(
    support: SupportAdmin(
      id: _texte(s, 'id'),
      titre: _texte(s, 'titre'),
      type: _type(s['type']),
      langue: _texte(s, 'langue'),
      categorie: _texte(s, 'categorie'),
      niveau: niveaux is List && niveaux.isNotEmpty && niveaux.first is String
          ? niveaux.first as String
          : null,
      numeroVersion: derniere?.numero,
      statutVersion: derniere?.statut ?? StatutVersionRessource.brouillon,
      revueDroits: derniere?.revueDroits ?? RevueDroits.aVerifier,
      visibilite: _acces(s['politiqueAcces']),
      modifieLeUtc: _instant(s['modifieLeUtc']) ?? _absent('modifieLeUtc'),
      retire: s['retire'] == true,
    ),
    revision: (m['revision'] as num).toInt(),
    titreCourt: s['titreCourt'] is String ? s['titreCourt'] as String : '',
    edition: s['edition'] is String ? s['edition'] as String : null,
    politiqueHorsLigne:
        PolitiqueOffline.depuisSql(s['politiqueHorsLigne'] as String?) ??
        PolitiqueOffline.jamais,
    versions: List<VersionSupport>.unmodifiable(versions),
    droits: _droits(droitsDernier),
    historique: List<EvenementAudit>.unmodifiable(<EvenementAudit>[
      for (final Object? e in _liste(m['historique']))
        if (_evenement(_objet(e), acteur) case final EvenementAudit ev) ev,
    ]),
    capacites: CapacitesSupport(
      peutModifier: c['peutModifier'] == true,
      peutPublier: c['peutPublier'] == true,
      peutAttribuer: c['peutAttribuer'] == true,
      peutRetirer: c['peutRetirer'] == true,
    ),
  );
}

DroitsSupport _droits(Object? brut) {
  if (brut is! Map) return DroitsSupport(revue: RevueDroits.aVerifier);
  final Map<String, dynamic> d = Map<String, dynamic>.from(brut);
  return DroitsSupport(
    revue: _revueDeDroits(d),
    sourceTitre: _optionnel(d['sourceTitre']),
    titulaire: _optionnel(d['titulaire']),
    preuveFournie: d['preuveFournie'] == true,
    usages: <UsageDroit>{
      for (final Object? u in _liste(d['usages']))
        if (_usage(u) case final UsageDroit usage) usage,
    },
    attribution: _optionnel(d['attribution']),
    expireLeUtc: _instant(d['expireLeUtc']),
  );
}

/// La revue d'une version : sans droits saisis, a verifier ; approuvee et
/// echue, expiree. Le serveur ne porte pas de refus distinct.
RevueDroits _revueDeDroits(Object? brut) {
  if (brut is! Map || brut['approuve'] != true) return RevueDroits.aVerifier;
  final DateTime? expire = _instant(brut['expireLeUtc']);
  return expire != null && !expire.isAfter(DateTime.now().toUtc())
      ? RevueDroits.expire
      : RevueDroits.approuve;
}

EvenementAudit? _evenement(Map<String, dynamic> e, String acteur) {
  final ActionAudit? action = switch (e['action']) {
    'library_resource_draft_created' => ActionAudit.creation,
    'library_resource_draft_updated' => ActionAudit.depot,
    'library_rights_review' => ActionAudit.revueDroits,
    'library_version_published' => ActionAudit.publication,
    'library_groups_assigned' => ActionAudit.attribution,
    'library_resource_withdrawn' => ActionAudit.retrait,
    _ => null,
  };
  final DateTime? quand = _instant(e['creeLeUtc']);
  if (action == null || quand == null) return null;
  return EvenementAudit(action: action, acteur: acteur, quandUtc: quand);
}

UsageDroit? _usage(Object? u) => switch (u) {
  'application' => UsageDroit.application,
  'classe' => UsageDroit.classe,
  'telechargement' => UsageDroit.telechargement,
  'hors_ligne' || 'horsLigne' => UsageDroit.horsLigne,
  _ => null,
};

RevueDroits _revue(Object? v) => RevueDroits.values.firstWhere(
  (RevueDroits r) => r.name == v,
  orElse: () => RevueDroits.aVerifier,
);

TypeRessource _type(Object? v) =>
    TypeRessource.depuisSql(v as String?) ??
    (throw const FormatException('Type de ressource inconnu.'));

PolitiqueAcces _acces(Object? v) =>
    PolitiqueAcces.depuisSql(v as String?) ?? PolitiqueAcces.admin;

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('Objet attendu.');
  return Map<String, dynamic>.from(v);
}

List<Object?> _liste(Object? v) => v is List ? v : const <Object?>[];

List<String> _textes(Object? v) => List<String>.unmodifiable(<String>[
  for (final Object? e in _liste(v))
    if (e is String) e,
]);

String _texte(Map<String, dynamic> m, String cle) {
  final Object? v = m[cle];
  if (v is! String) throw FormatException('Champ $cle invalide.');
  return v;
}

String? _optionnel(Object? v) => v is String && v.isNotEmpty ? v : null;

DateTime? _instant(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toUtc() : null;

Never _absent(String cle) => throw FormatException('Champ $cle absent.');
