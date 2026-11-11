import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'groupe_reglages.dart';
import 'selecteur_theme.dart';

/// Les preferences du Compte, posees sur la page elle-meme, sans engrenage
/// ni page « Reglages » a ouvrir (PROFILS P1, pilote du 11/11/2026).
///
/// Le theme en choix en ligne ([SelecteurTheme], le seul choix du theme de
/// l'application, THEME-SW-1), puis, dans cet ordre et seulement quand
/// l'ecran les fournit : Langue, Notifications, Accessibilite. **Une seule
/// langue**, celle du compte, qui sert a l'interface ET aux e-mails (garde-cap,
/// 11/11/2026) : aucune ligne « Langue des e-mails ». Une ligne qui ne marche
/// pas n'est pas fournie (« 100 % operationnel », directeur, 11/11/2026) :
/// aucun etat « Non disponible ». L'ecran du role decide de chaque ligne
/// selon une capacite, jamais selon un role ; ce composant ne fait que les
/// ranger.
class GroupePreferences extends StatelessWidget {
  /// Cree les preferences.
  const GroupePreferences({
    super.key,
    this.langue,
    this.notifications,
    this.accessibilite,
  });

  /// « Langue » : la langue du compte, pour l'interface et les e-mails.
  final LigneRubrique? langue;

  /// « Notifications ».
  final LigneRubrique? notifications;

  /// « Accessibilité ».
  final LigneRubrique? accessibilite;

  /// Les lignes fournies, dans l'ordre fixe.
  List<LigneRubrique> get lignes => <LigneRubrique>[
    ?langue,
    ?notifications,
    ?accessibilite,
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
