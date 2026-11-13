// CAMARADES (directeur, 12/11/2026) : « il faut que les autres eleves voient
// celui qui recite, au moins une partie du nom, la photo, car ils partagent
// une salle ». Chaque eleve, enfant compris, lit le PRENOM des membres de sa
// Classe (jamais le nom de famille) ; la photo est deja ouverte par K-44.
//
// Le port de cette lecture et sa forme pure. Le serveur decide qui lit quoi
// (`camarades_classe_eleve()`, migration 20261124300000) ; l'ecran ne fait
// que relier l'identite LiveKit (le profil) au prenom rendu.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'annuaire_seance.dart' show CamaradeSeance;

/// La lecture des prenoms de la Classe de l'eleve connecte.
abstract interface class PortCamaradesSalle {
  /// Les camarades de la Classe active de l'eleve connecte (soi exclu),
  /// prenom seul. Vide quand le serveur ne rend rien (pas de Classe, lecture
  /// pas encore installee).
  Future<List<CamaradeSeance>> camarades();
}

/// Hors production (demonstration, tests) : aucun prenom.
class CamaradesSalleAbsents implements PortCamaradesSalle {
  /// Cree le port vide.
  const CamaradesSalleAbsents();

  @override
  Future<List<CamaradeSeance>> camarades() async => const <CamaradeSeance>[];
}

/// Le port, surcharge en production par `CamaradesSalleSupabase`.
final Provider<PortCamaradesSalle> portCamaradesSalleProvider =
    Provider<PortCamaradesSalle>((Ref _) => const CamaradesSalleAbsents());

/// Les camarades de l'eleve connecte. Lu par la salle seulement chez un
/// eleve. Aucune relance automatique : un echec laisse les cadres sans nom
/// (la photo reste), jamais une erreur montree en pleine seance.
final FutureProvider<List<CamaradeSeance>> camaradesSalleProvider =
    FutureProvider<List<CamaradeSeance>>(
      (Ref ref) => ref.watch(portCamaradesSalleProvider).camarades(),
      retry: (int _, Object _) => null,
    );

/// Lit la reponse de `camarades_classe_eleve` (ou de l'ancienne
/// `participants_classe_eleve_adulte`) en camarades. **Pure.** Soi-meme
/// (`est_moi`) est ecarte ; une ligne sans identifiant ni prenom aussi. Le
/// prenom est garde tel quel : deux camarades du meme prenom ne sont pas
/// departages (aucun nom de famille, aucune initiale inventee).
List<CamaradeSeance> camaradesDepuisReponse(Object? brut) {
  if (brut is! List) return const <CamaradeSeance>[];
  return <CamaradeSeance>[
    for (final Object? ligne in brut)
      if (ligne is Map)
        if ((ligne['profile_id'], ligne['prenom'], ligne['est_moi'])
            case (
              final String id,
              final String prenom,
              final Object? moi,
            ) when id.isNotEmpty && prenom.trim().isNotEmpty && moi != true)
          (id: id, prenom: prenom.trim()),
  ];
}
