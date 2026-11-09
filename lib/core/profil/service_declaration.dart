import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce qu'un enseignant peut corriger lui-meme dans son profil professionnel.
///
/// **Trois champs, pas un de plus.** `teacher_profiles` porte aussi
/// `weekly_hours_cap` et `kyc_status`, qui sont contractuels : ils se lisent a
/// l'ecran et ne s'ecrivent jamais d'ici. La borne n'est pas tenue par cette
/// interface -- une interface ne borne rien -- mais par la fonction SQL
/// `maj_profil_enseignant`, qui nomme les trois colonnes et ignore le reste.
///
/// Pourquoi une fonction et non une policy `UPDATE` : une policy borne les
/// LIGNES, pas les COLONNES. Bornee a `profile_id = auth.uid()`, elle aurait
/// laisse l'enseignant relever son propre plafond hebdomadaire.
abstract interface class ServiceDeclarationEnseignant {
  /// Ecrit les champs fournis, laisse les autres inchanges.
  ///
  /// Un parametre nul signifie « ne touche pas a ce champ », jamais « efface » :
  /// la fonction SQL applique un `coalesce` sur la valeur existante.
  Future<void> declarer({String? pays, List<String>? langues});
}

/// Ecriture Supabase, par l'unique porte ouverte au titulaire.
class ServiceDeclarationEnseignantSupabase
    implements ServiceDeclarationEnseignant {
  /// Cree le service a partir d'un client Supabase.
  const ServiceDeclarationEnseignantSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<void> declarer({String? pays, List<String>? langues}) =>
      _client.rpc<void>(
        'maj_profil_enseignant',
        // Marqueur null-aware plutot qu'un `if` : l'entree disparait quand la
        // valeur est nulle, ce qui est exactement ce que la RPC attend -- un
        // parametre absent laisse la colonne inchangee par son `coalesce`.
        params: <String, dynamic>{
          'p_country': ?pays,
          'p_languages': ?langues,
        },
      );
}

/// Le service de declaration employe par l'application.
final Provider<ServiceDeclarationEnseignant> serviceDeclarationProvider =
    Provider<ServiceDeclarationEnseignant>(
      (Ref ref) =>
          ServiceDeclarationEnseignantSupabase(Supabase.instance.client),
    );
