// Un fil de conversation qui n'est pas un fil de Messages metier : les echanges
// du controleur sur une mission (CONVERSATIONS-PARTOUT, directeur,
// 16/11/2026). Il pose la meme barre compacte (`BarreConversation.libre`) et le
// meme fil plein ecran (`FilDiscussion`, marges, fond, saisie fixe en bas) que
// Messages ; la page qui l'emploie n'a plus a poser ni l'un ni l'autre.
//
// Sans barre ([avecBarre] faux : tablette et ordinateur, ou la page garde son
// titre et son contexte epingle), c'est le fil non plein ecran d'avant.

import 'package:flutter/material.dart';

import '../../core/widgets/fil_discussion.dart';
import 'barre_conversation.dart';

/// Le fil d'une conversation libre, avec ou sans sa barre.
class FilLibre extends StatelessWidget {
  /// Cree le fil.
  const FilLibre({
    required this.titre,
    required this.messages,
    required this.textes,
    required this.onEnvoyer,
    super.key,
    this.cleFil,
    this.ligne,
    this.onRetour,
    this.avecBarre = true,
  });

  /// La cle du fil (un fil par mission : un autre fil ne reprend pas le champ).
  final Key? cleFil;

  /// Le titre de la barre (la mission, la classe).
  final String titre;

  /// La ligne fine sous le titre, ou `null`.
  final String? ligne;

  /// Le retour vers la liste des conversations.
  final VoidCallback? onRetour;

  /// Vrai : la barre compacte et le fil plein ecran (telephone). Faux : le
  /// fil seul, la page porte son titre.
  final bool avecBarre;

  /// Les messages.
  final List<MessageFil> messages;

  /// Les textes du fil.
  final TextesFilDiscussion textes;

  /// L'envoi : le futur se termine sur l'accuse du serveur, et echoue sinon.
  final Future<void> Function(String texte) onEnvoyer;

  @override
  Widget build(BuildContext context) {
    final Widget fil = FilDiscussion(
      key: cleFil,
      pleinEcran: avecBarre,
      messages: messages,
      textes: textes,
      onEnvoyer: onEnvoyer,
    );
    if (!avecBarre) return fil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BarreConversation.libre(titre: titre, ligne: ligne, onRetour: onRetour),
        Expanded(child: fil),
      ],
    );
  }
}
