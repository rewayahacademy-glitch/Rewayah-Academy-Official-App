import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Etat vide illustre.
///
/// Obligatoire des qu'une liste peut etre vide. Un etat vide est une
/// **invitation**, pas une excuse : « Aucun cours aujourd'hui, ton prochain
/// cours est jeudi », jamais « Aucune donnee »
/// (`docs/produit/parcours-utilisateurs.md`, regles communes).
///
/// D'ou l'API : [message] est obligatoire et [invitation] fortement attendue.
/// Un appel qui ne donne qu'un constat produit un ecran mort.
class EmptyState extends StatelessWidget {
  /// Cree un etat vide.
  const EmptyState({
    required this.message,
    super.key,
    this.invitation,
    this.icone,
    this.libelleAction,
    this.onAction,
  });

  /// Le constat, en une ligne courte.
  final String message;

  /// Ce que l'utilisateur peut faire ou attendre ensuite.
  final String? invitation;

  /// Icone d'illustration. Par defaut, un signe de bienvenue.
  final AppIcon? icone;

  /// Libelle du bouton d'action, quand une action a du sens.
  final String? libelleAction;

  /// L'action proposee.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair fond = palette.surfaceBase;
    final AppColorPair action = palette.surfacePrimary;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(metriques.marge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconTheme(
              data: palette.textOnLightAccent.asIconTheme(
                // Multiples de l'echelle, pas des valeurs ponctuelles.
                size: metriques.estEnfant
                    ? AppSpacing.xxxl * 3
                    : AppSpacing.xxxl * 2,
              ),
              child: Icon((icone ?? AppIcons.rienAAfficher).repos),
            ),
            Ecart.vXl,
            Text(
              message,
              textAlign: TextAlign.center,
              style: fond.applyTo(textes.titleLarge ?? const TextStyle()),
            ),
            if (invitation != null) ...<Widget>[
              Ecart.vSm,
              Text(
                invitation!,
                textAlign: TextAlign.center,
                style: fond.applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ],
            if (libelleAction != null && onAction != null) ...<Widget>[
              Ecart.vXxl,
              Pressable(
                onPress: onAction,
                libelleSemantique: libelleAction,
                respecterCibleTactile: false,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: metriques.cibleTactile,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: action.decoration(
                    borderRadius: BorderRadius.circular(metriques.rayon),
                  ),
                  child: Text(
                    libelleAction!,
                    style: action.applyTo(
                      textes.labelLarge ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
