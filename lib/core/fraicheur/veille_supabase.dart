// L'adaptateur Supabase de la veille de fraicheur : un canal Realtime, abonne
// aux changements Postgres des quatre tables publiees par la migration
// 20261027100000. Meme mecanisme que `support_actif_supabase.dart`, etendu.
//
// Le filtre est la RLS : Realtime l'applique a chaque insertion et chaque
// modification avec le jeton de l'abonne. Aucun filtre cote client ne la
// remplace. Une suppression arrive a tous les abonnes, avec la seule cle
// primaire : elle est traitee comme un signal de relecture, rien de plus.

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import 'port_veille.dart';

/// La veille servie par Supabase Realtime.
class VeilleSupabase implements PortVeille {
  /// Cree l'adaptateur sur le client de l'application.
  VeilleSupabase(this._client);

  final SupabaseClient _client;

  /// Chaque ecoute ouvre son propre canal : le nom porte un rang pour que deux
  /// ecoutes successives (retour du reseau) ne se confondent jamais.
  int _rang = 0;

  @override
  Stream<SignalVeille> ecouter() {
    late final StreamController<SignalVeille> flux;
    RealtimeChannel? canal;

    flux = StreamController<SignalVeille>(
      onListen: () {
        _rang += 1;
        RealtimeChannel c = _client.channel('veille-fraicheur:$_rang');
        for (final String table in tablesVeillees) {
          c = c.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (PostgresChangePayload paquet) {
              if (!flux.isClosed) flux.add(ChangementTable(paquet.table));
            },
          );
        }
        canal = c.subscribe((RealtimeSubscribeStatus statut, Object? erreur) {
          if (flux.isClosed) return;
          if (statut == RealtimeSubscribeStatus.subscribed) {
            // Jointure ou rejointure : tout est a relire.
            flux.add(const CanalRejoint());
          } else if (erreur != null) {
            journalDev('Veille de fraicheur : ${statut.name}, $erreur');
          }
          // Erreur ou delai depasse : transmis a la veille, qui le dit a la
          // supervision (29/10/2026). La fermeture voulue (`closed`) ne
          // compte pas.
          if (statut == RealtimeSubscribeStatus.channelError ||
              statut == RealtimeSubscribeStatus.timedOut) {
            flux.addError(ErreurCanalVeille(statut.name));
          }
        });
      },
      onCancel: () async {
        final RealtimeChannel? c = canal;
        canal = null;
        if (c != null) await _client.removeChannel(c);
        await flux.close();
      },
    );
    return flux.stream;
  }
}
