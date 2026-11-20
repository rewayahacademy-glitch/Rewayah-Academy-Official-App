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
// Seconde regle (relecture adverse 2 de la PR 657) : JAMAIS de fil troue. Quand
// la nouvelle page ne recoupe plus rien de ce qui etait affiche (plus de 50
// arrivees entre deux relectures, telephone en veille par exemple), l'ecran
// garde ce qu'il montrait et la memoire charge aussitot les pages qui
// comblent le trou ([pagesComblement] au plus), puis montre tout d'un coup.
// Au-dela, ou si la lecture echoue, la memoire repart de la page la plus
// recente : la vue se cale sur les derniers messages ([recalages]) et la
// rangee « Chargement des messages precedents » ramene la suite.
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

  /// Le nombre de pages lues au plus pour combler un trou, avant de repartir
  /// de la page la plus recente.
  static const int pagesComblement = 4;

  /// Le fil dont les messages sont montres (la base de [messages]).
  FilMetier? _fil;

  /// Le dernier fil recu (une meme instance n'est traitee qu'une fois).
  FilMetier? _recu;

  List<MessageCommunication> _anciens = const <MessageCommunication>[];

  /// `null` tant qu'aucun message n'est garde hors de la page rendue : le fil
  /// rendu dit alors lui-meme s'il en reste de plus anciens.
  bool? _plusAnciens;

  bool _enCours = false;

  /// Un trou est en train d'etre comble : le dernier fil recu attend ici.
  FilMetier? _enAttente;

  /// Change a chaque remise a zero et a chaque comblement : une lecture
  /// partie avant ne s'applique plus.
  int _generation = 0;

  bool _liberee = false;

  int _recalages = 0;

  /// Augmente quand la memoire est repartie de la page la plus recente (trou
  /// trop grand, ou lecture du trou en echec) : l'ecran cale alors sa lecture
  /// sur les derniers messages, la ou la personne retrouve le fil.
  int get recalages => _recalages;

  /// Recoit le fil rendu par la derniere lecture. Les messages de la lecture
  /// precedente plus anciens que la nouvelle page, et absents d'elle, sont
  /// gardes. Un autre fil remet la memoire a zero. Ne previent personne :
  /// appelee pendant la construction.
  void recevoir(FilMetier fil) {
    if (identical(_recu, fil)) return;
    _recu = fil;
    if (_enAttente != null && _fil?.id == fil.id) {
      // Le comblement en cours s'appliquera a ce fil, le plus recent.
      _enAttente = fil;
      return;
    }
    _integrer(fil);
  }

  void _integrer(FilMetier fil) {
    final FilMetier? avant = _fil;
    if (avant == null || avant.id != fil.id) {
      _remettre(fil);
      return;
    }
    final Set<String> page = <String>{
      for (final MessageCommunication m in fil.messages) m.id,
    };
    final List<MessageCommunication> connus = _messagesDe(avant);
    if (_troue(connus, fil, page)) {
      if (lire == null) {
        _repartir(fil, const <MessageCommunication>[], null);
        return;
      }
      // L'ecran garde ce qu'il montre ; la memoire comble le trou hors de la
      // construction, puis montre tout.
      _enAttente = fil;
      final int generation = ++_generation;
      final bool plusAvant = _plusAnciens ?? avant.plusAnciens;
      Future<void>(() => _combler(generation, connus, fil, plusAvant));
      return;
    }
    _fil = fil;
    final DateTime? debut = fil.messages.isEmpty
        ? null
        : fil.messages.first.envoyeLe;
    final List<MessageCommunication> retenus = <MessageCommunication>[
      for (final MessageCommunication m in connus)
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

  /// La nouvelle page ne recoupe rien de ce qui etait montre, alors qu'il
  /// reste des messages avant elle : entre les deux, un trou.
  bool _troue(
    List<MessageCommunication> connus,
    FilMetier fil,
    Set<String> page,
  ) {
    if (connus.isEmpty || fil.messages.isEmpty || !fil.plusAnciens) {
      return false;
    }
    if (connus.any((MessageCommunication m) => page.contains(m.id))) {
      return false;
    }
    // Une page entierement plus ancienne que ce qui est montre n'est pas un
    // trou devant lui (aucune arrivee) : elle se range comme avant.
    return !fil.messages.last.envoyeLe.isBefore(connus.last.envoyeLe);
  }

  void _remettre(FilMetier fil) {
    _generation++;
    _fil = fil;
    _anciens = const <MessageCommunication>[];
    _plusAnciens = null;
    _enAttente = null;
    _enCours = false;
  }

  /// Repart de [fil] (la page la plus recente) et des pages [chargees] qui
  /// la precedent ; l'ecran cale sa lecture sur les derniers messages.
  void _repartir(
    FilMetier fil,
    List<MessageCommunication> chargees,
    bool? plusAnciens,
  ) {
    final Set<String> page = <String>{
      for (final MessageCommunication m in fil.messages) m.id,
    };
    _fil = fil;
    _anciens = List<MessageCommunication>.unmodifiable(<MessageCommunication>[
      for (final MessageCommunication m in chargees)
        if (!page.contains(m.id)) m,
    ]);
    _plusAnciens = _anciens.isEmpty ? null : plusAnciens;
    _recalages++;
  }

  Future<void> _combler(
    int generation,
    List<MessageCommunication> connus,
    FilMetier cible,
    bool plusAvant,
  ) async {
    final LirePageAnterieure? lecture = lire;
    if (_liberee || generation != _generation || lecture == null) return;
    final Set<String> ids = <String>{
      for (final MessageCommunication m in connus) m.id,
    };
    List<MessageCommunication> chargees = const <MessageCommunication>[];
    String avantId = cible.messages.first.id;
    bool joint = false;
    bool plus = true;
    bool echec = false;
    _enCours = true;
    notifyListeners();
    try {
      for (int i = 0; i < pagesComblement && !joint && plus; i++) {
        final PageMessagesFil p = await lecture(avantId);
        if (_liberee || generation != _generation) return;
        chargees = <MessageCommunication>[...p.messages, ...chargees];
        plus = p.plusAnciens;
        if (p.messages.isEmpty) break;
        joint = p.messages.any((MessageCommunication m) => ids.contains(m.id));
        avantId = p.messages.first.id;
      }
    } on Object {
      if (_liberee || generation != _generation) return;
      echec = true;
    }
    if (_liberee || generation != _generation) return;
    final FilMetier dernier = _enAttente ?? cible;
    _enAttente = null;
    _enCours = false;
    _generation++;
    if (!echec && joint) {
      // Le trou est comble : tout se montre, dans l'ordre, sans doublon ; la
      // lecture de la personne ne bouge pas. Sinon (trou trop grand, lecture
      // en echec, ou page qui ne rejoint rien), on repart des plus recents.
      final Set<String> vus = <String>{};
      final List<MessageCommunication> fusion = <MessageCommunication>[
        for (final MessageCommunication m in <MessageCommunication>[
          ...connus,
          ...chargees,
        ])
          if (vus.add(m.id)) m,
      ];
      mergeSort<MessageCommunication>(
        fusion,
        compare: (MessageCommunication a, MessageCommunication b) =>
            a.envoyeLe.compareTo(b.envoyeLe),
      );
      final Set<String> page = <String>{
        for (final MessageCommunication m in cible.messages) m.id,
      };
      _fil = cible;
      _anciens = List<MessageCommunication>.unmodifiable(<MessageCommunication>[
        for (final MessageCommunication m in fusion)
          if (!page.contains(m.id)) m,
      ]);
      _plusAnciens = plus && plusAvant;
    } else {
      _repartir(cible, chargees, plus);
    }
    // Un fil arrive pendant le comblement se range comme d'habitude (il peut
    // a son tour ouvrir un trou, comble de la meme facon).
    if (!identical(dernier, cible)) _integrer(dernier);
    notifyListeners();
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

  /// Une page ancienne est en cours de lecture (ou un trou se comble).
  bool get enCours => _enCours;

  /// Charge la page qui precede le plus ancien message connu. Echoue si la
  /// lecture echoue (l'ecran dit l'echec et propose « Reessayer »).
  Future<void> chargerAnciens() async {
    final LirePageAnterieure? lecture = lire;
    final List<MessageCommunication> connus = messages;
    if (lecture == null || connus.isEmpty || _enCours) return;
    final int generation = _generation;
    _enCours = true;
    notifyListeners();
    try {
      final PageMessagesFil page = await lecture(connus.first.id);
      if (_liberee || generation != _generation) return;
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
      if (!_liberee && generation == _generation) {
        _enCours = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _liberee = true;
    super.dispose();
  }
}
