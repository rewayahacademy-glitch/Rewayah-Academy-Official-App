// L'adaptateur Supabase du tableau de pilotage de la direction (R7, R9,
// R17, R19), sur la RPC `pilotage_admin_page` (migration 20261016100200).
//
// Le serveur calcule chaque ligne (classes, remplissage, demandes,
// enseignants libres et manquants par genre), le tri, le resume et les
// compteurs. Rien n'est recalcule ici.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import '../planning/service_planning.dart' show Creneau;
import 'port_pilotage.dart';
import 'service_groupes.dart' show TypePublicGroupe;

/// Le tableau de pilotage servi par Supabase.
class PilotageSupabase implements PortPilotage {
  /// Cree l'adaptateur sur le client de l'application.
  const PilotageSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<PagePilotage> page(
    FiltrePilotage filtre, {
    required int page,
    required int taille,
  }) async {
    final Object? brut = await _client.rpc<Object?>(
      'pilotage_admin_page',
      params: parametresPilotage(filtre, page: page, taille: taille),
    );
    if (brut is! Map) throw const FormatException('Objet attendu.');
    return pagePilotageJson(Map<String, dynamic>.from(brut));
  }
}

/// Les parametres de `pilotage_admin_page` pour [filtre].
Map<String, dynamic> parametresPilotage(
  FiltrePilotage filtre, {
  required int page,
  required int taille,
}) => <String, dynamic>{
  'p_page': page < 1 ? 1 : page,
  'p_taille': taille,
  if (filtre.type != null) 'p_type': filtre.type!.valeurSql,
  if (filtre.jour != null) 'p_jour': filtre.jour,
  if (filtre.heure != null) 'p_heure': filtre.heure,
  if (filtre.fuseau != null) 'p_fuseau': filtre.fuseau,
  if (filtre.signal != null) 'p_signal': _signalSql(filtre.signal!),
};

String _signalSql(SignalPilotage s) => switch (s) {
  SignalPilotage.penurie => 'penurie',
  SignalPilotage.sousMinimum => 'sous_minimum',
  SignalPilotage.attenteEnseignant => 'attente_enseignant',
};

/// Une page rendue par `pilotage_admin_page`.
PagePilotage pagePilotageJson(Map<String, dynamic> m) {
  final Map<String, dynamic> r = _objetOuVide(m['resume']);
  final Map<String, dynamic> c = _objetOuVide(m['compteurs']);
  return PagePilotage(
    lignes: List<LignePilotage>.unmodifiable(<LignePilotage>[
      for (final Object? l in _liste(m['lignes'])) lignePilotageJson(_objet(l)),
    ]),
    total: _entier(m['total']),
    page: _entier(m['page'], 1),
    taille: _entier(m['taille'], taillePagePilotage),
    resume: ResumePilotage(
      classes: _entier(r['classes']),
      classesAttenteEnseignant: _entier(r['classes_attente_enseignant']),
      classesSousMinimum: _entier(r['classes_sous_minimum']),
      demandesEnAttente: _entier(r['demandes_en_attente']),
      enseignantsLibres: _entier(r['enseignants_libres']),
      enseignantsManquants: _entier(r['enseignants_manquants']),
    ),
    compteurs: <SignalPilotage, int>{
      for (final SignalPilotage s in SignalPilotage.values)
        s: _entier(c[_signalSql(s)]),
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
    totalSansFiltre: _entier(m['total_sans_filtre']),
  );
}

/// Une ligne du tableau.
LignePilotage lignePilotageJson(Map<String, dynamic> l) => LignePilotage(
  id: '${l['id']}',
  creneau: Creneau(
    jour: _entier(l['jour']),
    heure: _entier(l['heure']),
    fuseau: l['fuseau'] as String? ?? 'Europe/Paris',
  ),
  type: TypePublicGroupe.depuisSql(l['type'] as String?),
  classes: _entier(l['classes']),
  effectif: _entier(l['effectif']),
  capacite: _entier(l['capacite']),
  classesSousMinimum: _entier(l['classes_sous_minimum']),
  classesAttenteEnseignant: _entier(l['classes_attente_enseignant']),
  demandesEnAttente: _entier(l['demandes_en_attente']),
  parGenre: List<EnseignantsGenre>.unmodifiable(<EnseignantsGenre>[
    for (final Object? g in _liste(l['par_genre']))
      if (g is Map)
        if (_genre(g['genre']) case final GenreClasse genre)
          EnseignantsGenre(
            genre: genre,
            libres: _entier(g['libres']),
            manquants: _entier(g['manquants']),
          ),
  ]),
);

GenreClasse? _genre(Object? v) => switch (v) {
  'hommes' => GenreClasse.hommes,
  'femmes' => GenreClasse.femmes,
  'indetermine' => GenreClasse.indetermine,
  _ => null,
};

int _entier(Object? v, [int defaut = 0]) => v is num ? v.toInt() : defaut;

List<Object?> _liste(Object? v) => v is List ? v : const <Object?>[];

Map<String, dynamic> _objetOuVide(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('Objet attendu.');
  return Map<String, dynamic>.from(v);
}
