import '../../core/capacites/notifications_supabase.dart';
import '../../core/i18n/strings.g.dart';

/// Résout uniquement des libellés traduits; les paramètres SQL restent cachés.
NotificationContenu contenuNotificationPour(
  String evenement,
  Map<String, dynamic> _,
) {
  final String titre = switch (evenement) {
    'demande_recue' => t.notifications.evenements.demandeRecue,
    'demande_presentation' => t.notifications.evenements.demandePresentation,
    'classe_validee' => t.notifications.evenements.classeValidee,
    'enseignant_affecte' => t.notifications.evenements.enseignantAffecte,
    'demande_close' => t.notifications.evenements.demandeClose,
    'remplacement_propose' => t.notifications.evenements.remplacementPropose,
    'remplacement_pris' => t.notifications.evenements.remplacementPris,
    'controle_mission_attribuee' =>
      t.notifications.evenements.controleMissionAttribuee,
    'controle_mission_non_controlee' =>
      t.notifications.evenements.controleMissionNonControlee,
    'classe_changee' => t.notifications.evenements.classeChangee,
    _ => throw const FormatException('Événement de notification inconnu.'),
  };
  return NotificationContenu(titre: titre);
}
