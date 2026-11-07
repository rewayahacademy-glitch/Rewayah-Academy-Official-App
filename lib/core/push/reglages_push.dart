// PUSH-1 : la lecture des reglages et les trois gestes (activer, retirer,
// regler une categorie). Logique sans widget, testee seule.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import 'navigateur_push.dart';
import 'port_push.dart';
import 'push_supabase.dart';

/// Le Web Push du navigateur ; remplace par les tests.
final Provider<NavigateurPush> navigateurPushProvider =
    Provider<NavigateurPush>((Ref ref) => const NavigateurPushSysteme());

/// Le serveur ; nul hors du demarrage applicatif (tests, apercu isole).
final Provider<PortPush?> portPushProvider = Provider<PortPush?>((Ref ref) {
  try {
    return PushSupabase(Supabase.instance.client);
  } on Object {
    return null;
  }
});

/// Ce que la feuille affiche. La cle publique est lue d'avance quand
/// l'appareil peut s'abonner : le geste demande l'autorisation sans attente.
final FutureProvider<EtatReglagesPush> reglagesPushProvider =
    FutureProvider.autoDispose<EtatReglagesPush>((Ref ref) async {
      final PortPush? port = ref.watch(portPushProvider);
      if (port == null) throw const CapaciteIndisponible('PUSH-1');
      return lireReglagesPush(ref.watch(navigateurPushProvider), port);
    });

/// Lit l'appareil puis le serveur.
Future<EtatReglagesPush> lireReglagesPush(
  NavigateurPush navigateur,
  PortPush port,
) async {
  final EtatAppareilPush appareil = await navigateur.etat();
  final String? adresse = await navigateur.adresse();
  final ReglagesPushServeur serveur = await port.reglages(adresse: adresse);
  final bool peutActiver =
      serveur.autorise &&
      (appareil == EtatAppareilPush.inactif ||
          (appareil == EtatAppareilPush.actif && !serveur.cetAppareil));
  return EtatReglagesPush(
    appareil: appareil,
    serveur: serveur,
    clePublique: peutActiver ? await port.clePublique() : null,
  );
}

/// Le geste « Recevoir les notifications sur cet appareil » : l'autorisation
/// d'abord (premier appel, dans le geste), puis l'inscription sur le serveur.
/// Leve [ActivationRefusee] si le navigateur refuse.
Future<void> activerPush(
  NavigateurPush navigateur,
  PortPush port,
  String clePublique,
) async {
  final AbonnementNavigateur abonnement = await navigateur.activer(clePublique);
  await port.inscrire(abonnement, appareil: navigateur.appareil);
}

/// Le geste « Ne plus les recevoir sur cet appareil ». Le navigateur d'abord :
/// meme si le serveur ne repond pas, l'appareil ne recoit plus rien, et le
/// serveur retire l'abonnement au premier envoi refuse (410).
Future<void> desactiverPush(NavigateurPush navigateur, PortPush port) async {
  final String? adresse = await navigateur.desactiver();
  if (adresse != null) await port.desinscrire(adresse);
}
