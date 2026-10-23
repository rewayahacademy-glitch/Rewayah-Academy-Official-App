// Les prerequis de l'enseignant connecte (ENS-01), lus par la RPC
// `prerequis_enseignant` (migration 20261016100500). Le serveur calcule les
// quatre elements ; rien n'est deduit ici (E6).

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bienvenue_page.dart';

/// Lit les prerequis sur [client].
Future<PrerequisEnseignant> lirePrerequisEnseignant(
  SupabaseClient client,
) async {
  final Object? brut = await client.rpc<Object?>('prerequis_enseignant');
  if (brut is! Map) throw const FormatException('Objet attendu.');
  return prerequisEnseignantJson(Map<String, dynamic>.from(brut));
}

/// La reponse de `prerequis_enseignant`.
PrerequisEnseignant prerequisEnseignantJson(Map<String, dynamic> m) =>
    PrerequisEnseignant(
      photo: m['photo'] == true,
      langues: m['langues'] == true,
      fuseau: m['fuseau'] == true,
      disponibilites: m['disponibilites'] == true,
    );

/// La lecture serveur des prerequis. Aucune retentative automatique.
final FutureProvider<PrerequisEnseignant> prerequisEnseignantServeurProvider =
    FutureProvider<PrerequisEnseignant>(
      (Ref ref) => lirePrerequisEnseignant(Supabase.instance.client),
      retry: (int _, Object _) => null,
    );

/// Le branchement de [prerequisEnseignantProvider] : la valeur lue des
/// qu'elle arrive ; `null` pendant la lecture ou en echec, et la carte
/// « A completer » n'est alors pas affichee (jamais un etat suppose).
Override surchargePrerequisEnseignant() =>
    prerequisEnseignantProvider.overrideWith(
      (Ref ref) => ref.watch(prerequisEnseignantServeurProvider).value,
    );
