import 'package:flutter_riverpod/flutter_riverpod.dart';
// `StreamProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` : meme convention que `service_planning.dart`.
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, StreamProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'demonstration_horloge.dart';
import 'horloge_supabase.dart';
import 'session_clock_vm.dart';

/// L'acces au temps d'une seance.
///
/// **Toutes les conversions sont resolues cote serveur.** Le port rend des
/// horloges deja rendues : le client n'a aucun moyen de convertir un fuseau
/// IANA (ni `timezone`, ni `tz`, ni `intl` dans `pubspec.yaml`, qui est gele),
/// et c'est un choix, pas un manque a combler dans un widget.
/// `public.instant_creneau()` sait deja le faire en base, et la recoder
/// rejouerait le bug des sept jours d'ecart corrige par la migration `0006`.
///
/// Les trois capacites serveur dont ce port a besoin **n'existent pas encore** :
/// `join_opens_at` configurable, horloge serveur, et rendu des conversions.
/// Elles sont chiffrees dans `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_A.md`.
abstract class PortHorlogeSeance {
  /// L'horloge d'une occurrence, resolue cote serveur (conversions incluses).
  Future<SessionClockVM?> horlogeDe({
    required String groupeId,
    String? sessionId,
  });

  /// Flux de rafraichissement.
  ///
  /// **La cadence est decidee par l'implementation, jamais par le widget.**
  /// Le depot a deja paye ce defaut : une boucle posee dans un ecran continuait
  /// a tourner apres la sortie de salle, et le commentaire de
  /// `lib/core/presence/service_presence.dart` en garde la trace.
  Stream<SessionClockVM> suivre({required String groupeId, String? sessionId});

  /// L'instant serveur de reference.
  ///
  /// **Ne jamais y substituer `DateTime.now()`** : l'horloge d'un appareil
  /// derive, et un compte a rebours faux est pire qu'un compte a rebours
  /// absent.
  Future<DateTime> maintenantServeurUtc();
}

/// Choisit le port selon le mode de compilation.
///
/// **En production, le temps vient du serveur** (`horloge_seance()` et
/// `maintenant_serveur()`, migrations `0030` et `0033`, presentes en
/// production le 23 septembre 2026). Le double ancre au 21 septembre ne sort
/// que sous `PLAYGROUND=true`.
PortHorlogeSeance portHorlogeSelon({required bool demo}) => demo
    ? HorlogeSeanceDemonstration()
    : HorlogeSeanceSupabase(Supabase.instance.client);

/// Le port du temps employe par l'application.
///
/// Il suit le patron de declaration du depot, celui des trente et un services
/// existants : l'interface, son implementation et le provider dans le meme
/// voisinage, sans racine d'injection.
final Provider<PortHorlogeSeance> portHorlogeSeanceProvider =
    Provider<PortHorlogeSeance>(
      (Ref ref) => portHorlogeSelon(demo: Env.playgroundActif),
    );

/// Le temps d'un groupe, rafraichi a la cadence du port.
///
/// **Un seul abonnement par groupe, et aucun minuteur dans un widget.** Le
/// depot porte deja deux `Timer.periodic` poses dans des ecrans ; en ajouter un
/// troisieme rendrait le temps dependant de l'ecran affiche.
/// Une seule lecture de l'horloge d'une Classe (lot salle 3, 25/10/2026) :
/// `null` quand aucune seance ni occurrence n'existe. [horlogeGroupeProvider]
/// n'emet rien dans ce cas ; cette lecture dit a la carte que l'attente est
/// finie (« Aucune seance prevue ») au lieu d'un squelette sans fin.
final FutureProviderFamily<SessionClockVM?, String> horlogeClasseLueProvider =
    FutureProvider.family<SessionClockVM?, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portHorlogeSeanceProvider).horlogeDe(groupeId: groupeId),
    );

final StreamProviderFamily<SessionClockVM, String> horlogeGroupeProvider =
    StreamProvider.family<SessionClockVM, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portHorlogeSeanceProvider).suivre(groupeId: groupeId),
    );
