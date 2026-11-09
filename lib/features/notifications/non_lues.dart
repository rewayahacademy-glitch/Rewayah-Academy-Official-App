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

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_notifications.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/halo_compte.dart';
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
  final int nonLues = valeur.where((NotificationTuteur n) => !n.lue).length;
  if (nonLues > 0) {
    return EtatHaloCompte.nouveau(nombre: nonLues, chemin: cheminNotifications);
  }
  return null;
}

/// La cloche posee par une coquille de role : la `ClocheNotifications` du
/// core, avec le point de [nonLuesProvider]. Un seul endroit decide du point ;
/// aucune coquille ne le recalcule.
class ClocheCoquille extends ConsumerWidget {
  /// Cree la cloche.
  const ClocheCoquille({required this.onPress, super.key, this.actif = false});

  /// L'ouverture du centre de notifications du role.
  final VoidCallback onPress;

  /// La page des notifications est celle qui est ouverte.
  final bool actif;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ClocheNotifications(
    onPress: onPress,
    actif: actif,
    nonLues: ref.watch(nonLuesProvider),
  );
}
