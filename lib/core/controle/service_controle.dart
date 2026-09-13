import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../planning/service_planning.dart';

/// Le nombre de seances que le planning global lit d'un coup.
///
/// Une borne, et non une pagination : `CTR-01` regarde ce qui se passe
/// maintenant et ce qui arrive ensuite, pas l'histoire de l'academie. Deux cents
/// seances a venir, c'est deja plusieurs semaines de production a l'echelle du
/// MVP-0 ; au dela, l'ecran le dit en pied de liste plutot que de faire croire a
/// une liste complete.
const int plafondPlanningGlobal = 200;

/// De combien une seance reste visible apres son heure de fin.
///
/// **Le meme quart d'heure que la base** : `autoriser_jeton_video()` accepte
/// jusqu'a `fin + 15 minutes` (ADR-005), et `rejoindre_observation()` reprend
/// cette borne mot pour mot. Un planning qui retirerait la ligne plus tot
/// masquerait une salle encore ouverte ; plus tard, il proposerait une porte
/// que le backend refuse.
const Duration graceApresFin = Duration(minutes: 15);

/// Ce que le controle qualite lit et ce qu'il peut faire.
///
/// **La lecture ne passe par aucune vue neuve** : `mes_seances_v` borne deja son
/// appelant et rend toutes les seances a l'administration et au controle
/// (`0005`). Une vue jumelle pour `CTR-01` finirait par afficher un autre etat
/// de la meme seance -- c'est exactement ce que `0005` avait refuse en
/// remplacant `family_sessions_v`.
/// L'entree dans la salle, elle, n'est pas ici : s'inscrire comme temoin est un
/// geste d'acces a la salle, et il vit avec les autres dans `ServiceVideo` --
/// aux cotes de la sortie volontaire et de la demande de jeton.
abstract interface class ServiceControle {
  /// Les seances en cours et a venir, la plus proche d'abord.
  Future<List<Seance>> planning();
}

/// L'implementation reelle.
class ServiceControleSupabase implements ServiceControle {
  /// Cree le service.
  const ServiceControleSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Seance>> planning() async {
    // La borne basse part de l'instant, jamais du debut du jour civil : une
    // seance de 23h40 doit rester lisible a 00h10, et le controle qualite d'une
    // academie a cheval sur trois fuseaux ne travaille pas par journees.
    final DateTime borne = DateTime.now().toUtc().subtract(graceApresFin);
    final List<Map<String, dynamic>> lignes = await _client
        .from('mes_seances_v')
        .select()
        .gte('ended_at', borne.toIso8601String())
        .order('started_at')
        .limit(plafondPlanningGlobal);
    return lignes.map(Seance.depuisJson).toList();
  }
}

/// Le service de controle employe par l'application.
final Provider<ServiceControle> serviceControleProvider =
    Provider<ServiceControle>(
      (Ref ref) => ServiceControleSupabase(Supabase.instance.client),
    );

/// Le planning global, relu a la demande.
final FutureProvider<List<Seance>> planningGlobalProvider =
    FutureProvider<List<Seance>>(
      (Ref ref) => ref.watch(serviceControleProvider).planning(),
    );
