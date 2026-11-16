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

import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/communications_supabase.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_delais.dart';
import '../../core/widgets/fil_discussion.dart' show EnvoiRefuse;
import 'fonctions_images_messages.dart';
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
  TypeObjetLie.candidature,
};

/// Les Messages metier servis par Supabase.
class MessagesMetierSupabase implements PortMessagesMetier {
  /// Cree l'adaptateur sur un appel RPC (le client de l'application, par
  /// [appelRpcSupabase], ou un faux dans les tests).
  MessagesMetierSupabase(
    this._appel, {
    required this.libelles,
    AppelFonction? fonctions,
    http.Client? transport,
    // ignore: prefer_initializing_formals
  }) : _fonctions = fonctions,
       _transport = transport ?? http.Client();

  final AppelRpc _appel;

  /// IMAGES-MESSAGERIE : les fonctions Edge ; `null` : aucune image.
  final AppelFonction? _fonctions;
  final http.Client _transport;

  /// Les miniatures lues, par fil (au plus [_filsGardes]) : UNE demande par
  /// fil ouvert, renouvelee seulement a l'expiration (1 h).
  final Map<String, Future<Map<String, AdresseImage>>> _miniatures =
      <String, Future<Map<String, AdresseImage>>>{};
  static const int _filsGardes = 6;

  /// Les mots composes a partir des donnees du serveur.
  final LibellesCommunication libelles;

  static const CapaciteIndisponible _lecture = CapaciteIndisponible(
    'COM-BR-01',
  );

  /// Monte a chaque ecriture (lu, envoi, ouverture) : une lecture de la liste
  /// partie avant ne sert jamais un appel arrive apres.
  int _generation = 0;
  Future<Object?>? _listeEnCours;
  int _listeGeneration = -1;
  DateTime _listeDepart = DateTime.fromMillisecondsSinceEpoch(0);

  /// `com_lister_fils` est le plus couteux des appels de la messagerie
  /// (15/11/2026, 85 % du temps de base) : les appels simultanes d'un meme
  /// signal rejoignent la lecture en cours, au lieu d'en lancer chacun une.
  Future<Object?> _listerFils() {
    final DateTime maintenant = DateTime.now();
    final Future<Object?>? enCours = _listeEnCours;
    if (enCours != null &&
        _listeGeneration == _generation &&
        maintenant.difference(_listeDepart) < AppDelais.jonctionListeFils) {
      return enCours;
    }
    final int generation = _generation;
    final Future<Object?> lecture = _appel(
      'com_lister_fils',
      const <String, dynamic>{},
    );
    _listeEnCours = lecture;
    _listeGeneration = generation;
    _listeDepart = maintenant;
    return lecture;
  }

