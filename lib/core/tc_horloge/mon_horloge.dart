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
  const MonHorloge({
    required this.maintenantServeur,
    this.moi,
    this.academie,
    this.lieuChoisi,
  });

  /// Lit `{maintenant, moi, academie, lieu_choisi}`.
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
      academie: FuseauVu.lire(brut['academie']),
      lieuChoisi: brut['lieu_choisi'] is bool
          ? brut['lieu_choisi'] as bool
          : null,
    );
  }

  /// L'instant serveur de la lecture.
  final DateTime maintenantServeur;

  /// Le fuseau du profil, `null` quand le profil n'en a pas.
  final FuseauVu? moi;

  /// L'horloge de l'academie (La Mecque, `Asia/Riyadh`, +3 h sans changement
  /// d'heure), montree en second apres l'heure de la personne (HORLOGE-ET-LIEU,
  /// H1 et H2, 12/11/2026). `null` tant que le serveur ne la rend pas (fonction
  /// pas encore installee) : l'ecran ne montre alors pas de seconde heure.
  final FuseauVu? academie;

  /// Vrai quand la personne a CHOISI sa ville (HORLOGE-ET-LIEU, partie B) :
  /// `moi` est alors le fuseau de sa ville. Faux quand elle n'en a pas choisi :
  /// `moi` n'est que le fuseau enregistre par defaut, pas un choix. `null`
  /// quand le serveur ne le dit pas (ancienne version) : l'ancien comportement.
  final bool? lieuChoisi;
}

/// La derniere lecture, pour les formateurs appeles hors d'un widget (une
/// phrase lue par le lecteur d'ecran, une cle de regroupement). Posee par
/// [monHorlogeProvider] seulement.
MonHorloge? _derniere;

/// L'heure murale de [instant] chez la personne, avec ce qui la fonde.
/// **La regle des trois cas** (architecte pedagogique, 13/11/2026) :
/// 1. sans ville choisie, l'ecran montre l'heure de l'APPAREIL et le dit ;
/// 2. avec une ville choisie, l'ecran montre l'heure de la VILLE ;
/// 3. si l'appareil et la ville donnent deux heures differentes (voyage),
///    l'ecran montre l'heure de l'appareil et le dit, sans rien modifier au
///    lieu enregistre.
/// Cote serveur, sans appareil, le fuseau enregistre sert toujours (jusqu'au
/// choix de la ville : le serveur ne lit jamais l'appareil). Un serveur qui ne
/// dit pas `lieu_choisi` garde l'ancien comportement : le fuseau du profil.
({DateTime murale, bool appareil}) _vue(DateTime instant) {
  final DateTime utc = instant.toUtc();
  final MonHorloge? m = _derniere;
  final FuseauVu? moi = m?.moi;
  final DateTime? duProfil = moi?.muraleA(utc);
  if (moi == null || duProfil == null) {
    return (murale: instant.toLocal(), appareil: true);
  }
  final bool? choisie = m?.lieuChoisi;
  if (choisie == null) return (murale: duProfil, appareil: false);
  if (!choisie) return (murale: instant.toLocal(), appareil: true);
  final Duration? decalageVille = moi.decalageA(utc);
  final bool voyage =
      decalageVille == null ||
      instant.toLocal().timeZoneOffset != decalageVille;
  return voyage
      ? (murale: instant.toLocal(), appareil: true)
      : (murale: duProfil, appareil: false);
}

/// L'instant [instant] a l'heure murale de la personne : ses champs (annee,
/// mois, jour, heure, minute) sont ceux de son fuseau de profil (sa ville),
/// sinon ceux de l'appareil (voir [_vue], les trois cas). **Pour l'affichage
/// seulement** : jamais une comparaison ni une difference d'instants.
DateTime chezMoi(DateTime instant) => _vue(instant).murale;

/// « 08:00 » a l'heure de la personne ([chezMoi]).
String heureChezMoi(DateTime instant) => heureDeLAppareil(chezMoi(instant));

/// Le jour civil de [instant] au fuseau du profil, en `DateTime` LOCAL a
/// minuit, pour les formateurs de date qui appellent eux-memes `toLocal()`
/// (dateCourteCandidature, dateEcheance) : [chezMoi] rend un `DateTime`
/// marque UTC qui porte l'heure murale, et `toLocal()` le decalerait une
/// seconde fois (constat de B, 12/11/2026).
DateTime jourChezMoi(DateTime instant) {
  final DateTime m = chezMoi(instant);
  return DateTime(m.year, m.month, m.day);
}

/// L'instant (UTC) dont l'heure murale, au fuseau du profil, est le
/// [annee]-[mois]-[jour] a [heure]:[minute] : l'inverse de [chezMoi], pour
/// un choix fait a l'ecran (HEURES-PROFIL H3, 12/11/2026). Sans fuseau de
/// profil, ou quand le decalage a cette date n'est pas sur, l'heure de
/// l'appareil (`DateTime` local), comme [chezMoi].
DateTime instantChezMoi(
  int annee,
  int mois,
  int jour, [
  int heure = 0,
  int minute = 0,
]) {
  final FuseauVu? moi = _derniere?.moi;
  final DateTime murale = DateTime.utc(annee, mois, jour, heure, minute);
  // Les trois cas : sans ville choisie, l'heure saisie est celle de l'appareil.
  if (moi != null && _derniere?.lieuChoisi != false) {
    // Deux passes : le decalage en vigueur a l'instant trouve, puis la
    // verification que cet instant rend bien l'heure murale demandee.
    final Duration? d = moi.decalageA(murale.subtract(moi.decalage));
    if (d != null) {
      DateTime utc = murale.subtract(d);
      final Duration? d2 = moi.decalageA(utc);
      if (d2 != null && d2 != d) utc = murale.subtract(d2);
      if (moi.muraleA(utc) == murale) return utc;
    }
  }
  return DateTime(annee, mois, jour, heure, minute);
}

/// L'horloge de l'academie (La Mecque) lue par [monHorlogeProvider], ou
/// `null`. Pour [lignesInterlocuteurs] et les ecrans qui montrent une seconde
/// heure.
FuseauVu? get horlogeAcademie => _derniere?.academie;

/// « 21:00 » a l'heure de l'academie (La Mecque) pour [instant], ou `null`
/// quand l'academie n'est pas lue, ou quand la personne vit deja a l'heure de
/// l'academie (une seconde ligne qui redirait la meme heure).
String? heureMecqueSiDifferente(DateTime instant) {
  final FuseauVu? a = _derniere?.academie;
  if (a == null) return null;
  final FuseauVu? moi = _derniere?.moi;
  final DateTime utc = instant.toUtc();
  if (estHeureDeLAppareil(instant)) {
    // L'ecran montre l'heure de l'appareil : la comparaison se fait avec elle.
    if (a.decalageA(utc) == instant.toLocal().timeZoneOffset) return null;
  } else if (moi != null && a.memeHeureQue(moi)) {
    return null;
  }
  return a.heureA(utc);
}

/// Vrai quand [chezMoi] retombe sur l'heure de l'appareil : l'ecran qui en a
/// la place le dit (« Heure de cet appareil »).
bool estHeureDeLAppareil(DateTime instant) => _vue(instant).appareil;

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
