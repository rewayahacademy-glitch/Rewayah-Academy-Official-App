// PE-B10 (20/11/2026) : un depot de fichier qui survit a une panne passagere.
//
// Lu dans les journaux de production (14-20/11/2026) : le 15/11, pendant la
// panne de la base (R19), 11 envois au seau `kyc` ont echoue (544, 504, 429,
// 500) et 4 confirmations (401, 403), sans aucun nouvel essai : le stockage
// tourne avec `retryAttempts = 0`. Le candidat lisait « Reessayez dans un
// instant » et, souvent, envoyait sa piece par le chat.
//
// La regle, une fois, pour la piece et la photo :
//   - chaque etape (envoi, confirmation, ligne) est reessayee seule, deux fois
//     au plus, quand la cause est passagere (coupure, 429, 5xx) ; un refus
//     (format, taille, contenu, droit, session) n'est jamais reessaye ;
//   - on reprend a l'etape qui a echoue, jamais depuis le debut : un fichier
//     deja envoye n'est pas renvoye ;
//   - la cle est stable d'un essai a l'autre : si la reponse d'un envoi s'est
//     perdue alors que le fichier est arrive, le nouvel essai recoit « existe
//     deja » et le tient pour un succes. Jamais deux fichiers, jamais deux
//     lignes pour un meme depot ;
//   - un 401 fait d'abord rafraichir la session une fois (le jeton a pu
//     expirer pendant un long envoi), puis reessaie l'etape.

import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'echec_depot.dart';

/// L'attente avant le nouvel essai numero [essai] (1, puis 2). Une attente
/// metier en secondes, pas une duree d'animation.
typedef Attente = Future<void> Function(int essai);

/// L'attente reelle : 2 s, puis 5 s.
Future<void> attenteReelle(int essai) =>
    Future<void>.delayed(Duration(seconds: essai == 1 ? 2 : 5));

/// Le nombre de nouveaux essais d'une etape passagere.
const int nouveauxEssaisDepot = 2;

/// Execute [etape], et la reessaie [nouveauxEssaisDepot] fois au plus quand la
/// cause de l'echec est passagere.
///
/// [rafraichir] est appele une seule fois sur une session refusee (401) ; s'il
/// rend vrai, l'etape est reessayee. [dejaFait] dit qu'un nouvel essai a
/// rencontre le resultat du precedent (objet ou ligne deja la) : l'etape est
/// alors reussie. L'erreur levee est celle du dernier essai.
Future<T> avecNouveauxEssais<T>(
  Future<T> Function() etape, {
  Attente attendre = attenteReelle,
  Future<bool> Function()? rafraichir,
  T Function(Object erreur)? dejaFait,
}) async {
  int essai = 0;
  bool rafraichi = false;
  while (true) {
    try {
      return await etape();
    } on Object catch (erreur) {
      if (essai > 0 && dejaFait != null && dejaDepose(erreur)) {
        return dejaFait(erreur);
      }
      final CauseEchecDepot cause = causeEchecDepot(erreur);
      if (cause == CauseEchecDepot.session &&
          !rafraichi &&
          rafraichir != null) {
        rafraichi = true;
        if (await rafraichir()) continue;
        rethrow;
      }
      if (!causePassagere(cause) || essai >= nouveauxEssaisDepot) rethrow;
      essai++;
      await attendre(essai);
    }
  }
}

/// Rafraichit la session du compte ; vrai si une session valable en sort.
Future<bool> rafraichirSession(SupabaseClient client) async {
  try {
    final AuthResponse r = await client.auth.refreshSession();
    return r.session != null;
  } on Object {
    return false;
  }
}

/// Envoie [octets] sous [cle] dans [seau], avec les nouveaux essais de la
/// regle. Une reponse « existe deja » a un nouvel essai est un succes : le
/// premier envoi etait arrive.
Future<void> envoyerAuSeau(
  SupabaseClient client, {
  required String seau,
  required String cle,
  required Uint8List octets,
  required String typeMime,
  Attente attendre = attenteReelle,
}) => avecNouveauxEssais<void>(
  () => client.storage
      .from(seau)
      .uploadBinary(
        cle,
        octets,
        fileOptions: FileOptions(contentType: typeMime),
      ),
  attendre: attendre,
  rafraichir: () => rafraichirSession(client),
  dejaFait: (_) {},
);
