// PE-D1 MESSAGERIE-FIABLE : la memoire des messages d'une conversation
// ouverte, quand le serveur ne rend que la page la plus recente
// (`com_lire_fil_page`, 50 messages).
//
// Une regle : AUCUN message deja affiche ne quitte l'ecran tant que la
// conversation est ouverte. Chaque relecture rend les 50 derniers messages ;
// ceux de la lecture precedente qui n'y sont plus (plus anciens que la
// nouvelle page) sont verses ici, dans l'ordre et sans doublon, avec les pages
// anciennes chargees en remontant.
//
// Le fil (`FilContextuel`) et le panneau de contexte (« Fichiers partages »)
// lisent la meme memoire : le panneau voit tous les messages charges, dit
// quand la liste est partielle et propose de charger la suite.

import 'package:flutter/foundation.dart';

import 'port_messages_metier.dart';

/// La lecture d'une page plus ancienne : les messages qui precedent le message
/// `avantId`.
typedef LirePageAnterieure = Future<PageMessagesFil> Function(String avantId);

/// La memoire des messages d'une conversation ouverte.
class MemoirePagesFil extends ChangeNotifier {
  /// Cree la memoire ; [lire] : la lecture des pages anciennes, ou `null`
  /// quand le port ne lit pas par pages (le fil rendu est alors entier).
  MemoirePagesFil({this.lire});

  /// La lecture des pages anciennes, ou `null`.
  final LirePageAnterieure? lire;

  FilMetier? _fil;
  List<MessageCommunication> _anciens = const <MessageCommunication>[];

  /// `null` tant qu'aucun message n'est garde hors de la page rendue : le fil
  /// rendu dit alors lui-meme s'il en reste de plus anciens.
  bool? _plusAnciens;

  bool _enCours = false;

  /// Recoit le fil rendu par la derniere lecture. Les messages de la lecture
  /// precedente plus anciens que la nouvelle page, et absents d'elle, sont
  /// gardes. Un autre fil remet la memoire a zero. Ne previent personne :
  /// appelee pendant la construction.
  void recevoir(FilMetier fil) {
    final FilMetier? avant = _fil;
    if (identical(avant, fil)) return;
    _fil = fil;
    if (avant == null || avant.id != fil.id) {
      _anciens = const <MessageCommunication>[];
      _plusAnciens = null;
      return;
    }
    final Set<String> page = <String>{
      for (final MessageCommunication m in fil.messages) m.id,
    };
    final DateTime? debut = fil.messages.isEmpty
        ? null
        : fil.messages.first.envoyeLe;
    final List<MessageCommunication> retenus = <MessageCommunication>[
      for (final MessageCommunication m in _messagesDe(avant))
        if (!page.contains(m.id) &&
            (debut == null || !m.envoyeLe.isAfter(debut)))
          m,
    ];
    // Le plus ancien message garde etait celui de la page precedente : ce
    // qu'elle disait des messages plus anciens vaut encore.
    if (_anciens.isEmpty && retenus.isNotEmpty) {
      _plusAnciens ??= avant.plusAnciens;
    }
    _anciens = List<MessageCommunication>.unmodifiable(retenus);
  }

  List<MessageCommunication> _messagesDe(FilMetier fil) {
    if (_anciens.isEmpty) return fil.messages;
    final Set<String> page = <String>{
      for (final MessageCommunication m in fil.messages) m.id,
    };
    return <MessageCommunication>[
      for (final MessageCommunication m in _anciens)
        if (!page.contains(m.id)) m,
      ...fil.messages,
    ];
  }

  /// Tous les messages connus, du plus ancien au plus recent, sans doublon.
  List<MessageCommunication> get messages {
    final FilMetier? fil = _fil;
    return fil == null ? const <MessageCommunication>[] : _messagesDe(fil);
  }

  /// Il reste des messages plus anciens que [messages] sur le serveur.
  bool get plusAnciens => _plusAnciens ?? _fil?.plusAnciens ?? false;

  /// Une page ancienne est en cours de lecture.
  bool get enCours => _enCours;

  /// Charge la page qui precede le plus ancien message connu. Echoue si la
  /// lecture echoue (l'ecran dit l'echec et propose « Reessayer »).
  Future<void> chargerAnciens() async {
    final LirePageAnterieure? lecture = lire;
    final List<MessageCommunication> connus = messages;
    if (lecture == null || connus.isEmpty || _enCours) return;
    _enCours = true;
    notifyListeners();
    try {
      final PageMessagesFil page = await lecture(connus.first.id);
      final Set<String> deja = <String>{
        for (final MessageCommunication m in messages) m.id,
      };
      _anciens = List<MessageCommunication>.unmodifiable(<MessageCommunication>[
        for (final MessageCommunication m in page.messages)
          if (!deja.contains(m.id)) m,
        ..._anciens,
      ]);
      _plusAnciens = page.plusAnciens;
    } finally {
      _enCours = false;
      notifyListeners();
    }
  }
}
