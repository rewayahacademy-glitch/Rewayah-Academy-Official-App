import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_notifications.dart';

/// Résout le libellé localisé à partir du type d'événement et de paramètres
/// non sensibles. L'appelant fournit les clés du catalogue i18n de l'application.
typedef NotificationTitleResolver = String Function(
  String evenement,
  Map<String, dynamic> params,
);

/// Adaptateur Supabase de la boîte de notifications privée.
class NotificationsSupabase implements PortNotifications {
  const NotificationsSupabase(
    this._client, {
    required NotificationTitleResolver titrePour,
  }) : _titrePour = titrePour;

  final SupabaseClient _client;
  final NotificationTitleResolver _titrePour;

  static const Set<String> _evenements = <String>{
    'demande_recue',
    'demande_presentation',
    'classe_validee',
    'enseignant_affecte',
    'demande_close',
    'remplacement_propose',
    'remplacement_pris',
  };

  String get _destinataire {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Session requise pour lire les notifications');
    }
    return id;
  }

  @override
  Future<List<NotificationTuteur>> liste() async {
    final dynamic rows = await _client
        .from('notifications')
        .select('id, destinataire, evenement, params, destination, cree_le')
        .eq('destinataire', _destinataire)
        .order('cree_le', ascending: false);
    if (rows is! List) {
      throw const FormatException('Réponse notifications invalide');
    }
    return rows
        .map(
          (dynamic row) => _notification(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<NotificationTuteur?> detail(String id) async {
    final dynamic row = await _client
        .from('notifications')
        .select('id, destinataire, evenement, params, destination, cree_le')
        .eq('destinataire', _destinataire)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    if (row is! Map) {
      throw const FormatException('Réponse notification invalide');
    }
    return _notification(Map<String, dynamic>.from(row));
  }

  /// Marque uniquement l'accusé de lecture géré par la RPC serveur.
  Future<void> marquerLue(String id) async {
    await _client.rpc<void>(
      'marquer_notification_lue',
      params: <String, dynamic>{'p_notification_id': id},
    );
  }

  NotificationTuteur _notification(Map<String, dynamic> row) {
    final String? id = row['id'] as String?;
    final String? evenement = row['evenement'] as String?;
    final dynamic rawParams = row['params'];
    final String? destination = row['destination'] as String?;
    final DateTime? date = DateTime.tryParse(
      row['cree_le']?.toString() ?? '',
    );
    if (id == null ||
        evenement == null ||
        !_evenements.contains(evenement) ||
        rawParams is! Map ||
        date == null) {
      throw const FormatException('Notification Supabase invalide');
    }

    final Map<String, dynamic> params = Map<String, dynamic>.from(rawParams);
    final String titre = _titrePour(evenement, params).trim();
    if (titre.isEmpty) {
      throw const FormatException('Libellé de notification absent');
    }

    return NotificationTuteur(
      id: id,
      titre: titre,
      date: date.toUtc(),
      destination: destination,
    );
  }
}
