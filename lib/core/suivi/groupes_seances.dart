import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import 'service_suivi.dart';

/// La classe de chaque seance du foyer : son identifiant et son nom
/// (Historique du tuteur, lot E du chantier Tuteur V1 ; point 4 du pilote,
/// 07/11/2026).
///
/// **Le nom vient avec la seance, cote serveur.** Avant le point 4, le nom
/// se cherchait parmi les classes COURANTES du foyer (`mes_groupes_famille_v`) :
/// une seance d'une Classe quittee ou close perdait son nom (« Classe non
/// disponible »), alors que chaque seance porte son `groupe_id`. Depuis la
/// migration `20261110900000`, `mes_seances_v` rend `groupe_id` et
/// `groupe_libelle`, sous la meme garde que la lecture de l'Historique.
///
/// **Repli.** Tant que la migration n'est pas installee, la lecture de ces
/// colonnes echoue : on retombe sur l'ancienne lecture de `sessions.groupe_id`
/// (policy `sessions_family_read`), identifiants seuls. Rien n'est devine.
///
/// Elle vit hors de `ServiceSuivi` pour ne pas changer une interface que
/// l'eleve et les doubles de test partagent.
@immutable
class ClasseDUneSeance {
  /// Cree la classe d'une seance.
  const ClasseDUneSeance({required this.groupeId, this.libelle});

  /// L'identifiant de la Classe (`sessions.groupe_id`).
  final String groupeId;

  /// Son nom (`groupes.libelle`), nul quand la lecture ne le donne pas.
  final String? libelle;
}

abstract interface class ServiceGroupesSeances {
  /// Seance vers classe, sur la meme fenetre que le suivi (les plus recentes
  /// d'abord, plafond [plafondSuiviFoyer]). `null` quand la lecture est
  /// indisponible : l'ecran dit alors « Classe non disponible », jamais une
  /// erreur d'ecran.
  Future<Map<String, ClasseDUneSeance>?> classesDesSeances();
}

/// L'implementation reelle, sous RLS.
class ServiceGroupesSeancesSupabase implements ServiceGroupesSeances {
  /// Cree le service. Le client est lu a la demande : un ecran monte sans
  /// Supabase initialise (test, galerie) obtient `null`, pas une exception.
  const ServiceGroupesSeancesSupabase(this._client);

  final SupabaseClient Function() _client;

  @override
  Future<Map<String, ClasseDUneSeance>?> classesDesSeances() async {
    try {
      // Le sens du tri s'ecrit : postgrest trie en DESCENDANT sans consigne
      // (registre, section 1 ter bis). Ici le descendant est voulu, pour
      // couvrir la meme fenetre que le suivi.
      final List<Map<String, dynamic>> lignes = await _client()
          .from('mes_seances_v')
          .select('session_id, groupe_id, groupe_libelle')
          .order('started_at', ascending: false)
          .limit(plafondSuiviFoyer);
      return classesDepuisVue(lignes);
    } catch (erreur) {
      journalDev(
        'nom des classes des seances indisponible : ${erreur.runtimeType}',
      );
    }
    try {
      final List<Map<String, dynamic>> lignes = await _client()
          .from('sessions')
          .select('id, groupe_id')
          .order('started_at', ascending: false)
          .limit(plafondSuiviFoyer);
      return <String, ClasseDUneSeance>{
        for (final MapEntry<String, String> e in groupesDepuisLignes(
          lignes,
        ).entries)
          e.key: ClasseDUneSeance(groupeId: e.value),
      };
    } catch (erreur) {
      // Aucune exception ne remonte : la classe est un complement de la
      // ligne, pas une condition de son affichage.
      journalDev('classes des seances indisponibles : ${erreur.runtimeType}');
      return null;
    }
  }
}

/// Lit les lignes de `mes_seances_v` (point 4) en table seance vers classe.
/// Une ligne sans classe (seance individuelle) est ignoree ; un nom vide ne
/// compte pas.
@visibleForTesting
Map<String, ClasseDUneSeance> classesDepuisVue(
  Iterable<Map<String, dynamic>> lignes,
) => <String, ClasseDUneSeance>{
  for (final Map<String, dynamic> ligne in lignes)
    if (ligne['session_id'] case final String id)
      if (ligne['groupe_id'] case final String groupe)
        id: ClasseDUneSeance(
          groupeId: groupe,
          libelle: switch (ligne['groupe_libelle']) {
            final String nom when nom.trim().isNotEmpty => nom,
            _ => null,
          },
        ),
};

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

/// Seance vers classe (identifiant et nom), `null` si indisponible.
final FutureProvider<Map<String, ClasseDUneSeance>?> groupesDesSeancesProvider =
    FutureProvider<Map<String, ClasseDUneSeance>?>(
      (Ref ref) => ref.watch(serviceGroupesSeancesProvider).classesDesSeances(),
    );
