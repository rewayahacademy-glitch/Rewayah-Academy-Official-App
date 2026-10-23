import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import 'service_suivi.dart';

/// La classe de chaque seance du foyer, lue dans `sessions.groupe_id`
/// (Historique du tuteur, lot E du chantier Tuteur V1).
///
/// **Pourquoi une lecture a part.** `mes_seances_v` n'expose pas la classe
/// (DB-CRS-13). Le foyer lit pourtant `sessions` (policy
/// `sessions_family_read`, `0001:1000-1005`), et `sessions.groupe_id` existe
/// depuis `0025`. Le libelle de la classe vient ensuite des classes COURANTES
/// du foyer (`mes_groupes_famille_v`) : une classe quittee reste « Classe non
/// disponible », jamais devinee. La vue dediee reste la solution propre
/// (DB-CRS-13) ; cette lecture n'invente rien en attendant.
///
/// Elle vit hors de `ServiceSuivi` pour ne pas changer une interface que
/// l'eleve et les doubles de test partagent.
abstract interface class ServiceGroupesSeances {
  /// Seance vers classe, sur la meme fenetre que le suivi (les plus recentes
  /// d'abord, plafond [plafondSuiviFoyer]). `null` quand la lecture est
  /// indisponible : l'ecran dit alors « Classe non disponible », jamais une
  /// erreur d'ecran.
  Future<Map<String, String>?> groupesDesSeances();
}

/// L'implementation reelle, sous RLS.
class ServiceGroupesSeancesSupabase implements ServiceGroupesSeances {
  /// Cree le service. Le client est lu a la demande : un ecran monte sans
  /// Supabase initialise (test, galerie) obtient `null`, pas une exception.
  const ServiceGroupesSeancesSupabase(this._client);

  final SupabaseClient Function() _client;

  @override
  Future<Map<String, String>?> groupesDesSeances() async {
    try {
      // Le sens du tri s'ecrit : postgrest trie en DESCENDANT sans consigne
      // (registre, section 1 ter bis). Ici le descendant est voulu, pour
      // couvrir la meme fenetre que `mes_seances_v`.
      final List<Map<String, dynamic>> lignes = await _client()
          .from('sessions')
          .select('id, groupe_id')
          .order('started_at', ascending: false)
          .limit(plafondSuiviFoyer);
      return groupesDepuisLignes(lignes);
    } catch (erreur) {
      // Aucune exception ne remonte : la classe est un complement de la
      // ligne, pas une condition de son affichage.
      journalDev('classes des seances indisponibles : ${erreur.runtimeType}');
      return null;
    }
  }
}

/// Lit les lignes `sessions` en table seance vers classe. Une ligne sans
/// classe (seance individuelle d'avant les classes) est ignoree.
@visibleForTesting
Map<String, String> groupesDepuisLignes(
  Iterable<Map<String, dynamic>> lignes,
) => <String, String>{
  for (final Map<String, dynamic> ligne in lignes)
    if (ligne['id'] case final String id)
      if (ligne['groupe_id'] case final String groupe) id: groupe,
};

/// Le service employe par l'application.
final Provider<ServiceGroupesSeances> serviceGroupesSeancesProvider =
    Provider<ServiceGroupesSeances>(
      (Ref ref) =>
          ServiceGroupesSeancesSupabase(() => Supabase.instance.client),
    );

/// Seance vers classe, `null` si indisponible.
final FutureProvider<Map<String, String>?> groupesDesSeancesProvider =
    FutureProvider<Map<String, String>?>(
      (Ref ref) => ref.watch(serviceGroupesSeancesProvider).groupesDesSeances(),
    );
