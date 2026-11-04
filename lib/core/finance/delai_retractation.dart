import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// REMB-14 (decision du directeur du 02/11/2026, DECISION-TARIFS-2026-10-18) :
/// le delai de retractation, en jours a compter du paiement, tel que la
/// politique commerciale en vigueur le publie (`remboursement_delai_jours`).
///
/// **Rien n'est en dur** : le texte « Annulation et remboursement » affiche
/// ce nombre. Non lu (hors ligne, lecture en erreur, base d'avant la
/// migration 20261106100000), il retombe sur une phrase sans duree, jamais
/// sur un nombre invente. Meme modele que le representant dans l'Union
/// europeenne.
abstract interface class PortDelaiRetractation {
  /// Le delai en jours, ou `null` si la politique ne le publie pas. Leve si
  /// la lecture n'a pas abouti.
  Future<int?> lire();
}

/// L'adaptateur reel : `tarifs_publics()`, ouverte sans connexion (la page
/// juridique s'ouvre aussi depuis l'ecran de connexion).
class DelaiRetractationSupabase implements PortDelaiRetractation {
  /// Cree l'adaptateur.
  const DelaiRetractationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<int?> lire() async {
    final Object? reponse = await _client.rpc<Object?>('tarifs_publics');
    return delaiDepuisTarifs(reponse);
  }
}

/// Le delai lu dans la reponse de `tarifs_publics()` (politique `courante`),
/// ou `null` : absent, d'un autre type ou hors des bornes de la base (0 a 60).
int? delaiDepuisTarifs(Object? reponse) {
  if (reponse is! Map) return null;
  final Object? courante = reponse['courante'];
  if (courante is! Map) return null;
  final Object? jours = courante['remboursementDelaiJours'];
  if (jours is! int || jours < 0 || jours > 60) return null;
  return jours;
}

/// Le port employe par l'application.
final Provider<PortDelaiRetractation> portDelaiRetractationProvider =
    Provider<PortDelaiRetractation>(
      (Ref ref) => DelaiRetractationSupabase(Supabase.instance.client),
    );

/// Le delai de retractation de la politique en vigueur.
final FutureProvider<int?> delaiRetractationProvider = FutureProvider<int?>(
  (Ref ref) => ref.watch(portDelaiRetractationProvider).lire(),
);
