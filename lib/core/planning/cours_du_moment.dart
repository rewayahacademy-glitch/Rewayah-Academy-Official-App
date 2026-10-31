/// Le cours du moment de chaque Classe, meme sans seance en base (defaut du
/// 30/10/2026 : une Classe creee pendant son creneau n'apparaissait ni sur
/// « Aujourd'hui » ni sur « Classes »).
///
/// `cours_du_moment_mes_classes()` (migration `20261101100100`) rend, pour
/// chaque Classe de l'appelant, la ligne de `horloge_classe` : la prochaine
/// seance vivante ou la prochaine occurrence d'un creneau dont le cours n'est
/// pas fini. Debut, fin et fenetre viennent du serveur ; rien ici ne calcule
/// un horaire. La lecture ne cree aucune seance : le concierge
/// (`seance_a_rejoindre`) la cree a l'appui sur « Rejoindre ».
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'service_planning.dart';

/// Lit `cours_du_moment_mes_classes()`. Tant que la migration n'est pas
/// appliquee (fonction absente), aucune ligne : les ecrans gardent les
/// seances deja creees.
Future<List<Map<String, dynamic>>> lireCoursDuMoment(
  SupabaseClient client,
) async {
  try {
    final List<dynamic> lignes = await client.rpc<List<dynamic>>(
      'cours_du_moment_mes_classes',
    );
    return lignes.cast<Map<String, dynamic>>();
  } on PostgrestException catch (e) {
    if (e.code == 'PGRST202' || e.code == '42883') {
      return const <Map<String, dynamic>>[];
    }
    rethrow;
  }
}

/// Les lignes du cours du moment de l'appelant connecte.
final FutureProvider<List<Map<String, dynamic>>> coursDuMomentProvider =
    FutureProvider<List<Map<String, dynamic>>>(
      (Ref _) => lireCoursDuMoment(Supabase.instance.client),
    );

/// Vrai pour une ligne dont la seance n'existe pas encore et dont les bornes
/// sont lisibles.
bool estCoursSansSeance(Map<String, dynamic> ligne) =>
    ligne['session_id'] == null &&
    ligne['groupe_id'] is String &&
    DateTime.tryParse(ligne['debut_utc'] as String? ?? '') != null &&
    DateTime.tryParse(ligne['fin_prevue_utc'] as String? ?? '') != null;

/// Ajoute aux [seances] de l'eleve le cours du moment de ses Classes qui n'a
/// pas encore de seance en base, sauf si une de ses seances commence deja au
/// meme instant (`mes_seances_v` ne porte pas la Classe). Trie par debut.
List<Seance> avecCoursSansSeanceEleve(
  List<Seance> seances,
  List<Map<String, dynamic>> coursDuMoment,
) {
  final List<Seance> nouveaux =
      <Seance>[
        for (final Map<String, dynamic> ligne in coursDuMoment)
          if (estCoursSansSeance(ligne)) Seance.coursSansSeance(ligne),
      ]..removeWhere(
        (Seance a) =>
            seances.any((Seance s) => s.debut.isAtSameMomentAs(a.debut)),
      );
  if (nouveaux.isEmpty) return seances;
  return <Seance>[...seances, ...nouveaux]
    ..sort((Seance a, Seance b) => a.debut.compareTo(b.debut));
}
