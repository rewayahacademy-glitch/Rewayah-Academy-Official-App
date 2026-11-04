// FUSEAUX, partie client : la lecture des interlocuteurs d'une classe.
//
// Un appel par classe, jamais par carte (garde-cap, 04/11/2026) : toutes les
// cartes, lignes et heures d'une meme classe lisent le meme provider. La
// lecture est refaite d'elle-meme au premier changement d'heure qu'elle porte.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'fuseaux_interlocuteurs.dart';
import 'interlocuteurs_supabase.dart';
import 'mon_horloge.dart';

/// L'acces aux fuseaux des interlocuteurs d'une classe.
abstract class PortInterlocuteurs {
  /// Les interlocuteurs de la classe [groupeId], selon qui regarde, ou `null`
  /// quand la classe ne concerne pas l'appelant ou que le serveur n'a pas
  /// encore la fonction : l'ecran garde alors sa seule heure, sans inventer
  /// l'autre.
  Future<InterlocuteursClasse?> lire(String groupeId);
}

/// Sous `PLAYGROUND`, aucune donnee serveur : pas de seconde heure.
class InterlocuteursAbsents implements PortInterlocuteurs {
  /// Cree le port vide.
  const InterlocuteursAbsents();

  @override
  Future<InterlocuteursClasse?> lire(String groupeId) async => null;
}

/// Le port employe par l'application. Sans client Supabase initialise (un
/// test de widget qui ne surcharge pas ce port), aucune seconde heure : les
/// ecrans gardent l'heure de la classe rendue par le serveur.
final Provider<PortInterlocuteurs> portInterlocuteursProvider =
    Provider<PortInterlocuteurs>((Ref ref) {
      if (Env.playgroundActif) return const InterlocuteursAbsents();
      try {
        return InterlocuteursSupabase(Supabase.instance.client);
      } on Object {
        return const InterlocuteursAbsents();
      }
    });

/// Les interlocuteurs d'une classe : une lecture par classe, partagee par
/// tous les widgets qui la regardent, relue au premier changement d'heure.
final FutureProviderFamily<InterlocuteursClasse?, String>
interlocuteursClasseProvider =
    FutureProvider.family<InterlocuteursClasse?, String>((
      Ref ref,
      String groupeId,
    ) async {
      // Une lecture par compte : monHorlogeProvider se relit a chaque
      // connexion et deconnexion ; le suivre jette la lecture du compte
      // precedent (meme classe, meme onglet, autre personne).
      ref.watch(monHorlogeProvider);
      final InterlocuteursClasse? lus = await ref
          .watch(portInterlocuteursProvider)
          .lire(groupeId);
      final DateTime? relire = lus?.relireA;
      if (lus != null && relire != null) {
        final Duration attente =
            relire.difference(lus.maintenantServeur) +
            const Duration(seconds: 5);
        // Un minuteur plus long qu'un mois ne sert a rien : l'ecran sera
        // rouvert avant.
        if (!attente.isNegative && attente < const Duration(days: 31)) {
          final Timer minuteur = Timer(attente, ref.invalidateSelf);
          ref.onDispose(minuteur.cancel);
        }
      }
      return lus;
    }, retry: (int _, Object _) => null);
