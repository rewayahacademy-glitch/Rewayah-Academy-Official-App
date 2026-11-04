// SNT (03/11/2026) : l'adaptateur Supabase des seances reportees, sur les RPC
// `lister_seances_reportees` et `fixer_nouvelle_date_seance` (migration
// 20261106500000). Le serveur decide de tout ; l'adaptateur traduit ses
// reponses et ses refus, il ne calcule rien.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'creation_classe_refusee.dart' show conflitDuDetail;
import 'port_seances_reportees.dart';

/// Lit la liste rendue par `lister_seances_reportees`. Pure, pour les tests ;
/// une ligne illisible est ecartee, jamais completee.
List<SeanceReportee> seancesReporteesDepuisJson(
  Object? reponse,
) => <SeanceReportee>[
  for (final Object? l in reponse is List ? reponse : const <Object?>[])
    if (l is Map)
      if ((DateTime.tryParse('${l['debut']}'), DateTime.tryParse('${l['fin']}'))
          case (final DateTime debut, final DateTime fin))
        SeanceReportee(
          id: '${l['id']}',
          seanceId: '${l['session_id']}',
          classe: l['classe'] as String? ?? '',
          debut: debut.toUtc(),
          fin: fin.toUtc(),
          fuseau: l['fuseau'] as String? ?? 'UTC',
          enseignant: (l['enseignant'] as String? ?? '').trim(),
        ),
];

/// Le refus du serveur, d'apres son code et son message. Pure, pour les
/// tests.
NouvelleDateRefusee refusNouvelleDate({
  required String? code,
  required String message,
  String? detail,
}) {
  if (message.startsWith('chevauchement avec une séance existante') ||
      code == '23P01') {
    return NouvelleDateRefusee(
      MotifNouvelleDateRefusee.chevauchement,
      conflit: conflitDuDetail(detail),
    );
  }
  return NouvelleDateRefusee(switch (message) {
    'NouvelleDateInvalide' => MotifNouvelleDateRefusee.datePassee,
    'NouvelleDateDejaFixee' => MotifNouvelleDateRefusee.dejaFixee,
    'SeanceReporteeIntrouvable' => MotifNouvelleDateRefusee.dejaFixee,
    'ClasseClose' => MotifNouvelleDateRefusee.classeClose,
    'NouvelleDateNonAutorisee' => MotifNouvelleDateRefusee.nonAutorisee,
    _ =>
      code == '42501'
          ? MotifNouvelleDateRefusee.nonAutorisee
          : MotifNouvelleDateRefusee.inconnu,
  });
}

/// Les seances reportees servies par Supabase.
class SeancesReporteesSupabase implements PortSeancesReportees {
  /// Cree l'adaptateur.
  const SeancesReporteesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SeanceReportee>> lister() async => seancesReporteesDepuisJson(
    await _client.rpc<Object?>('lister_seances_reportees'),
  );

  @override
  Future<String> fixer({
    required String reportId,
    required DateTime debut,
  }) async {
    try {
      final Object? id = await _client.rpc<Object?>(
        'fixer_nouvelle_date_seance',
        params: <String, dynamic>{
          'p_report': reportId,
          'p_debut': debut.toUtc().toIso8601String(),
        },
      );
      if (id is String && id.isNotEmpty) return id;
      throw const FormatException('Réponse de nouvelle date inconnue');
    } on PostgrestException catch (e) {
      throw refusNouvelleDate(
        code: e.code,
        message: e.message,
        detail: e.details?.toString(),
      );
    }
  }
}
