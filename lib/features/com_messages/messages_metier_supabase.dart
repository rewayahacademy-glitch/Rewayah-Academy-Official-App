// L'adaptateur Supabase des Messages metier (COM-BACK-1 ; COM-BR-01,
// COM-BR-02), sur les RPC `com_*` de la migration 20261016090000.
//
// Le serveur decide de tout : les paires autorisees (spec section 3.2), le
// fil absent quand il est refuse (`null`), la capacite d'ecrire. Un refus de
// compte (eleve mineur, compte desactive) ou une RPC pas encore deployee se
// lit comme une capacite indisponible, jamais comme une liste vide inventee.
//
// Non branche par defaut : `portMessagesMetierProvider` reste neutre tant que
// les migrations ne sont pas appliquees et que les libelles ne sont pas
// fournis (voir le rapport COM-BACK-1).

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/communications_supabase.dart';
import 'port_messages_metier.dart';

/// La longueur de l'apercu d'un fil dans la liste.
const int longueurApercuFil = 140;

/// Les types d'objet que le serveur sait porter ; les autres ne sont pas
/// demandes (aucun fil, sans appel).
const Set<TypeObjetLie> _typesServeur = <TypeObjetLie>{
  TypeObjetLie.classe,
  TypeObjetLie.eleve,
  TypeObjetLie.dossier,
  TypeObjetLie.remplacement,
  TypeObjetLie.profilPaiement,
};

/// Les Messages metier servis par Supabase.
class MessagesMetierSupabase implements PortMessagesMetier {
  /// Cree l'adaptateur sur un appel RPC (le client de l'application, par
  /// [appelRpcSupabase], ou un faux dans les tests).
  const MessagesMetierSupabase(this._appel, {required this.libelles});

  final AppelRpc _appel;

  /// Les mots composes a partir des donnees du serveur.
  final LibellesCommunication libelles;

  static const CapaciteIndisponible _lecture = CapaciteIndisponible(
    'COM-BR-01',
  );

  Future<Object?> _lire(String fonction, Map<String, dynamic> p) async {
    try {
      return await _appel(fonction, p);
    } on Object catch (e) {
      if (estRefusOuAbsence(e)) throw _lecture;
      rethrow;
    }
  }

  Future<FilMetier?> _filOuNull(String fonction, Map<String, dynamic> p) async {
    try {
      final Object? v = await _lire(fonction, p);
      return v == null ? null : filMetierJson(objetJson(v), libelles);
    } on CapaciteIndisponible {
      return null;
    }
  }

  @override
  Future<List<ResumeFil>> fils() async {
    final List<Map<String, dynamic>> lignes = listeJson(
      await _lire('com_lister_fils', const <String, dynamic>{}),
    );
    return List<ResumeFil>.unmodifiable(<ResumeFil>[
      for (final Map<String, dynamic> l in lignes)
        if (_resume(l) case final ResumeFil r when estFilMetier(r)) r,
    ]);
  }

