import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import '../planning/service_planning.dart';
import '../presence/service_presence.dart';

/// Le nombre de cours que le suivi lit d'un coup.
///
/// Une borne, et non une pagination : `TUT-06` repond a « comment se passent les
/// cours de mes enfants », pas « qu'est-ce qui s'est passe depuis deux ans ». A
/// raison de deux cours par semaine et par enfant, deux cents lignes couvrent
/// pres d'un an pour un enfant seul, et deux trimestres pour une fratrie de
/// trois. Au dela, l'ecran le dit en pied de liste plutot que de laisser croire
/// a un historique complet.
const int plafondSuiviFoyer = 200;

/// Ce que le suivi lit, et il ne fait que lire.
///
/// **Aucune vue neuve, et aucune migration.** Les deux lectures existaient
/// avant ce lot et etaient deja bornees a leur appelant : `mes_seances_v` rend
/// au tuteur les seances des enfants de son foyer depuis `0005`, et
/// `presence_seance_v` leurs lignes de presence depuis `0011` -- dont le corps
/// nomme `TUT-06`, parce que c'est pour lui que la borne du foyer y a ete
/// ecrite. Le client ne filtre donc **rien** par foyer : un filtre client
/// serait une decoration par-dessus une donnee deja livree, et il finirait par
/// diverger de la borne reelle.
///
/// **Le meme service servira le suivi eleve**, sans une ligne de plus : les
/// deux memes vues rendent alors sa seule seance et sa seule ligne de presence.
/// C'est la borne qui change d'appelant, pas la requete.
abstract interface class ServiceSuivi {
  /// Les cours du foyer, **le plus recent d'abord**.
  ///
  /// Le sens du tri s'ecrit toujours : `order()` de postgrest trie en
  /// descendant par defaut, et c'est exactement le piege qui avait inverse le
  /// feed de `ENS-06`. Ici le descendant est voulu, et c'est ecrit.
  ///
  /// [eleveId] : le profil de l'eleve dont on lit les cours. Donne, la requete
  /// porte `student_id = eleveId` (L2-04). `null` garde la lecture de tout le
  /// foyer, celle du tuteur ; la vue borne deja la lecture cote serveur (L1-04).
  Future<List<Seance>> seances({String? eleveId});

  /// La presence des membres du foyer sur ces memes cours.
  ///
  /// Rend `null` quand la lecture est **indisponible** : reseau coupe, lecture
  /// refusee, reponse illisible. `null` n'est pas une liste vide -- une liste
  /// vide dit « aucune ligne », `null` dit « je ne sais pas », et l'ecran
  /// affichera l'inconnu plutot qu'une absence (invariant J3).
  Future<List<PresenceParticipant>?> presences();
}

/// L'implementation reelle.
class ServiceSuiviSupabase implements ServiceSuivi {
  /// Cree le service.
  const ServiceSuiviSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Seance>> seances({String? eleveId}) async {
    // Lecture volontaire de tout le foyer (tuteur) quand [eleveId] est nul :
    // la vue filtre par role cote serveur (L1-04). Pour un eleve, le filtre
    // `student_id` est ajoute ici, pas dans l'appelant (L2-04).
    var requete = _client.from('mes_seances_v').select();
    if (eleveId != null) {
      requete = requete.eq('student_id', eleveId);
    }
    final List<Map<String, dynamic>> lignes = await requete
        .order('started_at', ascending: false)
        .limit(plafondSuiviFoyer);
    return lignes.map(Seance.depuisJson).toList();
  }

  @override
  Future<List<PresenceParticipant>?> presences() async {
    try {
      // Le meme ordre et le meme plafond que les seances, pour que les deux
      // lectures couvrent la meme fenetre : une presence lue sur une fenetre
      // plus courte laisserait les lignes les plus anciennes en « inconnu »
      // alors que la base sait y repondre. Un cours sans ligne rendue reste
      // affichable -- il dit l'inconnu, ce qui est exact.
      final List<Map<String, dynamic>> lignes = await _client
          .from('presence_seance_v')
          .select()
          .order('started_at', ascending: false)
          .limit(plafondSuiviFoyer);
      return lignes.map(PresenceParticipant.depuisJson).toList();
    } catch (erreur) {
      // Aucune exception ne remonte a l'ecran : un historique de cours ne
      // disparait pas parce que la presence n'a pas repondu. Les dates et les
      // enseignants restent lisibles, les etats disent « inconnu ».
      journalDev('presence du foyer indisponible : $erreur');
      return null;
    }
  }
}

/// Les cours de l'eleve connecte, le plus recent d'abord (L2-04).
///
/// Le profil vient de la session, jamais du role. Sans profil, la lecture
/// reste celle du foyer, bornee par la vue cote serveur (L1-04).
final FutureProvider<List<Seance>> seancesDeMonSuiviProvider =
    FutureProvider<List<Seance>>((Ref ref) {
      final String? eleveId = ref.watch(profilCourantProvider);
      return ref.watch(serviceSuiviProvider).seances(eleveId: eleveId);
    });

/// Le service de suivi employe par l'application.
final Provider<ServiceSuivi> serviceSuiviProvider = Provider<ServiceSuivi>(
  (Ref ref) => ServiceSuiviSupabase(Supabase.instance.client),
);

/// Les cours du foyer, le plus recent d'abord.
///
/// Lecture volontaire de tout le foyer (tuteur) : l'ecran de l'eleve utilise
/// [seancesDeMonSuiviProvider] (L2-04).
final FutureProvider<List<Seance>> seancesDuSuiviProvider =
    FutureProvider<List<Seance>>(
      (Ref ref) => ref.watch(serviceSuiviProvider).seances(),
    );

/// La presence du foyer sur ces cours.
final FutureProvider<List<PresenceParticipant>?> presenceDuSuiviProvider =
    FutureProvider<List<PresenceParticipant>?>(
      (Ref ref) => ref.watch(serviceSuiviProvider).presences(),
    );
