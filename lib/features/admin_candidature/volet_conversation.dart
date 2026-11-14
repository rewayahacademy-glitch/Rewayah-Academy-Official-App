/// RECRUTEMENT-SANS-SORTIE (directeur, 14/11/2026) : la conversation avec la
/// personne s'ouvre DANS son dossier. « Ecrire a {nom} » ne fait plus quitter
/// le dossier : sur ordinateur, un volet de cote a droite (Material 3, « side
/// sheet » standard : le dossier reste lisible et utilisable a cote) ; au
/// telephone et a la tablette, une surface plein ecran qui se replie sur le
/// dossier, a la meme position. On ecrit, on replie, on continue.
///
/// Le fil est celui de la page Messages (`FilEnPlace` -> `FilContextuel`) :
/// temps reel, coches de lecture et envoi honnete ne sont pas recrees.
/// « Ouvrir dans Messages » reste en lien secondaire ; il empile la page
/// Messages, et son retour ramene au dossier.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/tete_panneau.dart';
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

  /// La cle de la croix qui replie le volet.
  static const Key cleReplier = ValueKey<String>('volet-conversation-replier');

  /// La cle du lien « Ouvrir dans Messages ».
  static const Key cleMessages = ValueKey<String>(
    'volet-conversation-messages',
  );

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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TetePanneau(
                  titre: e.conversationAvec(nom: conversation.nom),
                  icone: AppIcons.discussion,
                  cleFermer: cleReplier,
                  onFermer: onReplier,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LienFleche(
                    key: cleMessages,
                    libelle: e.ouvrirDansMessages,
                    alignerEnDebut: true,
                    onPress: () => unawaited(
                      GoRouter.of(context)
                          .push<void>(conversation.cheminMessages),
                    ),
                  ),
                ),
                Ecart.vSm,
                Expanded(
                  child: FilEnPlace(
                    key: ValueKey<String>('volet-${conversation.filId}'),
                    filId: conversation.filId,
                    onLu: onLu,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ouvre la conversation au telephone et a la tablette : une surface plein
/// ecran au-dessus du dossier, que « Replier la conversation » (le disque
/// retour, ou le retour du systeme) referme sur le dossier, a la meme
/// position.
Future<void> ouvrirFeuilleConversation(
  BuildContext context, {
  required ConversationEnPlace conversation,
  VoidCallback? onLu,
}) {
  final e = t.com.messages.entree;
  final GoRouter? routeur = GoRouter.maybeOf(context);
  return AppBottomSheet.ouvrirLecture<void>(
    context,
    titre: e.conversationAvec(nom: conversation.nom),
    libelleFermer: e.replier,
    constructeur: (BuildContext contexte) => Column(
      key: VoletConversation.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (routeur != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: VoletConversation.cleMessages,
              libelle: e.ouvrirDansMessages,
              alignerEnDebut: true,
              onPress: () {
                Navigator.of(contexte).pop();
                unawaited(routeur.push<void>(conversation.cheminMessages));
              },
            ),
          ),
        Ecart.vSm,
        Expanded(
          child: FilEnPlace(
            key: ValueKey<String>('feuille-${conversation.filId}'),
            filId: conversation.filId,
            onLu: onLu,
          ),
        ),
      ],
    ),
  );
}
