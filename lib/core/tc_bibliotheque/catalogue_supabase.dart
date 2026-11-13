// L'adaptateur Supabase du catalogue de la Bibliotheque, cote lecteur (N4).
//
// Lectures seulement, sur les fonctions de la migration 20261108200000
// (`bibliotheque_catalogue_lecteur`, `bibliotheque_recents_lecteur`,
// `bibliotheque_reprise_lecteur`) et sur `ressources_du_groupe` (0035). Le
// serveur rejoue la regle de lecture de `library_resource` (RLS en vigueur et
// acces paye) : ce qui arrive ici est deja ce que l'appelant a le droit de
// voir. Aucune URL signee, aucune cle de stockage ne transite ; la couverture
// reste une cle d'asset (voir `LibraryResource.coverAsset`).
//
// La recherche libre n'est pas deleguee au `LIKE` du serveur : elle reprend
// `RechercheCatalogue.chercher`, qui normalise les accents et l'arabe et sait
// lire « sourate 2 » ou « page 12 ». Le serveur filtre par axes, l'application
// cherche dans ce qu'il a rendu.
//
// L'axe `etatOffline` d'un filtre n'existe pas au serveur : il depend des
// octets presents sur l'appareil. Il est laisse a l'appelant, qui connait les
// etats hors ligne (`RechercheCatalogue.filtrer(..., etats:)`).

import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_position.dart';
import 'library_resource.dart';
import 'port_catalogue.dart';
import 'recherche_catalogue.dart';

/// Le plafond de lignes demande au serveur a chaque page (sa borne est 200).
const int limiteCatalogueLecteur = 200;

/// Le nombre de pages lues au plus : le catalogue est « sans limite de
/// nombre » mais une lecture ne boucle jamais sans borne.
const int pagesCatalogueMax = 10;

/// Le catalogue lu au serveur.
class CatalogueSupabase implements PortCatalogue {
  /// Cree l'adaptateur.
  const CatalogueSupabase(this._client);

  final SupabaseClient _client;

