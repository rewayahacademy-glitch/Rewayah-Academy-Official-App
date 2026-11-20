// La lecture d'un fil des communications (revue COM-R, R-07 : une fonction,
// un endroit).
//
// Un seul adaptateur de `MessageCommunication` (le modele du socle) vers
// `MessageFil` (la bulle de `FilDiscussion`) : texte, ligne des pieces,
// horodatage. Les Messages metier (`FilContextuel`) et les canaux du Studio
// (`CanalStudio`) le lisent tous deux, en ecriture comme en lecture seule ;
// aucun ne recompose son texte ni sa date.

import 'package:flutter/widgets.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/dates_appareil.dart';
import '../i18n/strings.g.dart';
import '../tc_horloge/mon_horloge.dart';
import '../widgets/avatar_tile.dart' show AppAvatar;
import '../widgets/carte_piece_jointe.dart';
import '../widgets/fil_discussion.dart';
import 'image_praxis.dart';
import 'modeles_communication.dart';
import 'port_pieces_jointes.dart';

/// La ligne d'un vocal, par sa duree : « Message vocal de 0:28 ».
String ligneVocal(Duration duree) => t.com.socle.composants.lecture.vocal(
  duree: CartePieceJointe.libelleDuree(duree),
);

/// Le texte d'un message tel qu'il se lit dans un fil : son texte, puis une
/// ligne par piece jointe (« Piece jointe : Devoir.pdf ») ou vocal
/// (« Message vocal de 0:28 »). Jamais une reference ni une adresse.
///
/// Sans [avecVocaux], les vocaux ne sont pas dits ; sans [avecDocuments],
/// les autres pieces non plus : la bulle les montre alors par leur lecteur
/// et leur carte.
String texteDuMessage(
  MessageCommunication m, {
  bool avecVocaux = true,
  bool avecDocuments = true,
}) {
  final l = t.com.socle.composants.lecture;
  return <String>[
    if (m.texte.trim().isNotEmpty) m.texte.trim(),
    for (final PieceJointe p in m.piecesJointes)
      if (p.nature != NaturePieceJointe.vocal) ...<String>[
        if (avecDocuments) l.pieceJointe(nom: p.nom),
      ] else if (avecVocaux)
        switch (p.duree) {
          final Duration d => ligneVocal(d),
          null => l.vocalSansDuree,
        },
  ].join('\n');
}

/// La date et l'heure d'un message, a l'heure du profil ([chezMoi],
/// HEURES-PROFIL H1). Le jour reste
/// avec son mois : jamais « Dimanche 4 / octobre, 09:54 » dans une bulle a
/// 320 px en texte x2 (COM-RC tour 7, lot L).
String horodatageMessage(DateTime instant) {
  final DateTime local = chezMoi(instant);
  return t.com.socle.composants.lecture.horodatage(
    date: nombresLiesAuMotSuivant(dateDeLAppareil(local)),
    heure: heureDeLAppareil(local),
  );
}

/// La bulle d'un message du socle : l'auteur (« Vous » pour soi), le texte
/// sans ses pieces, le texte complet pour l'annonce, et [complement] (les
/// cartes et lecteurs des pieces, que l'ecran compose) sous le texte.
MessageFil messageFilDe(
  MessageCommunication m, {
  Widget? complement,
  bool suiviLecture = false,
  DateTime? luParAutresLe,
  String? idLocal,
}) => MessageFil(
  id: m.id,
  // PE-D1 : la bulle locale dont ce message est la copie confirmee (meme cle
  // d'envoi), et si le serveur a rendu cette cle.
  idLocal: idLocal,
  cleEnvoiConnue: m.cleIdempotence != null,
  // PX-BULLE-2 : le compte officiel (Praxis) porte son nom « #Ra_Praxis » meme
  // dans une bulle « de soi » cote administration, jamais « Vous ».
  auteur: m.deSoi && m.auteur.compteOfficiel != codeComptePraxis
      ? t.com.socle.composants.composer.auteurSoi
      : m.auteur.nomMarque,
  texte: texteDuMessage(m, avecVocaux: false, avecDocuments: false),
  annonceTexte: texteDuMessage(m),
  complement: complement,
  horodatage: horodatageMessage(m.envoyeLe),
  instant: m.envoyeLe,
  image: m.image,
  coeurs: m.coeurs,
  aimeParMoi: m.aimeParMoi,
  deSoi: m.deSoi,
  // PX-BULLE (directeur, 17/11/2026) : chaque bulle de Praxis porte son avatar
  // et son nom « #Ra_Praxis », meme dans une conversation a deux. Seul le code
  // serveur `praxis` (jamais un nom, jamais un autre compte officiel) ; aucune
  // bulle humaine n'est touchee.
  avatarAuteur: m.auteur.compteOfficiel == codeComptePraxis
      ? const ImagePraxis(diametre: AppAvatar.petit)
      : null,
  // MESSAGERIE-LU : avec [suiviLecture], un message de soi dit s'il est lu
  // par l'autre partie (lu au plus tard a [luParAutresLe]).
  remise: !suiviLecture || !m.deSoi
      ? null
      : luParAutresLe != null && !m.envoyeLe.isAfter(luParAutresLe)
      ? RemiseMessage.lu
      : RemiseMessage.envoye,
);