  ResumeFil? _resume(Map<String, dynamic> l) {
    try {
      return resumeFilJson(l, libelles);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<FilMetier?> fil(String filId) async {
    if (!estUuid(filId)) return null;
    return _filOuNull('com_lire_fil', <String, dynamic>{'p_fil_id': filId});
  }

  @override
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId) async {
    if (!_typesServeur.contains(type) || !estUuid(objetId)) return null;
    return _filOuNull('com_fil_pour_objet', <String, dynamic>{
      'p_type': type.name,
      'p_objet_id': objetId,
    });
  }

  @override
  Future<FilMetier?> ouvrirConversation(
    ConversationPossible conversation,
  ) async {
    final ObjetLie objet = conversation.objet;
    if (!_typesServeur.contains(objet.type) || !estUuid(objet.id)) {
      return null;
    }
    return _filOuNull('com_ouvrir_conversation', <String, dynamic>{
      'p_type': objet.type.name,
      'p_objet_id': objet.id,
      'p_interlocuteur': conversation.interlocuteur.id,
    });
  }

  @override
  Future<List<ConversationPossible>> conversationsPourObjet(
    TypeObjetLie type,
    String objetId,
  ) async {
    if (!_typesServeur.contains(type) || !estUuid(objetId)) {
      return const <ConversationPossible>[];
    }
    final List<Map<String, dynamic>> lignes = listeJson(
      await _lire('com_conversations_pour_objet', <String, dynamic>{
        'p_type': type.name,
        'p_objet_id': objetId,
      }),
    );
    return List<ConversationPossible>.unmodifiable(<ConversationPossible>[
      for (final Map<String, dynamic> l in lignes)
        ConversationPossible(
          interlocuteur: participantJson(
            objetJson(l['interlocuteur']),
            libelles,
          ),
          objet: objetLieJson(objetJson(l['objet']), libelles),
          nature: switch (l['nature']) {
            'famille' => NatureInterlocuteur.famille,
            'administration' => NatureInterlocuteur.administration,
            _ => NatureInterlocuteur.personne,
          },
          filId: texteOptionnel(l, 'fil_id'),
          attention: _attention(l['non_lus']),
        ),
    ]);
  }

  @override
  Future<void> marquerLu(String filId) async {
    if (!estUuid(filId)) throw ArgumentError.value(filId, 'filId');
    await _lire('com_marquer_lu', <String, dynamic>{'p_fil_id': filId});
  }

  @override
  Future<void> envoyer(
    String filId,
    String texte,
    String cleIdempotence,
  ) async {
    final String message = texte.trim();
    if (message.isEmpty) throw ArgumentError.value(texte, 'texte');
    if (!estUuid(filId)) throw ArgumentError.value(filId, 'filId');
    // Un refus d'envoi reste un echec (« non confirme ») : il n'est pas
    // converti en capacite indisponible.
    final Map<String, dynamic> accuse = objetJson(
      await _appel('com_envoyer_message', <String, dynamic>{
        'p_fil_id': filId,
        'p_texte': message,
        'p_cle_idempotence': cleServeur(cleIdempotence),
      }),
    );
    texteJson(accuse, 'id');
  }
}

IndicateurAttention _attention(Object? nonLus) {
  final int n = nonLus is int && nonLus > 0 ? nonLus : 0;
  return n == 0
      ? IndicateurAttention.aucun
      : IndicateurAttention(nonLus: n, niveau: NiveauAttention.aLire);
}

List<Participant> _parties(
  Map<String, dynamic> fil,
  LibellesCommunication libelles,
) => <Participant>[
  for (final Map<String, dynamic> p in listeJson(fil['parties']))
    participantJson(p, libelles),
];

/// Le resume d'un fil rendu par `com_lister_fils`.
ResumeFil resumeFilJson(
  Map<String, dynamic> fil,
  LibellesCommunication libelles,
) {
  final List<Map<String, dynamic>> messages = listeJson(fil['messages']);
  final String? dernier = messages.isEmpty
      ? null
      : texteOptionnel(messages.last, 'texte');
  return ResumeFil(
    id: texteJson(fil, 'id'),
    objet: objetLieJson(objetJson(fil['objet']), libelles),
    interlocuteurs: <Participant>[
      for (final Participant p in _parties(fil, libelles))
        if (!p.estSoi) p,
    ],
    apercu: dernier == null || dernier.length <= longueurApercuFil
        ? dernier
        : dernier.substring(0, longueurApercuFil),
    dernierMessageLe: instantOptionnel(fil, 'dernier_message_le'),
    attention: _attention(fil['non_lus']),
  );
}

/// Un fil complet rendu par `com_lire_fil` ou `com_ouvrir_conversation`.
FilMetier filMetierJson(
  Map<String, dynamic> fil,
  LibellesCommunication libelles,
) {
  final ObjetLie objet = objetLieJson(objetJson(fil['objet']), libelles);
  return FilMetier(
    id: texteJson(fil, 'id'),
    contexte: <ElementContexteFil>[
      ElementContexteFil(objet: objet, accessible: fil['accessible'] == true),
    ],
    participants: _parties(fil, libelles),
    messages: <MessageCommunication>[
      for (final Map<String, dynamic> m in listeJson(fil['messages']))
        MessageCommunication(
          id: texteJson(m, 'id'),
          auteur: participantJson(objetJson(m['auteur']), libelles),
          texte: texteJson(m, 'texte'),
          envoyeLe: instantJson(m, 'envoye_le'),
        ),
    ],
    attention: _attention(fil['non_lus']),
    capacites: <CapaciteFil>{
      if (fil['peut_ecrire'] == true) CapaciteFil.ecrire,
    },
  );
}
