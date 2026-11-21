// Le point de non-lus de la cloche (fiche « Fraicheur et notifications » du
// 27/10/2026, lignes 12 et 14).
//
// Une seule source : la liste du centre de notifications
// (`notificationsTuteurProvider`), lue dans la base par le port de la personne
// connectee, et relue sans geste quand la veille de fraicheur signale un
// changement de la table `notifications` (une notification ecrite par le
// serveur, une lecture faite sur un autre appareil). Le point n'existe que
// pour de vrais non-lus : sans source (capacite indisponible), sans lecture
// encore faite ou en echec, il n'y a pas de point.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_notifications.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/halo_compte.dart';
import 'cloche/annonces_cloche.dart';
import 'cloche/etat_annonces_cloche.dart';
import 'cloche/ouvrir_cloche.dart';
import 'notifications_page.dart';

/// Le nombre de notifications non lues de la personne connectee, `null` tant
/// qu'aucune liste n'est connue (chargement, echec, capacite absente). Pure :
/// derive de la liste, jamais compte a part.
int? nonLuesDepuis(AsyncValue<List<NotificationTuteur>> liste) {
  final List<NotificationTuteur>? valeur = liste.value;
  if (valeur == null) return null;
  return valeur.where((NotificationTuteur n) => !n.lue).length;
}

/// Les non-lus de la cloche, pour toutes les coquilles (tuteur, eleve,
/// enseignante, controleur).
final Provider<int?> nonLuesProvider = Provider<int?>(
  (Ref ref) => nonLuesDepuis(ref.watch(notificationsTuteurProvider)),
);

/// NAV-REFONTE, etape 2a (decision du directeur du 09/11/2026) : le halo du
/// cercle Compte, tire de la **meme liste** que la cloche (aucune lecture a
/// part). Pure et testee.
///
/// - Urgent : la plus recente notification de niveau urgent encore a faire
///   (un geste en attente) ou pas encore lue ; la feuille ouvre sa
///   destination, sinon le centre de notifications.
/// - Nouveau : au moins une notification non lue ; la feuille ouvre le centre
///   de notifications.
/// - Aucun : rien de cela, aucune liste connue (chargement, echec, capacite
///   absente : jamais un faux calme affiche comme certain, jamais un faux
///   halo), ou aucun centre de notifications pour cette personne
///   ([cheminNotifications] nul, l'eleve mineur).
EtatHaloCompte? haloDepuisNotifications(
  AsyncValue<List<NotificationTuteur>> liste, {
  required String? cheminNotifications,
  Set<String> vues = const <String>{},
}) {
  final List<NotificationTuteur>? valeur = liste.value;
  if (valeur == null || cheminNotifications == null) return null;
  for (final NotificationTuteur n in valeur) {
    if (n.niveau == NiveauAttention.urgent && (n.gesteEnAttente || !n.lue)) {
      return EtatHaloCompte.urgent(
        titre: n.titre,
        detail: n.texte,
        chemin: n.destination ?? cheminNotifications,
      );
    }
  }
  final Set<String> ids = <String>{
    for (final NotificationTuteur n in valeur)
      if (!n.lue) n.id,
  };
  // Toucher le cercle marque « vues » les nouveautes signalees : le halo
  // s'eteint jusqu'a une nouveaute qui n'a pas encore ete signalee.
  if (ids.isNotEmpty && !vues.containsAll(ids)) {
    return EtatHaloCompte.nouveau(
      nombre: ids.length,
      chemin: cheminNotifications,
      idsNonLus: ids,
    );
  }
  return null;
}

/// Les nouveautes deja signalees par le halo du cercle Compte et vues (le
/// cercle a ete touche), pour la session de l'application (arbitrage du
/// garde-cap du 09/11/2026 : « Nouveau s'eteint, vu »). Une nouvelle
/// notification non lue rallume le halo.
class NouveautesVues extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Marque [ids] vues.
  void marquer(Set<String> ids) => state = <String>{...state, ...ids};
}

/// Les nouveautes vues, lues par la coquille de chaque role.
final NotifierProvider<NouveautesVues, Set<String>> nouveautesVuesProvider =
    NotifierProvider<NouveautesVues, Set<String>>(NouveautesVues.new);

/// La cloche posee par une coquille de role : la `ClocheNotifications` du
/// core, avec le point de [nonLuesProvider] et les annonces de l'academie pas
/// encore vues. Un seul endroit decide du point ; aucune coquille ne le
/// recalcule.
///
/// CLOCHE-C (directeur, 21/11/2026, decision ANNONCES-NOTIFS regle 1) : la
/// cloche ouvre le panneau ancre (ordinateur) ou la feuille du bas
/// (telephone) ; « Voir tout » mene a [cheminPage]. Sur la page des
/// notifications elle-meme ([actif]), elle ne rouvre rien par-dessus.
class ClocheCoquille extends ConsumerWidget {
  /// Cree la cloche.
  const ClocheCoquille({
    super.key,
    this.cheminPage,
    this.onPress,
    this.actif = false,
  });

  /// La page complete des notifications du role, ou nul (le candidat, qui
  /// n'en a pas : tout se lit dans le panneau).
  final String? cheminPage;

  /// Le geste de la cloche sur sa propre page ([actif]) ; nul : aucun.
  final VoidCallback? onPress;

  /// La page des notifications est celle qui est ouverte.
  final bool actif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? notifs = ref.watch(nonLuesProvider);
    final EtatAnnoncesCloche annonces = ref.watch(
      annoncesClocheProvider(false),
    );
    final Map<String, bool> fermetures = ref.watch(fermeturesClocheProvider);
    final int annoncesNonVues = annonces.lues
        .where((AnnonceCloche a) => !a.vue && !(fermetures[a.id] ?? a.fermee))
        .length;
    final int? total = notifs == null && annoncesNonVues == 0
        ? null
        : (notifs ?? 0) + annoncesNonVues;
    return ClocheNotifications(
      onPress: actif
          ? onPress
          : () => unawaited(ouvrirCloche(context, cheminPage: cheminPage)),
      actif: actif,
      nonLues: total,
    );
  }
}
