import '../../core/capacites/notifications_supabase.dart';
import '../../core/i18n/strings.g.dart';

/// Résout uniquement des libellés traduits; les paramètres SQL restent cachés.
NotificationContenu contenuNotificationPour(
  String evenement,
  Map<String, dynamic> _,
) {
  final String titre = switch (evenement) {
    'demande_recue' => t.notifications.evenements.demandeRecue,
    'classe_validee' => t.notifications.evenements.classeValidee,
    'enseignant_affecte' => t.notifications.evenements.enseignantAffecte,
    'demande_close' => t.notifications.evenements.demandeClose,
    'remplacement_propose' => t.notifications.evenements.remplacementPropose,
    'remplacement_pris' => t.notifications.evenements.remplacementPris,
    _ => throw const FormatException('Événement de notification inconnu.'),
  };
  return NotificationContenu(titre: titre);
}
