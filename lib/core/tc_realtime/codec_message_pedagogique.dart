/// L'ecriture et la lecture d'un [MessagePedagogique] sur le fil.
///
/// **Les cles tiennent en une lettre**, comme celles de `ContenuPresente` dans
/// le socle, et pour la meme raison : le paquet part vers cinq ou six appareils
/// dont certains en 3G, et le canal ephemere en emet beaucoup. La charge, elle,
/// garde les cles lisibles que chaque agent a choisies -- le lot F ne la
/// reecrit pas, il l'emballe.
///
/// **Le codec vit hors du contrat.** `MessagePedagogique` est stube a
/// l'identique par Agent D ; lui ajouter des methodes ferait diverger son stub
/// du canonique.
library;

import 'dart:convert';

import '../observabilite/journal_dev.dart';
import 'port_realtime_pedagogique.dart';

/// Encode un message pour le fil.
List<int> messageVersOctets(MessagePedagogique message) =>
    utf8.encode(jsonEncode(messageVersJson(message)));

/// La forme JSON d'un message.
Map<String, dynamic> messageVersJson(MessagePedagogique message) =>
    <String, dynamic>{
      't': message.type,
      's': message.sessionId,
      'e': message.emetteurProfilId,
      'h': message.emisLeUtc.toUtc().millisecondsSinceEpoch,
      'c': message.charge,
    };

/// Decode un message recu. `null` quand le paquet est inexploitable.
///
/// **Un paquet illisible ne casse rien.** Il vient du reseau, donc d'une
/// version d'application qu'on ne controle pas ; le rattraper ici evite qu'un
/// client plus recent ne fasse tomber le canal d'un client plus ancien pour
/// tout le reste de la seance. Le socle tient deja exactement cette regle
/// (`LiveKitSessionProvider._recevoirDonnees`).
MessagePedagogique? messageDepuisOctets(List<int> octets) {
  try {
    final Object? decode = jsonDecode(utf8.decode(octets));
    return messageDepuisJson(decode);
  } catch (e) {
    journalDev('message pedagogique illisible : $e');
    return null;
  }
}

/// Lit un message depuis sa forme JSON. `null` si un champ obligatoire manque.
MessagePedagogique? messageDepuisJson(Object? brut) {
  if (brut is! Map<String, dynamic>) {
    return null;
  }
  final String? type = brut['t'] as String?;
  final String? sessionId = brut['s'] as String?;
  final String? emetteur = brut['e'] as String?;
  final int? instant = brut['h'] as int?;
  final Object? charge = brut['c'];
  if (type == null ||
      sessionId == null ||
      emetteur == null ||
      instant == null ||
      charge is! Map<String, dynamic>) {
    return null;
  }
  return MessagePedagogique(
    type: type,
    sessionId: sessionId,
    emetteurProfilId: emetteur,
    charge: charge,
    emisLeUtc: DateTime.fromMillisecondsSinceEpoch(instant, isUtc: true),
  );
}

/// L'empreinte d'un message, pour ecarter un paquet livre deux fois.
///
/// C'est la forme encodee elle-meme : **deux messages identiques au bit pres
/// sont le meme message**, et il n'existe pas de champ d'identifiant unique
/// dans l'enveloppe -- l'y ajouter ferait diverger le stub d'Agent D du
/// contrat canonique.
///
/// Plafond assume : deux messages reellement distincts, de meme type, du meme
/// emetteur, a la meme milliseconde et de charge identique seraient confondus.
/// Pour les messages qui empruntent le canal fiable -- un tour de page, un
/// rappel discret -- deux emissions indiscernables a la milliseconde pres
/// doivent de toute facon produire un seul effet.
String empreinteMessage(MessagePedagogique message) =>
    jsonEncode(messageVersJson(message));