  Future<Object?> _lire(String fonction, Map<String, dynamic> p) async {
    final bool liste = fonction == 'com_lister_fils';
    if (!liste) _generation += 1;
    try {
      return await (liste ? _listerFils() : _appel(fonction, p));
    } on Object catch (e) {
      if (estRefusOuAbsence(e)) throw _lecture;
      rethrow;
    } finally {
      if (!liste) _generation += 1;
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
            candidat: type == TypeObjetLie.candidature,
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
    await _poster(filId, texte, cleIdempotence);
  }

  /// Poste le message ; rend son identifiant.
  Future<String> _poster(String filId, String texte, String cle) async {
    final String message = texte.trim();
    if (message.isEmpty) throw ArgumentError.value(texte, 'texte');
    if (!estUuid(filId)) throw ArgumentError.value(filId, 'filId');
    // Un refus d'envoi reste un echec (« non confirme ») : il n'est pas
    // converti en capacite indisponible.
    final Object? reponse;
    _generation += 1;
    try {
      reponse = await _appel('com_envoyer_message', <String, dynamic>{
        'p_fil_id': filId,
        'p_texte': message,
        'p_cle_idempotence': cleServeur(cle),
      });
    } on PostgrestException catch (e) {
      // MESSAGES-CANDIDAT : la limite de 30 messages par jour d'un candidat
      // (SQLSTATE 53400) se dit, sans « Reessayer » qui ne changerait rien.
      if (e.code == '53400') {
        throw EnvoiRefuse(t.com.messages.candidature.plafond);
      }
      rethrow;
    } finally {
      _generation += 1;
    }
    return texteJson(objetJson(reponse), 'id');
  }

  @override
  Future<void> envoyerImage(
    String filId,
    String texte,
    String cleIdempotence,
    ImagePrete image, {
    ProgressionImage? progression,
  }) async {
    final AppelFonction? fonctions = _fonctions;
    if (fonctions == null) throw const CapaciteIndisponible('COM-BR-02');
    final String messageId = await _poster(filId, texte, cleIdempotence);
    progression?.call(0.05);
    final Map<String, dynamic> depot = await fonctions(
      'message-image-depot',
      <String, dynamic>{
        'action': 'demander',
        'message_id': messageId,
        'image': <String, dynamic>{
          'mime': image.mime,
          'octets': image.octets.length,
          'largeur': image.largeur,
          'hauteur': image.hauteur,
          if (image.couleurMoyenne != null)
            'couleur_moyenne': image.couleurMoyenne,
        },
        'miniature': <String, dynamic>{
          'mime': image.mimeMiniature,
          'octets': image.miniature.length,
        },
      },
    );
    final String imageId = texteJson(depot, 'image_id');
    progression?.call(0.1);
    await _deposer(objetJson(depot['image']), image.octets);
    progression?.call(0.85);
    await _deposer(objetJson(depot['miniature']), image.miniature);
    progression?.call(0.95);
    await fonctions('message-image-depot', <String, dynamic>{
      'action': 'confirmer',
      'image_id': imageId,
    });
    progression?.call(1);
    unawaited(_miniatures.remove(filId));
  }

  /// Le `PUT` signe : exactement les en-tetes exiges par le serveur.
  Future<void> _deposer(Map<String, dynamic> cible, Uint8List octets) async {
    final Uri url = Uri.parse(texteJson(cible, 'url'));
    final Object? exiges = cible['en_tetes_exiges'];
    if (url.scheme != 'https' || exiges is! Map) {
      throw const EchecImage(RefusImage.depotImpossible);
    }
    final http.StreamedResponse reponse;
    try {
      final http.Request demande = http.Request('PUT', url)
        ..headers.addAll(<String, String>{
          for (final MapEntry<Object?, Object?> e in exiges.entries)
            if (e.key is String &&
                e.value is String &&
                e.key != 'content-length')
              e.key! as String: e.value! as String,
        })
        ..bodyBytes = octets;
      reponse = await _transport.send(demande);
      await reponse.stream.drain<void>();
    } on Object {
      // Aucune reponse du stockage : l'envoi a coupe, ou l'origine du seau
      // refuse cette adresse.
      throw const EchecImage(RefusImage.envoiStockage);
    }
    if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
      throw const EchecImage(RefusImage.envoiStockage);
    }
  }

  @override
  Future<Map<String, AdresseImage>> urlsMiniatures(String filId) {
    final AppelFonction? fonctions = _fonctions;
    if (fonctions == null || !estUuid(filId)) {
      return Future<Map<String, AdresseImage>>.value(
        const <String, AdresseImage>{},
      );
    }
    final Future<Map<String, AdresseImage>>? gardees = _miniatures[filId];
    if (gardees != null) {
      return gardees.then((Map<String, AdresseImage> m) {
        final bool perimees = m.values.any(
          (AdresseImage a) => !a.expireLe.isAfter(DateTime.now()),
        );
        if (!perimees) return m;
        _miniatures.remove(filId);
        return urlsMiniatures(filId);
      });
    }
    while (_miniatures.length >= _filsGardes) {
      _miniatures.remove(_miniatures.keys.first);
    }
    final Future<Map<String, AdresseImage>> demande = _lireAdresses(
      fonctions,
      <String, dynamic>{'fil_id': filId},
    );
    _miniatures[filId] = demande;
    // Un echec ne reste pas en memoire : la prochaine ouverture redemande.
    unawaited(
      demande.then<void>((_) {}, onError: (_) => _miniatures.remove(filId)),
    );
    return demande;
  }

