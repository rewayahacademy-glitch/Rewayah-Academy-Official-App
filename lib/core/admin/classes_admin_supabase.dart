// L'adaptateur Supabase de la liste paginee des classes de la direction
// (R16, R17), sur la RPC `classes_admin_page` (migration 20261016100000).
//
// Le serveur filtre, compte, pagine et numerote les classes paralleles ; il
// rend aussi les classes sans enseignant (R7) et les capacites de chaque
// ligne. Rien n'est recalcule ici : la ligne est lue telle qu'elle arrive.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import '../planning/service_planning.dart';
import 'port_classes_admin.dart';
import 'service_groupes.dart';

/// La liste des classes servie par Supabase.
class ClassesAdminSupabase implements PortClassesAdmin {
  /// Cree l'adaptateur sur le client de l'application.
  const ClassesAdminSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<PageClasses> page(
    FiltreClasses filtre, {
    required int page,
    required int taille,
  }) async {
    final Object? brut = await _client.rpc<Object?>(
      'classes_admin_page',
      params: parametresClassesAdmin(filtre, page: page, taille: taille),
    );
    if (brut is! Map) throw const FormatException('Objet attendu.');
    return pageClassesJson(Map<String, dynamic>.from(brut));
  }
}

/// Les parametres de `classes_admin_page` pour [filtre].
Map<String, dynamic> parametresClassesAdmin(
  FiltreClasses filtre, {
  required int page,
  required int taille,
}) {
  final String texte = filtre.texte.trim();
  final String? enseignant = filtre.enseignantId;
  return <String, dynamic>{
    'p_page': page < 1 ? 1 : page,
    'p_taille': taille,
    if (texte.isNotEmpty) 'p_texte': texte,
    if (filtre.type != null) 'p_type': filtre.type!.valeurSql,
    if (filtre.etat != null) 'p_etat': _etatSql(filtre.etat!),
    if (filtre.jour != null) 'p_jour': filtre.jour,
    if (filtre.heure != null) 'p_heure': filtre.heure,
    if (filtre.fuseau != null) 'p_fuseau': filtre.fuseau,
    if (filtre.genre != null) 'p_genre': filtre.genre!.name,
    if (enseignant == FiltreClasses.sansEnseignant)
      'p_sans_enseignant': true
    else
      'p_enseignant_id': ?enseignant,
    if (filtre.remplissage != null)
      'p_remplissage': switch (filtre.remplissage!) {
        RemplissageClasse.pleine => 'pleine',
        RemplissageClasse.avecPlaces => 'avec_places',
      },
  };
}

String _etatSql(EtatClasseListee e) => switch (e) {
  EtatClasseListee.active => 'active',
  EtatClasseListee.attenteEnseignant => 'attente_enseignant',
  EtatClasseListee.cloturee => 'cloturee',
};

/// Une page rendue par `classes_admin_page`.
PageClasses pageClassesJson(Map<String, dynamic> m) {
  final Map<String, dynamic> compteurs = m['compteurs'] is Map
      ? Map<String, dynamic>.from(m['compteurs'] as Map)
      : const <String, dynamic>{};
  return PageClasses(
    lignes: List<ClasseListee>.unmodifiable(<ClasseListee>[
      for (final Object? l in _liste(m['lignes'])) classeListeeJson(_objet(l)),
    ]),
    total: _entier(m['total']),
    page: _entier(m['page'], 1),
    taille: _entier(m['taille'], taillePageClasses),
    compteurs: <EtatClasseListee, int>{
      for (final EtatClasseListee e in EtatClasseListee.values)
        e: _entier(compteurs[_etatSql(e)]),
    },
    jours: <int>[
      for (final Object? j in _liste(m['jours']))
        if (j is num) j.toInt(),
    ],
    heures: <int>[
      for (final Object? h in _liste(m['heures']))
        if (h is num) h.toInt(),
    ],
    fuseaux: <String>[
      for (final Object? f in _liste(m['fuseaux']))
        if (f is String) f,
    ],
    enseignants: <EnseignantFiltre>[
      for (final Object? e in _liste(m['enseignants']))
        if (e is Map && e['id'] is String)
          (
            id: e['id'] as String,
            libelle: e['libelle'] is String ? e['libelle'] as String : '',
          ),
    ],
    genres: <GenreClasse>[
      for (final Object? g in _liste(m['genres']))
        if (_genre(g) case final GenreClasse genre) genre,
    ],
    totalSansFiltre: _entier(m['total_sans_filtre']),
  );
}

/// Une ligne de la page.
ClasseListee classeListeeJson(Map<String, dynamic> l) {
  final String? enseignant = l['teacher_id'] as String?;
  return ClasseListee(
    groupe: GroupeAdmin(
      id: l['groupe_id'] as String,
      libelle: l['libelle'] as String? ?? '',
      type: TypePublicGroupe.depuisSql(l['type_public'] as String?),
      seuilMax: _entier(l['seuil_max']),
      teacherId: enseignant ?? '',
      teacherIdentifiant: l['teacher_immutable_id'] as String? ?? '',
      teacherPrenom: l['teacher_prenom'] as String?,
      teacherNom: l['teacher_nom'] as String?,
      creneau: Creneau(
        jour: _entier(l['weekday']),
        heure: _entier(l['hour_local']),
        fuseau: l['timezone_iana'] as String? ?? 'Europe/Paris',
      ),
      nombreMembres: _entier(l['nombre_membres']),
      actif: l['actif'] == true,
    ),
    numeroDansFamille: (l['numero_dans_famille'] as num?)?.toInt(),
    codeCourt: l['code_court'] as String?,
    genre: _genre(l['genre']),
    sansEnseignant: l['sans_enseignant'] == true || enseignant == null,
    peutAffecterEnseignant: l['peut_affecter_enseignant'] == true,
    peutFusionner: l['peut_fusionner'] == true,
    peutTransferer: l['peut_transferer'] == true,
  );
}

GenreClasse? _genre(Object? v) => switch (v) {
  'hommes' => GenreClasse.hommes,
  'femmes' => GenreClasse.femmes,
  'indetermine' => GenreClasse.indetermine,
  // D1 (29/10/2026) : la liste dit « mixte » pour une classe mixte.
  'mixte' => GenreClasse.mixte,
  _ => null,
};

int _entier(Object? v, [int defaut = 0]) => v is num ? v.toInt() : defaut;

List<Object?> _liste(Object? v) => v is List ? v : const <Object?>[];

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('Objet attendu.');
  return Map<String, dynamic>.from(v);
}
