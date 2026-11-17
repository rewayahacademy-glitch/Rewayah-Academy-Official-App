// VU-UNE-FOIS (directeur, 16/11/2026 : « ce qui est utile une seule fois ne doit
// pas rester sur l'ecran ») : ce qu'un compte a deja vu, cote serveur, pour que
// un bandeau ferme ne revienne jamais, sur aucun appareil ni navigateur.
//
// Un seul adaptateur pour tous les bandeaux « une fois » : une cle par bandeau
// (`bandeau.deux_cotes`, format `^[a-z][a-z0-9_.-]{2,59}$`). Les deux RPC de la
// migration VU-UNE-FOIS (#541) : `lire_vus()` rend les cles deja vues par le
// compte connecte, `marquer_vu(p_cle)` en ajoute une (idempotente).
//
// Aucune memoire d'appareil. Une lecture impossible (serveur d'avant ce lot,
// reseau) vaut « rien de vu » : le bandeau se montre, il ne disparait jamais
// par erreur, et une cle marquee reste vue pour la session meme si
// l'ecriture echoue.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/rpc_finance_supabase.dart';
import '../preferences/preferences_compte.dart';

const String _dependance = 'VU-UNE-FOIS';

/// Ce que le serveur sait des bandeaux vus par le compte connecte.
abstract interface class PortVus {
  /// Les cles deja vues (`lire_vus`).
  Future<Set<String>> lire();

  /// Marque une cle comme vue (`marquer_vu`), idempotente.
  Future<void> marquer(String cle);
}

/// Tant qu'aucun adaptateur serveur n'est branche (tests, demonstration).
class VusIndisponibles implements PortVus {
  /// Cree l'implementation.
  const VusIndisponibles();

  static const CapaciteIndisponible _absente = CapaciteIndisponible(
    _dependance,
  );

  @override
  Future<Set<String>> lire() => Future<Set<String>>.error(_absente);

  @override
  Future<void> marquer(String cle) => Future<void>.error(_absente);
}

/// Les RPC `lire_vus` et `marquer_vu`.
class VusSupabase implements PortVus {
  /// Cree l'adaptateur sur le client de l'application.
  VusSupabase(SupabaseClient client) : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  VusSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<Set<String>> lire() async {
    final Object? brut = await appelerFinance(_appel, 'lire_vus', _dependance);
    if (brut is! List) {
      throw const FormatException('liste invalide: lire_vus');
    }
    return <String>{
      for (final Object? c in brut)
        if (c is String && c.isNotEmpty) c,
    };
  }

  @override
  Future<void> marquer(String cle) async {
    await appelerFinance(_appel, 'marquer_vu', _dependance, <String, dynamic>{
      'p_cle': cle,
    });
  }
}

/// Le port des bandeaux vus.
final Provider<PortVus> portVusProvider = Provider<PortVus>(
  (Ref ref) => const VusIndisponibles(),
);

/// Les cles de bandeau d'aujourd'hui.
@immutable
abstract final class ClesVu {
  /// Le bandeau « Lecture des deux cotes » de la liste des candidatures.
  static const String deuxCotes = 'bandeau.deux_cotes';
}

/// Les cles deja vues par le compte connecte. `AsyncLoading` tant que le
/// serveur n'a pas repondu ; une lecture impossible rend l'ensemble vide.
class VusDuCompte extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    // Un autre compte sur le meme appareil relit ses propres cles.
    ref.watch(compteDesPreferencesProvider);
    try {
      return await ref.read(portVusProvider).lire();
    } on Object {
      return <String>{};
    }
  }

  /// Marque [cle] comme vue : tout de suite a l'ecran, puis au serveur. Un
  /// echec du serveur ne rouvre pas le bandeau pendant cette session.
  Future<void> marquer(String cle) async {
    final Set<String> avant = state.asData?.value ?? <String>{};
    state = AsyncData<Set<String>>(<String>{...avant, cle});
    try {
      await ref.read(portVusProvider).marquer(cle);
    } on Object {
      // Non confirme : la prochaine session le montrera encore une fois.
    }
  }
}

/// Les bandeaux vus par le compte connecte.
final AsyncNotifierProvider<VusDuCompte, Set<String>> vusProvider =
    AsyncNotifierProvider<VusDuCompte, Set<String>>(VusDuCompte.new);
