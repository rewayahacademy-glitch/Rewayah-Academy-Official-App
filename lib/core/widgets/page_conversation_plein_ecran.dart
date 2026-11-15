// La page d'une conversation ouverte (MESSAGERIE-PLEIN-ECRAN, directeur,
// 15/11/2026) : le contenu prend toute la hauteur, au-dessus du clavier
// (`resizeToAvoidBottomInset`), sans titre, sans onglets, sans barre globale.
// La seule zone qui defile est celle des messages : exception « messagerie »
// a `DECISION-DEFILEMENT-2026-11-01.md`
// (`docs/current/UX_REVIEW_MESSAGERIE-PLEIN-ECRAN.md`).

import 'package:flutter/material.dart';

/// La page d'une conversation ouverte, au telephone.
class PageConversationPleinEcran extends StatelessWidget {
  /// Cree la page autour de [child].
  const PageConversationPleinEcran({required this.child, super.key});

  /// La conversation (barre, fil, saisie).
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Scaffold(resizeToAvoidBottomInset: true, body: SafeArea(child: child));
}
