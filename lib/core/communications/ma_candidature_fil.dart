// L'identifiant de MA candidature, pour ouvrir son fil (MESSAGES-CANDIDAT,
// CAND-Q06). Le client ne le lit nulle part ailleurs : `etat_dossier()` ne le
// rend pas. Le serveur (`com_ma_candidature`) ne rend que la candidature de la
// personne connectee ; un identifiant n'est jamais une autorisation, le fil se
// confronte aux paires recalculees par le serveur.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'communications_supabase.dart';

/// La lecture de l'identifiant de ma candidature.
typedef LireMaCandidatureId = Future<String?> Function();

/// La lecture employee par l'application : neutre tant que `main.dart` ne
/// branche pas le serveur (capacite indisponible : rien n'est rendu).
final Provider<LireMaCandidatureId> lireMaCandidatureIdProvider =
    Provider<LireMaCandidatureId>(
      (Ref ref) =>
          () => Future<String?>.error(
            const CapaciteIndisponible('MESSAGES-CANDIDAT'),
          ),
    );

/// L'identifiant de ma candidature, `null` si la personne n'en a pas.
final FutureProvider<String?> maCandidatureIdProvider = FutureProvider<String?>(
  (Ref ref) => ref.watch(lireMaCandidatureIdProvider)(),
  retry: (int retryCount, Object error) => null,
);

/// La lecture servie par Supabase (`com_ma_candidature`).
LireMaCandidatureId lireMaCandidatureIdSupabase(AppelRpc appel) => () async {
  try {
    final Object? v = await appel(
      'com_ma_candidature',
      const <String, dynamic>{},
    );
    return v is String && estUuid(v) ? v : null;
  } on Object catch (e) {
    if (estRefusOuAbsence(e)) {
      throw const CapaciteIndisponible('MESSAGES-CANDIDAT');
    }
    rethrow;
  }
};
