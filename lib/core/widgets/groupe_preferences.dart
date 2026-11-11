import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'groupe_reglages.dart';
import 'selecteur_theme.dart';

/// Les preferences du Compte, posees sur la page elle-meme, sans engrenage
/// ni page « Reglages » a ouvrir (PROFILS P1, pilote du 11/11/2026).
///
/// Le theme en choix en ligne ([SelecteurTheme], le seul choix du theme de
/// l'application, THEME-SW-1), puis, dans cet ordre et seulement quand
/// l'ecran les fournit : Langue de l'application, Notifications,
/// Accessibilite, Langue des e-mails. L'ecran du role decide de chaque ligne
/// selon une capacite, jamais selon un role ; ce composant ne fait que les
/// ranger.
class GroupePreferences extends StatelessWidget {
  /// Cree les preferences.
  const GroupePreferences({
    super.key,
    this.langueApplication,
    this.notifications,
    this.accessibilite,
    this.langueCourriels,
  });

  /// « Langue de l'application ».
  final LigneRubrique? langueApplication;

  /// « Notifications ».
  final LigneRubrique? notifications;

  /// « Accessibilité ».
  final LigneRubrique? accessibilite;

  /// « Langue des e-mails et des messages ».
  final LigneRubrique? langueCourriels;

  /// Les lignes fournies, dans l'ordre fixe.
  List<LigneRubrique> get lignes => <LigneRubrique>[
    ?langueApplication,
    ?notifications,
    ?accessibilite,
    ?langueCourriels,
  ];

  @override
  Widget build(BuildContext context) {
    final List<LigneRubrique> fournies = lignes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SelecteurTheme(),
        if (fournies.isNotEmpty) ...<Widget>[
          Ecart.vLg,
          GroupeReglages(lignes: fournies),
        ],
      ],
    );
  }
}
