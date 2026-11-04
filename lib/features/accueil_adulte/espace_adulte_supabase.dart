import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/planning/service_planning.dart';
import '../../core/tc_horloge/horloge_supabase.dart' show dateRendue;
import '../ma_classe_adulte/ma_classe_adulte_page.dart'
    show MaClasseAdulteVM, ParticipantClasseAdulte;
import 'accueil_adulte_page.dart' show AccueilAdulteVM, SeancePasseeAdulte;
import 'port_espace_adulte.dart';

/// La taille d'une page de l'historique : le plafond que
/// `seances_passees_eleve_adulte` applique (migration 20261102700000).
const int taillePageHistoriqueAdulte = 100;

/// Lit une ligne de `seances_passees_eleve_adulte` en seance passee.
///
/// **Pure**, testable sans client. Une ligne illisible (sans identifiant,
/// sans bornes, sans date rendue) est ecartee : `null`, jamais completee.
/// La date vient du serveur, dans le fuseau du compte ; elle n'est ici que
/// mise en mots (`dateRendue`).
SeancePasseeAdulte? seancePasseeDepuisLigne(Map<String, dynamic> ligne) {
  final Seance? seance = Seance.lire(ligne);
  final Object? jour = ligne['jour_iso'];
  final Object? date = ligne['date_locale'];
  if (seance == null || jour is! int || date is! String) {
    return null;
  }
  return SeancePasseeAdulte(
    seance: seance,
    dateRendue: dateRendue(jourIso: jour, dateIso: date),
    absence: ligne['absent'] == true,
  );
}

/// Lit une ligne de `participants_classe_eleve_adulte` en participant.
/// **Pure** ; une ligne sans identifiant ni prenom est ecartee.
ParticipantClasseAdulte? participantDepuisLigne(Map<String, dynamic> ligne) {
  final Object? id = ligne['profile_id'];
  final Object? prenom = ligne['prenom'];
  if (id is! String || prenom is! String) {
    return null;
  }
  return ParticipantClasseAdulte(
    id: id,
    prenom: prenom,
    cleAvatar: ligne['cle_avatar'] as String?,
    estMoi: ligne['est_moi'] == true,
  );
}

/// L'adaptateur reel du port de l'eleve adulte.
///
/// Trois lectures serveur, aucune ecriture (migration 20261102700000) :
/// `espace_eleve_adulte`, `seances_passees_eleve_adulte`,
/// `participants_classe_eleve_adulte`. Toutes partent de `auth.uid()` :
/// aucun identifiant ne part du client. Le droit est serveur
/// (`ma_capacite_eleve()`), jamais ici : un compte qui n'est pas eleve
/// autonome ne recoit aucune ligne, ce que l'adaptateur dit
/// `CapaciteIndisponible`.
class EspaceAdulteSupabase implements PortEspaceAdulte {
  /// Cree l'adaptateur.
  const EspaceAdulteSupabase(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> _espace(String capacite) async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'espace_eleve_adulte',
    );
    if (lignes.isEmpty || lignes.first is! Map<String, dynamic>) {
      throw CapaciteIndisponible(capacite);
    }
    return lignes.first as Map<String, dynamic>;
  }

  /// Une page brute de `seances_passees_eleve_adulte`.
  Future<List<Map<String, dynamic>>> _page({
    required int limite,
    DateTime? avant,
  }) async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'seances_passees_eleve_adulte',
      params: <String, Object?>{
        'p_limite': limite,
        'p_avant': avant?.toUtc().toIso8601String(),
      },
    );
    return <Map<String, dynamic>>[
      for (final Object? l in lignes)
        if (l is Map<String, dynamic>) l,
    ];
  }

  static List<SeancePasseeAdulte> _lire(List<Map<String, dynamic>> lignes) =>
      <SeancePasseeAdulte>[
        for (final Map<String, dynamic> l in lignes)
          if (seancePasseeDepuisLigne(l) case final SeancePasseeAdulte s) s,
      ];

  @override
  Future<AccueilAdulteVM> accueil({required int limite}) async {
    final Map<String, dynamic> espace = await _espace('accueil_eleve_adulte');
    final String? groupeId = espace['groupe_id'] as String?;
    return AccueilAdulteVM(
      prenom: (espace['prenom'] as String?) ?? '',
      groupeId: groupeId,
      dernieresSeances: _lire(await _page(limite: limite)),
    );
  }

  @override
  Future<MaClasseAdulteVM> maClasse() async {
    final Map<String, dynamic> espace = await _espace('ma_classe_eleve_adulte');
    final String? groupeId = espace['groupe_id'] as String?;
    if (groupeId == null) {
      return const MaClasseAdulteVM();
    }
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'participants_classe_eleve_adulte',
    );
    return MaClasseAdulteVM(
      groupeId: groupeId,
      participants: <ParticipantClasseAdulte>[
        for (final Object? l in lignes)
          if (l is Map<String, dynamic>)
            if (participantDepuisLigne(l) case final ParticipantClasseAdulte p)
              p,
      ],
    );
  }

  @override
  Future<List<SeancePasseeAdulte>> historique() async {
    await _espace('historique_seances_eleve_adulte');
    final List<SeancePasseeAdulte> toutes = <SeancePasseeAdulte>[];
    DateTime? avant;
    while (true) {
      final List<Map<String, dynamic>> page = await _page(
        limite: taillePageHistoriqueAdulte,
        avant: avant,
      );
      toutes.addAll(_lire(page));
      // La page suivante part du debut de la derniere ligne brute : une
      // ligne illisible ecartee ne doit pas arreter la lecture.
      final Object? dernier = page.isEmpty ? null : page.last['started_at'];
      final DateTime? debut = dernier is String
          ? DateTime.tryParse(dernier)
          : null;
      if (page.length < taillePageHistoriqueAdulte || debut == null) {
        return toutes;
      }
      avant = debut;
    }
  }
}
