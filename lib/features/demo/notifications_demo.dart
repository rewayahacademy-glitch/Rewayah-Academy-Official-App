// Notifications fictives de la demonstration tuteur (LT-12) : aucune source
// reelle (DB-CPT-04), jamais en production (garde de `mode_demonstration`).

import '../../core/capacites/port_notifications.dart';
import '../../core/router/routes.dart';

/// Quatre notifications fictives : deux non lues, une lue, et une dont la
/// cible a ete retiree par le serveur.
class NotificationsDemo implements PortNotifications {
  /// Cree le double.
  const NotificationsDemo();

  /// L'identifiant de la notification a cible retiree.
  static const String idCibleRetiree = 'demo-notif-retiree';

  static List<NotificationTuteur> _liste() {
    final DateTime m = DateTime.now();
    DateTime jour(int n, int h) => DateTime(m.year, m.month, m.day - n, h);
    return <NotificationTuteur>[
      NotificationTuteur(
        id: 'demo-notif-seance',
        titre: 'Séance d’Aïcha terminée : présence enregistrée',
        date: jour(0, 17),
        destination: Routes.tuteurSuivi,
      ),
      NotificationTuteur(
        id: 'demo-notif-solde',
        titre: 'Remise créditée sur le solde de Yusuf',
        date: jour(1, 18),
        destination: Routes.tuteurCompteSoldes,
      ),
      NotificationTuteur(
        id: idCibleRetiree,
        titre: 'Nouvelle ressource dans la classe d’Aïcha',
        date: jour(3, 10),
        destination: Routes.tuteurSuivi,
        lue: true,
        cibleRetiree: true,
      ),
      NotificationTuteur(
        id: 'demo-notif-academie',
        titre: 'Message de l’académie : calendrier des vacances',
        date: jour(6, 9),
        lue: true,
      ),
    ];
  }

  @override
  Future<List<NotificationTuteur>> liste() async => _liste();

  @override
  Future<NotificationTuteur?> detail(String id) async {
    for (final NotificationTuteur n in _liste()) {
      if (n.id == id) {
        return n;
      }
    }
    return null;
  }
}
