// L'adaptateur Supabase de la veille des messages (MESSAGERIE-TEMPS-REEL,
// 14/11/2026) : un canal Realtime abonne aux insertions et modifications de
// `public.com_signaux` (migration 20261125800000), filtrees sur la personne.
//
// Le filtre de la ligne n'est qu'une economie : la RLS de la table (chacun
// sa ligne) est appliquee par Realtime avec le jeton de l'abonne. Le paquet ne
// porte ni texte ni nom ; seuls l'identifiant du fil et la nature sont lus.

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import 'veille_messages.dart';

/// La veille des messages servie par Supabase Realtime.
class VeilleMessagesSupabase implements PortVeilleMessages {
  /// Cree l'adaptateur sur le client de l'application.
  VeilleMessagesSupabase(this._client);

  final SupabaseClient _client;
  int _rang = 0;

  /// Le signal d'une ligne recue, ou `null` si elle est illisible. Pure.
  static FilABouge? signalDe(Map<String, dynamic> ligne) {
    final Object? fil = ligne['fil_id'];
    final NatureSignalMessages? nature = switch (ligne['nature']) {
      'message' => NatureSignalMessages.message,
      'lecture' => NatureSignalMessages.lecture,
      _ => null,
    };
    if (fil is! String || fil.isEmpty || nature == null) return null;
    return FilABouge(filId: fil, nature: nature);
  }

  @override
  Stream<SignalMessages> ecouter(String profilId) {
    late final StreamController<SignalMessages> flux;
    RealtimeChannel? canal;

    void recu(PostgresChangePayload paquet) {
      final FilABouge? s = signalDe(paquet.newRecord);
      if (s != null && !flux.isClosed) flux.add(s);
    }

    flux = StreamController<SignalMessages>(
      onListen: () {
        _rang += 1;
        final PostgresChangeFilter filtre = PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'destinataire',
          value: profilId,
        );
        canal = _client
            .channel('veille-messages:$_rang')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'com_signaux',
              filter: filtre,
              callback: recu,
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'com_signaux',
              filter: filtre,
              callback: recu,
            )
            .subscribe((RealtimeSubscribeStatus statut, Object? erreur) {
              if (flux.isClosed) return;
              if (statut == RealtimeSubscribeStatus.subscribed) {
                flux.add(const CanalMessagesRejoint());
              } else if (erreur != null) {
                journalDev('Veille des messages : ${statut.name}, $erreur');
              }
              if (statut == RealtimeSubscribeStatus.channelError ||
                  statut == RealtimeSubscribeStatus.timedOut) {
                flux.addError(ErreurCanalMessages(statut.name));
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