  @override
  Future<AdresseImage?> urlImage(String filId, String imageId) async {
    final AppelFonction? fonctions = _fonctions;
    if (fonctions == null || !estUuid(filId) || !estUuid(imageId)) return null;
    final Map<String, AdresseImage> lues = await _lireAdresses(
      fonctions,
      <String, dynamic>{'fil_id': filId, 'image_id': imageId},
    );
    return lues[imageId];
  }

  Future<Map<String, AdresseImage>> _lireAdresses(
    AppelFonction fonctions,
    Map<String, dynamic> corps,
  ) async {
    final Map<String, dynamic> reponse = await fonctions(
      'message-images-lecture',
      corps,
    );
    final DateTime maintenant = DateTime.now();
    final Map<String, AdresseImage> rendues = <String, AdresseImage>{};
    for (final Map<String, dynamic> l in listeJson(reponse['images'])) {
      final Object? url = l['url'];
      final Object? id = l['id'];
      if (id is! String || url is! String) continue;
      final Object? duree = l['expire_dans_secondes'];
      // Une minute de marge : on renouvelle avant l'expiration reelle.
      final int secondes = (duree is int ? duree : 3600) - 60;
      rendues[id] = AdresseImage(
        url: url,
        expireLe: maintenant.add(Duration(seconds: secondes)),
      );
    }
    return rendues;
  }

  @override
  Future<EtatCoeur> aimer(String messageId) =>
      _coeur('aimer_message', messageId);

  @override
  Future<EtatCoeur> nePlusAimer(String messageId) =>
      _coeur('ne_plus_aimer_message', messageId);

  Future<EtatCoeur> _coeur(String fonction, String messageId) async {
    if (!estUuid(messageId)) throw ArgumentError.value(messageId, 'messageId');
    final Map<String, dynamic> r = objetJson(
      await _appel(fonction, <String, dynamic>{'p_message': messageId}),
    );
    final Object? n = r['coeurs'];
    return EtatCoeur(
      coeurs: n is int && n > 0 ? n : 0,
      aimeParMoi: r['aime_par_moi'] == true,
    );
  }
}

IndicateurAttention _attention(Object? nonLus) {
  final int n = nonLus is int && nonLus > 0 ? nonLus : 0;
  return n == 0
      ? IndicateurAttention.aucun
      : IndicateurAttention(nonLus: n, niveau: NiveauAttention.aLire);
}

/// Un fil de candidature : son objet est une candidature.
bool _estCandidature(Map<String, dynamic> fil) =>
    TypeObjetLie.depuis(texteOptionnel(objetJson(fil['objet']), 'type')) ==
    TypeObjetLie.candidature;

List<Participant> _parties(
  Map<String, dynamic> fil,
  LibellesCommunication libelles,
) => <Participant>[
  for (final Map<String, dynamic> p in listeJson(fil['parties']))
    participantJson(p, libelles, candidat: _estCandidature(fil)),
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
          auteur: participantJson(
            objetJson(m['auteur']),
            libelles,
            candidat: _estCandidature(fil),
          ),
          texte: texteJson(m, 'texte'),
          envoyeLe: instantJson(m, 'envoye_le'),
          image: ImageMessage.depuisJson(m['image']),
          coeurs: m['coeurs'] is int && (m['coeurs'] as int) > 0
              ? m['coeurs'] as int
              : 0,
          aimeParMoi: m['aime_par_moi'] == true,
        ),
    ],
    attention: _attention(fil['non_lus']),
    capacites: <CapaciteFil>{
      if (fil['peut_ecrire'] == true) CapaciteFil.ecrire,
    },
    luParAutresLe: instantOptionnel(fil, 'lu_par_autres_le'),
  );
}
