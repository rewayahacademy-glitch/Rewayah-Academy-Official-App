import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'echanges_controleur.dart';

/// Adaptateur B-12. Toutes les lectures et écritures passent par les RPC
/// serveur sous le JWT courant; aucun profil ou rôle ne vient du client.
class EchangesControleurSupabase implements PortEchanges {
  EchangesControleurSupabase(this._client, {this._generateur = const Uuid()});

  final SupabaseClient _client;
  final Uuid _generateur;
  final Map<String, String> _clesApresEchec = <String, String>{};

  @override
  Future<List<FilEchange>> fils() async =>
      _fils(await _client.rpc<List<dynamic>>('controleur_lister_fils'));

  @override
  Future<FilEchange> filDeMission(String missionId) async {
    final Object? value = await _client.rpc<Object?>(
      'controleur_fil_de_mission',
      params: <String, dynamic>{'p_mission_id': missionId},
    );
    if (value is! Map) throw const FormatException('Fil invalide.');
    return _fil(Map<String, dynamic>.from(value));
  }

  @override
  Future<void> envoyer(String filId, String texte) async {
    final String message = texte.trim();
    if (message.isEmpty) throw ArgumentError.value(texte, 'texte');
    final String commande = '$filId\u0000$message';
    final String cle = _clesApresEchec[commande] ?? _generateur.v4();
    try {
      await _client.rpc<void>(
        'controleur_envoyer_message',
        params: <String, dynamic>{
          'p_fil_id': filId,
          'p_cle_client': cle,
          'p_texte': message,
        },
      );
      _clesApresEchec.remove(commande);
    } catch (_) {
      // Reutilise la cle apres un timeout/retry afin que la contrainte unique
      // du serveur rende le renvoi idempotent. Une reussite libere la cle.
      _clesApresEchec[commande] = cle;
      rethrow;
    }
  }
}

List<FilEchange> _fils(Object? value) {
  if (value is! List) throw const FormatException('Liste de fils invalide.');
  return value
      .map((Object? item) {
        if (item is! Map) throw const FormatException('Fil invalide.');
        return _fil(Map<String, dynamic>.from(item));
      })
      .toList(growable: false);
}

FilEchange _fil(Map<String, dynamic> row) {
  final Object? messages = row['messages'];
  if (messages is! List) throw const FormatException('Messages invalides.');
  return FilEchange(
    id: _string(row, 'id'),
    missionId: _string(row, 'mission_id'),
    classe: _string(row, 'classe'),
    debutMission: _date(row, 'debut_mission'),
    etat: switch (row['etat']) {
      'reponse_recue' => EtatFilEchange.reponseRecue,
      'en_attente' => EtatFilEchange.enAttente,
      _ => throw const FormatException('État de fil inconnu.'),
    },
    messages: messages
        .map((Object? item) {
          if (item is! Map) throw const FormatException('Message invalide.');
          final Map<String, dynamic> message = Map<String, dynamic>.from(item);
          return MessageEchange(
            id: _string(message, 'id'),
            auteur: switch (message['auteur']) {
              'controleur' => AuteurEchange.controleur,
              'administration' => AuteurEchange.administration,
              _ => throw const FormatException('Auteur de message inconnu.'),
            },
            texte: _string(message, 'texte'),
            date: _date(message, 'date'),
          );
        })
        .toList(growable: false),
  );
}

String _string(Map<String, dynamic> row, String key) {
  final Object? value = row[key];
  if (value is! String) throw FormatException('Champ $key invalide.');
  return value;
}

DateTime _date(Map<String, dynamic> row, String key) {
  final DateTime? value = DateTime.tryParse(_string(row, key));
  if (value == null) throw FormatException('Date $key invalide.');
  return value.toLocal();
}
