// FUSEAUX, partie client : l'heure d'une personne vient du fuseau de son
// profil, pas de l'appareil (garde-cap, 04/11/2026). Pour les ecrans ou une
// heure ne concerne qu'elle (notifications, Journee, accueil eleve, salle) :
// une seule heure, « chez vous ».
//
// Un seul provider pour toute l'application ([monHorlogeProvider], lu a la
// racine), un seul formateur ([chezMoi], [heureChezMoi]). Le serveur rend le
// decalage du fuseau du profil (`public.mon_horloge()`, migration
// 20261109900000) ; le client n'y ajoute aucune regle IANA. Sans ce fuseau
// (fonction pas encore installee, profil sans fuseau, hors ligne), l'heure
// de l'appareil, dite comme telle la ou l'ecran en a la place.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../i18n/dates_appareil.dart';
import 'fuseaux_interlocuteurs.dart';

/// Le fuseau du profil de la personne connectee, tel que le serveur le rend.
class MonHorloge {
  /// Cree la lecture.
  const MonHorloge({required this.maintenantServeur, this.moi});

  /// Lit `{maintenant, moi}`.
  factory MonHorloge.lire(Object? brut) {
    if (brut is! Map) throw const FormatException('mon_horloge : objet');
    final Object? m = brut['maintenant'];
    final DateTime? maintenant = m is String
        ? DateTime.tryParse(m)?.toUtc()
        : null;
    if (maintenant == null) {
      throw const FormatException('mon_horloge : maintenant');
    }
    return MonHorloge(
      maintenantServeur: maintenant,
      moi: FuseauVu.lire(brut['moi']),
    );
  }

  /// L'instant serveur de la lecture.
  final DateTime maintenantServeur;

  /// Le fuseau du profil, `null` quand le profil n'en a pas.
  final FuseauVu? moi;
}

/// La derniere lecture, pour les formateurs appeles hors d'un widget (une
/// phrase lue par le lecteur d'ecran, une cle de regroupement). Posee par
/// [monHorlogeProvider] seulement.
MonHorloge? _derniere;

/// L'instant [instant] a l'heure murale de la personne : ses champs (annee,
/// mois, jour, heure, minute) sont ceux de son fuseau de profil, sinon ceux
/// de l'appareil. **Pour l'affichage seulement** : jamais une comparaison ni
/// une difference d'instants.
DateTime chezMoi(DateTime instant) {
  final DateTime? murale = _derniere?.moi?.muraleA(instant.toUtc());
  return murale ?? instant.toLocal();
}

/// « 08:00 » a l'heure de la personne ([chezMoi]).
String heureChezMoi(DateTime instant) => heureDeLAppareil(chezMoi(instant));

/// Vrai quand [chezMoi] retombe sur l'heure de l'appareil : l'ecran qui en a
/// la place le dit (« Heure de cet appareil »).
bool estHeureDeLAppareil(DateTime instant) =>
    _derniere?.moi?.muraleA(instant.toUtc()) == null;

/// Le fuseau du profil qui rend [instant], ou `null` quand [chezMoi]
/// retombe sur l'appareil.
String? fuseauChezMoi(DateTime instant) =>
    estHeureDeLAppareil(instant) ? null : _derniere?.moi?.fuseau;

/// Vrai quand un evenement d'authentification change le compte lu
/// ([compteLu]) : connexion d'un autre compte, ou deconnexion d'un compte.
/// Le rejeu du dernier evenement (meme compte) n'en est pas un.
bool compteAChange(
  AuthChangeEvent evenement,
  String? compte,
  String? compteLu,
) => switch (evenement) {
  AuthChangeEvent.signedIn => compte != compteLu,
  AuthChangeEvent.signedOut => compteLu != null,
  _ => false,
};

/// Pose la lecture courante, pour les tests.
void poserMonHorlogePourTest(MonHorloge? lecture) => _derniere = lecture;

/// La lecture de `public.mon_horloge()`, une fois par session, relue au
/// prochain changement d'heure du fuseau. Lue a la racine de l'application
/// (`app.dart`), pour que chaque ecran se redessine quand elle arrive.
final FutureProvider<MonHorloge?> monHorlogeProvider =
    FutureProvider<MonHorloge?>((Ref ref) async {
      if (Env.playgroundActif) return _derniere = null;
      SupabaseClient client;
      try {
        client = Supabase.instance.client;
      } on Object {
        return _derniere = null;
      }
      // Une lecture par compte : on relit quand le compte CHANGE. Le flux
      // rejoue son dernier evenement a chaque abonne (« signedIn » du compte
      // deja lu) : relire sur ce rejeu relancait la lecture sans fin (des
      // centaines d'appels a la seconde, constat du 05/11/2026).
      final String? compteLu = client.auth.currentUser?.id;
      final StreamSubscription<AuthState> abonnement = client
          .auth
          .onAuthStateChange
          .listen((AuthState e) {
            if (compteAChange(e.event, e.session?.user.id, compteLu)) {
              ref.invalidateSelf();
            }
          });
      ref.onDispose(abonnement.cancel);
      if (client.auth.currentSession == null) return _derniere = null;
      MonHorloge? lu;
      try {
        lu = MonHorloge.lire(await client.rpc<Object?>('mon_horloge'));
      } on PostgrestException catch (e) {
        // Fonction pas encore installee, ou compte refuse : l'appareil.
        if (e.code != 'PGRST202' && e.code != '42883' && e.code != '42501') {
          rethrow;
        }
      } on FormatException {
        lu = null;
      }
      _derniere = lu;
      final DateTime? relire = lu?.moi?.prochainChangement;
      if (lu != null && relire != null) {
        final Duration attente =
            relire.difference(lu.maintenantServeur) +
            const Duration(seconds: 5);
        if (!attente.isNegative && attente < const Duration(days: 31)) {
          final Timer minuteur = Timer(attente, ref.invalidateSelf);
          ref.onDispose(minuteur.cancel);
        }
      }
      return lu;
    }, retry: (int _, Object _) => null);
