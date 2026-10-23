import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../widgets/empty_state.dart';
import '../widgets/offline_banner.dart';

/// Feuille de route temporaire.
///
/// L'etape 2 pose l'arborescence, pas les ecrans metier : ceux-ci arrivent a
/// l'etape 3 et suivantes, chacun a partir de sa fiche dans
/// `docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`.
///
/// Ce widget n'est pas un ecran vide : il nomme la destination, pour qu'une
/// navigation de test dise ou elle a mene.
class EcranAConstruire extends StatelessWidget {
  /// Cree le placeholder d'une destination.
  const EcranAConstruire({required this.destination, super.key});

  /// Le nom lisible de la destination.
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(destination)),
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Expanded(
            child: EmptyState(
              message: t.aConstruire.titre,
              invitation: t.aConstruire.detail,
            ),
          ),
        ],
      ),
    );
  }
}
