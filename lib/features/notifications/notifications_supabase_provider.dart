import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/capacites/notifications_supabase.dart';
import '../../core/capacites/port_notifications.dart';
import 'contenu_notification.dart';

/// Source branchée sur 0063 dans l'application, tout en laissant les ports
/// remplacés par les écrans de démonstration et les tests.
final Provider<PortNotifications> notificationsPagePortProvider =
    Provider<PortNotifications>((Ref ref) {
      final PortNotifications port = ref.watch(portNotificationsProvider);
      if (port is! NotificationsIndisponibles) return port;
      try {
        return NotificationsSupabase(
          Supabase.instance.client,
          contenuPour: contenuNotificationPour,
        );
      } on Object {
        // Hors du démarrage applicatif (tests, aperçu isolé), garder l'état
        // explicite d'indisponibilité plutôt que simuler une liste vide.
        return port;
      }
    });
