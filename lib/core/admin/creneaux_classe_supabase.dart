import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/creation_classe_supabase.dart' show genreClasseSql;
import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import '../offres/affectation_refusee.dart';
import 'creneaux_classe.dart';

/// L'adaptateur des creneaux d'une Classe (`ajouter_creneau_classe_admin`,
/// `modifier_creneau_classe_admin`, `retirer_creneau_classe_admin`,
/// `regler_genre_classe_admin`, lecture de `groupe_creneaux` sous la
/// politique de la direction).
class CreneauxClasseSupabase implements ServiceCreneauxClasse {
  /// Cree l'adaptateur.
  const CreneauxClasseSupabase(this._client);

  final SupabaseClient _client;

  /// Un refus du predicat (P0001, chevauchement 23P01) arrive en
  /// [AffectationRefusee], un refus du geste en [CreneauRefuse], jamais avec
  /// le texte SQL ; les autres erreurs (droit, reseau) passent telles
  /// quelles.
  Future<T> _traduire<T>(Future<T> Function() appel) async {
    try {
      return await appel();
    } on PostgrestException catch (e) {
      final String message = e.message;
      final MotifRefusCreneau? geste = message.startsWith('DernierCreneau')
          ? MotifRefusCreneau.dernier
          : message.startsWith('CreneauExistant')
          ? MotifRefusCreneau.existant
          : message.startsWith('CreneauIntrouvable')
          ? MotifRefusCreneau.introuvable
          : message.startsWith('ClasseIndisponible')
          ? MotifRefusCreneau.classeFermee
          : null;
      if (geste != null) throw CreneauRefuse(geste);
      final MotifRefusAffectation? motif = motifRefusDeplacementClasse(
        code: e.code,
        message: message,
      );
      if (motif == null) rethrow;
      throw AffectationRefusee(motif);
    }
  }

  @override
  Future<int> ajouter({
    required String groupeId,
    required int jour,
    required int heure,
  }) => _traduire<int>(() async {
    final int? n = await _client.rpc<int?>(
      'ajouter_creneau_classe_admin',
      params: <String, dynamic>{
        'p_groupe_id': groupeId,
        'p_weekday': jour,
        'p_hour_local': heure,
      },
    );
    return n ?? 0;
  });

  @override
  Future<List<CreneauClasse>> lister(String groupeId) async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('groupe_creneaux')
        .select('weekday, hour_local')
        .eq('groupe_id', groupeId)
        .order('weekday')
        .order('hour_local');
    return <CreneauClasse>[
      for (final Map<String, dynamic> l in lignes)
        (
          jour: (l['weekday'] as num).toInt(),
          heure: (l['hour_local'] as num).toInt(),
        ),
    ];
  }

  @override
  Future<int> modifier({
    required String groupeId,
    required CreneauClasse ancien,
    required CreneauClasse nouveau,
    required String motif,
  }) => _traduire<int>(() async {
    final int? n = await _client.rpc<int?>(
      'modifier_creneau_classe_admin',
      params: <String, dynamic>{
        'p_groupe_id': groupeId,
        'p_weekday': ancien.jour,
        'p_hour_local': ancien.heure,
        'p_nouveau_weekday': nouveau.jour,
        'p_nouvelle_heure': nouveau.heure,
        'p_motif': motif,
      },
    );
    return n ?? 0;
  });

  @override
  Future<int> retirer({
    required String groupeId,
    required CreneauClasse creneau,
    required String motif,
  }) => _traduire<int>(() async {
    final int? n = await _client.rpc<int?>(
      'retirer_creneau_classe_admin',
      params: <String, dynamic>{
        'p_groupe_id': groupeId,
        'p_weekday': creneau.jour,
        'p_hour_local': creneau.heure,
        'p_motif': motif,
      },
    );
    return n ?? 0;
  });

  @override
  Future<void> reglerGenre({
    required String groupeId,
    required GenreClasse genre,
    required String motif,
  }) => _traduire<void>(
    () => _client.rpc<void>(
      'regler_genre_classe_admin',
      params: <String, dynamic>{
        'p_groupe_id': groupeId,
        'p_genre': genreClasseSql(genre),
        'p_motif': motif,
      },
    ),
  );
}