  Future<Object?> _rpc(String fonction, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc<Object?>(fonction, params: params);
    } on PostgrestException catch (e) {
      throw EchecCatalogue(_raison(e));
    } on FormatException {
      throw const EchecCatalogue('reponse illisible');
    } on Exception {
      throw const EchecCatalogue('hors ligne');
    }
  }

  static String _raison(PostgrestException e) {
    if (e.code == '42501') return 'non autorise';
    if (e.code == '22023') return 'filtre invalide';
    return 'refus du serveur';
  }

  /// Le filtre traduit en cles du serveur. Seuls les axes poses partent.
  static Map<String, dynamic> filtreServeur(
    FiltreCatalogue? filtre, {
    String? id,
  }) {
    final Map<String, dynamic> sortie = <String, dynamic>{};
    if (filtre != null) {
      final Set<TypeRessource>? types = filtre.types;
      if (types != null && types.isNotEmpty) {
        sortie['types'] =
            types.map((TypeRessource t) => t.valeurSql).toList(growable: false)
              ..sort();
      }
      if (filtre.langue != null) sortie['langue'] = filtre.langue;
      if (filtre.categorie != null) sortie['categorie'] = filtre.categorie;
      if (filtre.niveau != null) sortie['niveau'] = filtre.niveau;
      if (filtre.rayon != null) sortie['rayon'] = filtre.rayon;
      if (filtre.etape != null) sortie['etape'] = filtre.etape;
    }
    if (id != null) sortie['id'] = id;
    return sortie;
  }

  /// Une liste de manifestes rendue par le serveur.
  static List<LibraryResource> manifestes(Object? brut) {
    if (brut == null) return const <LibraryResource>[];
    if (brut is! List) throw const FormatException('liste attendue');
    return brut
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> m) =>
              LibraryResource.depuisJson(Map<String, dynamic>.from(m)),
        )
        .toList(growable: false);
  }

  /// La reprise rendue par `bibliotheque_reprise_lecteur`, ou `null`.
  static ReprisLecture? reprise(Object? brut) {
    if (brut is! Map) return null;
    final Object? ressource = brut['ressource'];
    final Object? position = brut['position'];
    final Object? vueLe = brut['vue_le'];
    if (ressource is! Map || position is! Map || vueLe is! String) {
      return null;
    }
    final LibraryResource r = LibraryResource.depuisJson(
      Map<String, dynamic>.from(ressource),
    );
    final ContentPosition? p = _position(r.id, position);
    final DateTime? quand = DateTime.tryParse(vueLe)?.toUtc();
    if (p == null || quand == null) return null;
    return ReprisLecture(ressource: r, position: p, vueLeUtc: quand);
  }

  static ContentPosition? _position(
    String resourceId,
    Map<dynamic, dynamic> m,
  ) {
    final String? version = m['resource_version_id'] as String?;
    switch (TypeAncrage.depuisSql(m['type_ancrage'] as String?)) {
      case TypeAncrage.page:
        final Object? page = m['page'];
        if (page is! num) return null;
        return ContentPosition.page(
          resourceId: resourceId,
          page: page.toInt(),
          resourceVersionId: version,
        );
      case TypeAncrage.ayah:
        final Object? sourate = m['sourate'];
        final Object? ayah = m['ayah'];
        if (sourate is! num || ayah is! num) return null;
        return ContentPosition.ayah(
          resourceId: resourceId,
          sourate: sourate.toInt(),
          ayah: ayah.toInt(),
          resourceVersionId: version,
        );
      case TypeAncrage.section:
        final Object? section = m['section_id'];
        if (section is! String) return null;
        return ContentPosition.section(
          resourceId: resourceId,
          sectionId: section,
          resourceVersionId: version,
        );
      case TypeAncrage.fraction:
        final Object? fraction = m['fraction'];
        if (fraction is! num) return null;
        return ContentPosition.fraction(
          resourceId: resourceId,
          fraction: fraction.toDouble(),
          resourceVersionId: version,
        );
      case null:
        return null;
    }
  }

  /// Tout le catalogue visible : le serveur rend des pages de
  /// [limiteCatalogueLecteur] documents (filtre `decalage`) ; on lit la page
  /// suivante tant que la precedente est pleine.
  @override
  Future<List<LibraryResource>> tous({FiltreCatalogue? filtre}) async {
    final List<LibraryResource> sortie = <LibraryResource>[];
    for (int page = 0; page < pagesCatalogueMax; page++) {
      final Map<String, dynamic> serveur = filtreServeur(filtre);
      if (page > 0) serveur['decalage'] = page * limiteCatalogueLecteur;
      final List<LibraryResource> lot = manifestes(
        await _rpc('bibliotheque_catalogue_lecteur', <String, dynamic>{
          'p_filtre': serveur,
          'p_limite': limiteCatalogueLecteur,
        }),
      );
      sortie.addAll(lot);
      if (lot.length < limiteCatalogueLecteur) break;
    }
    return List<LibraryResource>.unmodifiable(sortie);
  }

  @override
  Future<List<RayonBibliotheque>> rayons() async {
    final Object? brut = await _rpc('bibliotheque_rayons_lecteur');
    if (brut == null) return const <RayonBibliotheque>[];
    if (brut is! List) throw const EchecCatalogue('reponse illisible');
    final List<RayonBibliotheque> rayons = brut
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> m) =>
              RayonBibliotheque.depuisJson(Map<String, dynamic>.from(m)),
        )
        .toList();
    rayons.sort((RayonBibliotheque a, RayonBibliotheque b) => a.ordre - b.ordre);
    return List<RayonBibliotheque>.unmodifiable(rayons);
  }

  @override
  Future<List<LibraryResource>> recents({int limite = 10}) async => manifestes(
    await _rpc('bibliotheque_recents_lecteur', <String, dynamic>{
      'p_limite': limite.clamp(1, 50),
    }),
  );

  @override
  Future<List<LibraryResource>> pourGroupe(String groupeId) async => manifestes(
    await _rpc('ressources_du_groupe', <String, dynamic>{
      'p_groupe_id': groupeId,
    }),
  );

  @override
  Future<LibraryResource?> parId(String resourceId) async {
    final List<LibraryResource> trouves = manifestes(
      await _rpc('bibliotheque_catalogue_lecteur', <String, dynamic>{
        'p_filtre': filtreServeur(null, id: resourceId),
        'p_limite': 1,
      }),
    );
    return trouves.isEmpty ? null : trouves.first;
  }

  @override
  Future<List<LibraryResource>> rechercher(
    String requete, {
    FiltreCatalogue? filtre,
  }) async => RechercheCatalogue.chercher(await tous(filtre: filtre), requete);

  @override
  Future<ReprisLecture?> derniereLecture() async =>
      reprise(await _rpc('bibliotheque_reprise_lecteur'));
}
