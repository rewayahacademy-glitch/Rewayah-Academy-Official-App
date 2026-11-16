/// RECRUTEMENT-SANS-SORTIE (directeur, 14/11/2026) : la conversation avec la
/// personne s'ouvre DANS son dossier. « Ecrire a {nom} » ne fait plus quitter
/// le dossier : sur ordinateur, un volet de cote a droite (Material 3, « side
/// sheet » standard : le dossier reste lisible et utilisable a cote) ; au
/// telephone et a la tablette, une surface plein ecran qui se replie sur le
/// dossier, a la meme position. On ecrit, on replie, on continue.
///
/// Le fil est celui de la page Messages (`FilEnPlace` -> `FilContextuel`) :
/// temps reel, coches de lecture et envoi honnete ne sont pas recrees.
///
/// CONVERSATIONS-PARTOUT (directeur, 16/11/2026) : ni titre, ni lien, ni bloc
/// d'identite de plus au-dessus du fil. La conversation a la mise en page de la
/// messagerie refaite : la barre compacte (`BarreConversation` : retour ou
/// croix, avatar a cote du nom, « Ouvrir dans Messages » en bouton d'icone), le
/// fil pleine page, ses marges. Aucune variante locale : tout vient de
/// `FilEnPlace`. « Ouvrir dans Messages » empile la page Messages, et son
/// retour ramene au dossier.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/espace_travail_adaptatif.dart';
import '../../core/widgets/page_conversation_plein_ecran.dart';
import '../com_messages/barre_conversation.dart';
import '../com_messages/entree_messages_contexte.dart';
import '../com_messages/fil_en_place.dart';

/// Le volet de cote de la conversation, sur ordinateur.
class VoletConversation extends StatelessWidget {
  /// Cree le volet.
  const VoletConversation({
    required this.conversation,
    required this.onReplier,
    super.key,
    this.onLu,
  });

  /// La conversation ouverte.
  final ConversationEnPlace conversation;

  /// Replie le volet : le dossier reprend toute la largeur.
  final VoidCallback onReplier;

  /// Le fil vient d'etre marque lu (la page relit ses badges).
  final VoidCallback? onLu;

  /// La cle du volet.
  static const Key cle = ValueKey<String>('volet-conversation');

  /// La cle du bouton qui replie le volet : celui de la barre de la
  /// conversation, le meme que celui de la page Messages.
  static const Key cleReplier = EspaceTravailAdaptatif.cleRetourListe;

  /// La cle du bouton « Ouvrir dans Messages » de la barre.
  static const Key cleMessages = BarreConversation.cleOuvrirMessages;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final e = t.com.messages.entree;
    return Semantics(
      key: cle,
      container: true,
      explicitChildNodes: true,
      label: e.conversationAvec(nom: conversation.nom),
      // Le volet vit a cote de la page (hors de son Scaffold) : le champ du
      // fil demande une surface Material au-dessus de lui.
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surfaceRaised.background,
            border: BorderDirectional(
              start: palette.borderHairline.asBorderSide(),
            ),
          ),
          child: FilEnPlace(
            key: ValueKey<String>('volet-${conversation.filId}'),
            filId: conversation.filId,
            onLu: onLu,
            onReplier: onReplier,
            iconeReplier: AppIcons.fermer,
            onOuvrirMessages: () => unawaited(
              GoRouter.of(context).push<void>(conversation.cheminMessages),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ouvre la conversation au telephone et a la tablette : une page plein ecran
/// au-dessus du dossier (la meme que la conversation de la page Messages :
/// barre compacte, fil, saisie), que « Replier la conversation » (le retour de
/// la barre, ou le retour du systeme) referme sur le dossier, a la meme
/// position. L'adresse du dossier ne change pas.
Future<void> ouvrirFeuilleConversation(
  BuildContext context, {
  required ConversationEnPlace conversation,
  VoidCallback? onLu,
}) {
  final GoRouter? routeur = GoRouter.maybeOf(context);
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext contexte) => PageConversationPleinEcran(
        child: Semantics(
          key: VoletConversation.cle,
          container: true,
          explicitChildNodes: true,
          label: t.com.messages.entree.conversationAvec(nom: conversation.nom),
          child: FilEnPlace(
            key: ValueKey<String>('feuille-${conversation.filId}'),
            filId: conversation.filId,
            onLu: onLu,
            onReplier: () => Navigator.of(contexte).pop(),
            onOuvrirMessages: routeur == null
                ? null
                : () {
                    Navigator.of(contexte).pop();
                    unawaited(routeur.push<void>(conversation.cheminMessages));
                  },
          ),
        ),
      ),
    ),
  );
}
