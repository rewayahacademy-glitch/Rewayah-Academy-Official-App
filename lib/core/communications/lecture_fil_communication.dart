// La lecture d'un fil des communications (revue COM-R, R-07 : une fonction,
// un endroit).
//
// Un seul adaptateur de `MessageCommunication` (le modele du socle) vers
// `MessageFil` (la bulle de `FilDiscussion`) : texte, ligne des pieces,
// horodatage. Les Messages metier (`FilContextuel`) et les canaux du Studio
// (`CanalStudio`) le lisent tous deux, en ecriture comme en lecture seule ;
// aucun ne recompose son texte ni sa date.

import 'package:flutter/widgets.dart';

import '../i18n/dates_appareil.dart';
import '../i18n/strings.g.dart';
import '../widgets/carte_piece_jointe.dart';
import '../widgets/fil_discussion.dart';
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

/// La date et l'heure d'un message, a l'heure de l'appareil.
String horodatageMessage(DateTime instant) {
  final DateTime local = instant.toLocal();
  return t.com.socle.composants.lecture.horodatage(
    date: dateDeLAppareil(local),
    heure: heureDeLAppareil(local),
  );
}

/// La bulle d'un message du socle : l'auteur (« Vous » pour soi), le texte
/// sans ses pieces, le texte complet pour l'annonce, et [complement] (les
/// cartes et lecteurs des pieces, que l'ecran compose) sous le texte.
MessageFil messageFilDe(MessageCommunication m, {Widget? complement}) =>
    MessageFil(
      id: m.id,
      auteur: m.deSoi
          ? t.com.socle.composants.composer.auteurSoi
          : m.auteur.nomAffiche,
      texte: texteDuMessage(m, avecVocaux: false, avecDocuments: false),
      annonceTexte: texteDuMessage(m),
      complement: complement,
      horodatage: horodatageMessage(m.envoyeLe),
      deSoi: m.deSoi,
    );
