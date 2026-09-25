import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/chemin_retour.dart';
import 'capacite_indisponible.dart';

/// Une notification du tuteur.
@immutable
class NotificationTuteur {
  /// Cree une notification. [destination] est validee a la construction : un
  /// chemin externe, la salle, la classe ou l'entree d'agent deviennent
  /// `null`, jamais un lien suivi.
  NotificationTuteur({
    required this.id,
    required this.titre,
    required this.date,
    String? destination,
    this.lue = false,
    this.cibleRetiree = false,
  }) : destination = cheminRetourValide(destination);

  /// Vrai quand le serveur la dit deja lue.
  final bool lue;

  /// Vrai quand le serveur dit que sa cible n'existe plus : l'ecran le dit
  /// au toucher, sans naviguer (LT-12).
  final bool cibleRetiree;

  /// Identifiant.
  final String id;

  /// Titre, deja redige.
  final String titre;

  /// Date d'emission.
  final DateTime date;

  /// Chemin interne ouvert au toucher, deja valide. `null` : aucun.
  final String? destination;
}

/// Les notifications du tuteur (contrat K6).
abstract interface class PortNotifications {
  /// Les notifications, la plus recente d'abord.
  Future<List<NotificationTuteur>> liste();

  /// Une notification precise.
  Future<NotificationTuteur?> detail(String id);
}

/// Les notifications tant qu'aucune source n'existe (DB-CPT-04) : « Les
/// notifications ne sont pas encore disponibles », cloche sans pastille,
/// jamais un faux etat vide. Aucun adaptateur prevu.
class NotificationsIndisponibles implements PortNotifications {
  /// Cree l'implementation.
  const NotificationsIndisponibles();

  @override
  Future<List<NotificationTuteur>> liste() =>
      Future<List<NotificationTuteur>>.error(
        const CapaciteIndisponible('DB-CPT-04'),
      );

  @override
  Future<NotificationTuteur?> detail(String id) =>
      Future<NotificationTuteur?>.error(
        const CapaciteIndisponible('DB-CPT-04'),
      );
}

/// Les notifications employees par l'application.
final Provider<PortNotifications> portNotificationsProvider =
    Provider<PortNotifications>(
      (Ref ref) => const NotificationsIndisponibles(),
    );
