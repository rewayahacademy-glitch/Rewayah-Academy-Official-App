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
