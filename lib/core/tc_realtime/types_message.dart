/// Les types de messages que le lot F possede, et les sujets de transport.
///
/// **Un type est un contrat de lecture de la charge**, pas une etiquette : le
/// recepteur decide comment lire `MessagePedagogique.charge` d'apres lui. Les
/// types sont donc nommes une seule fois, ici, et jamais recopies en litteral.
///
/// Repartition des espaces de noms, pour qu'aucun agent n'ecrase le type d'un
/// autre sur le meme canal :
///
/// | Prefixe | Proprietaire |
/// |---|---|
/// | `tc.etat_partage.*` | Agent F |
/// | `tc.realtime.*` | Agent F |
/// | `tc.outils.*` | Agent D (`evenements_outils.dart`) |
///
/// Le lot F **transporte** les types d'Agent D sans les connaitre : il ne les
/// declare pas ici, il ne les decode pas, il les route par canal. C'est
/// exactement ce que la regle « Agent D ne transporte pas lui-meme les strokes »
/// demande, et rien de plus.
library;

import 'port_realtime_pedagogique.dart';

/// Le support, la position, la plage, le mode : une revision complete.
///
/// La charge est `codec_etat_partage.etatVersJson(...)` augmentee de la clef
/// `cause`. **Toujours l'etat entier**, jamais un delta.
const String typeRevisionEtatPartage = 'tc.etat_partage.revision';

/// L'eleve dont c'est le tour. Fiable.
///
/// Charge : `{'academy_id': String?}`. `null` remet la classe au collectif.
/// **C'est un `academy_id`, jamais un nom** : la desambiguisation du produit se
/// fait par prenom plus identifiant d'academie (decision D-08), et le nom de
/// famille n'existe nulle part dans une projection enseignant.
const String typeEleveActif = 'tc.realtime.eleve_actif';

/// Le rappel discret, adresse a un seul participant. Fiable et cible.
///
/// Charge : `{'academy_id': String}`. **Rien d'autre** : pas de texte, pas de
/// motif, pas de nom. Le destinataire recoit un signal, pas un message.
const String typeRappelDiscret = 'tc.realtime.rappel_discret';

/// Le sujet du canal de donnees qui porte le protocole pedagogique.
///
/// **Un sujet nomme, jamais le canal nu.** Le socle pose deja la regle pour
/// `sujetContenuPresente` : LiveKit laisse passer n'importe quel paquet, et un
/// recepteur qui ne filtrerait pas lirait un paquet etranger comme un ordre
/// pedagogique. Le sujet du lot F est distinct de celui du socle : les deux
/// protocoles coexistent sans se lire l'un l'autre.
const String sujetProtocolePedagogique = 'tc-pedagogique';

/// Ce qui a motive une revision de l'etat partage.
///
/// **Informatif, jamais decisionnel.** L'etat transporte est complet : un
/// recepteur qui ignorerait la cause resterait correct. Elle existe pour que
/// l'interface puisse animer un tour de page autrement qu'un changement de
/// support, et pour que le journal se lise.
enum CauseRevision {
  /// Un autre support est devenu le support actif.
  support('support'),

  /// La position a change dans le meme support : page, verset, section.
  position('position'),

  /// La plage de travail a change.
  plage('plage'),

  /// Le mode d'affichage a change : page, verset, focus.
  mode('mode'),

  /// Les plages masquees ont change.
  masquage('masquage'),

  /// Les marqueurs semantiques ont change.
  marqueurs('marqueurs'),

  /// La position de reprise du groupe a change.
  reprise('reprise'),

  /// Restauration explicite, apres reconnexion de l'emetteur.
  restauration('restauration');

  const CauseRevision(this.valeurSql);

  /// La valeur telle qu'elle voyage et telle que la base l'attendra.
  final String valeurSql;

  /// Lit une cause. `null` sur valeur inconnue : une cause illisible ne doit
  /// **jamais** faire rejeter l'etat qu'elle accompagne.
  static CauseRevision? depuisSql(String? valeur) {
    for (final CauseRevision c in CauseRevision.values) {
      if (c.valeurSql == valeur) {
        return c;
      }
    }
    return null;
  }
}

/// Le message qui annonce l'eleve dont c'est le tour.
///
/// **Le type et la forme de sa charge sont decides au meme endroit**, ici :
/// laisser chaque appelant composer la carte lui-meme produirait deux clefs
/// voisines sur le meme canal, et un jour l'une serait lue pour l'autre.
///
/// [academyId] a `null` remet la classe au collectif. **C'est un `academy_id`,
/// jamais un nom** : la desambiguisation du produit se fait par prenom plus
/// identifiant d'academie (decision D-08).
MessagePedagogique messageEleveActif({
  required String sessionId,
  required String emetteurProfilId,
  required DateTime maintenantUtc,
  String? academyId,
}) => MessagePedagogique(
  type: typeEleveActif,
  sessionId: sessionId,
  emetteurProfilId: emetteurProfilId,
  charge: <String, dynamic>{'academy_id': academyId},
  emisLeUtc: maintenantUtc.toUtc(),
);

/// Le message du rappel discret, adresse a un seul participant.
///
/// **Rien d'autre que l'identifiant du destinataire ne voyage** : pas de texte,
/// pas de motif, pas de nom. Le destinataire recoit un signal, pas un message,
/// et l'enseignant n'obtient aucun accuse de reception (CONTRACTS section 12).
MessagePedagogique messageRappelDiscret({
  required String sessionId,
  required String emetteurProfilId,
  required String academyId,
  required DateTime maintenantUtc,
}) => MessagePedagogique(
  type: typeRappelDiscret,
  sessionId: sessionId,
  emetteurProfilId: emetteurProfilId,
  charge: <String, dynamic>{'academy_id': academyId},
  emisLeUtc: maintenantUtc.toUtc(),
);

/// Lit l'`academy_id` porte par un message d'eleve actif ou de rappel discret.
///
/// Rend `null` quand la charge n'en porte pas -- ce qui, pour
/// [typeEleveActif], est la valeur legitime « retour au collectif », et pour
/// [typeRappelDiscret] un paquet a ignorer.
String? academyIdDeCharge(MessagePedagogique message) =>
    message.charge['academy_id'] as String?;

