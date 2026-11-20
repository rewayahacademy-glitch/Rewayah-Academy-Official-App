// VIVANT (20/11/2026) : le dernier message non lu, pour la case des messages
// de l'accueil de la direction. Meme lecture que le compteur
// (`nonLusMessagesProvider` : `fils()` de la messagerie existante, jamais un
// second circuit), relue a chaque signal de la veille des messages.
//
// Sans lecture (capacite indisponible, echec) ou sans apercu : rien, la case
// garde son seul nombre.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/communications/veille_messages.dart';
import '../com_messages/entete_fil_contexte.dart' show titreFil;
import '../com_messages/port_messages_metier.dart';

/// Qui a ecrit, puis la premiere ligne de son message : la conversation non
/// lue la plus recente.
final FutureProvider<(String, String)?> dernierNonLuProvider =
    FutureProvider.autoDispose<(String, String)?>((Ref ref) async {
      ref.watch(
        etatVeilleMessagesProvider.select((EtatVeilleMessages e) => e.rang),
      );
      try {
        ResumeFil? dernier;
        for (final ResumeFil f
            in await ref.watch(portMessagesMetierProvider).fils()) {
          if (!estFilMetier(f) || f.attention.nonLus <= 0) continue;
          final DateTime? le = f.dernierMessageLe;
          final DateTime? leDernier = dernier?.dernierMessageLe;
          if (dernier == null ||
              (le != null && (leDernier == null || le.isAfter(leDernier)))) {
            dernier = f;
          }
        }
        final String? apercu = dernier?.apercu?.trim();
        if (dernier == null || apercu == null || apercu.isEmpty) return null;
        return (
          titreFil(dernier.interlocuteurs, dernier.objet.libelle),
          apercu,
        );
      } on Object {
        return null;
      }
    }, retry: (int retryCount, Object error) => null);
