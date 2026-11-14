// MESSAGERIE-TEMPS-REEL (14/11/2026) : le nombre de messages non lus de la
// personne, sur tous ses fils metier, relu a chaque signal de la veille des
// messages. Lu par la messagerie existante (`fils()`), jamais par un second
// circuit : le serveur ne rend a chacun que ses fils (pour la direction, ceux
// de son cote, CAND-Q07).
//
// Sans compte a montrer (capacite indisponible, lecture qui echoue), 0 :
// rien n'est pose, la coquille reste celle d'avant.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/veille_messages.dart';
import '../../core/observabilite/journal_dev.dart';
import 'port_messages_metier.dart';

/// Les messages non lus de tous les fils metier de la personne connectee.
final FutureProvider<int> nonLusMessagesProvider =
    FutureProvider.autoDispose<int>((Ref ref) async {
      ref.watch(
        etatVeilleMessagesProvider.select((EtatVeilleMessages e) => e.rang),
      );
      try {
        int total = 0;
        for (final ResumeFil f
            in await ref.watch(portMessagesMetierProvider).fils()) {
          if (estFilMetier(f)) total += f.attention.nonLus;
        }
        return total;
      } on CapaciteIndisponible {
        return 0;
      } on Object catch (e) {
        journalDev('Non lus des messages illisibles : ${e.runtimeType}');
        return 0;
      }
    }, retry: (int retryCount, Object error) => null);
