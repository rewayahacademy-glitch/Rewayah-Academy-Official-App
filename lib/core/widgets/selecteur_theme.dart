import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../preferences/preferences_locales.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'controle_segmente.dart';

/// Le choix du theme (Apparence), partage par toutes les pages qui le
/// proposent : **un seul petit rectangle, trois bascules cote a cote**, soleil
/// (clair), systeme, lune (sombre) (THEME-SW-1, demande repetee du directeur).
///
/// Il lit et ecrit la meme preference que la bascule de l'en-tete
/// (`preferencesLocalesProvider`) : un choix fait ailleurs se reflete ici.
/// L'ordre visuel suit le sens de lecture, il se miroite donc tout seul en
/// arabe. Sous le rectangle, une phrase dit ce que l'option choisie fait.
///
/// Une page qui propose le theme pose ce composant ; elle ne recompose jamais
/// trois cartes ou trois lignes radio (lib/CLAUDE.md, interdits d'interface).
class SelecteurTheme extends ConsumerWidget {
  /// Cree le selecteur.
  const SelecteurTheme({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final PreferenceTheme theme = ref.watch(
      preferencesLocalesProvider.select((PreferencesLocales p) => p.theme),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: t.commun.theme.groupe,
          child: ControleSegmente<PreferenceTheme>(
            rectangle: true,
            valeur: theme,
            segments: <Segment<PreferenceTheme>>[
              Segment<PreferenceTheme>(
                valeur: PreferenceTheme.clair,
                libelle: t.compte.themeClair,
                icone: AppIcons.themeClair,
              ),
              Segment<PreferenceTheme>(
                valeur: PreferenceTheme.systeme,
                libelle: t.compte.themeSysteme,
                icone: AppIcons.tabletteOuOrdinateur,
              ),
              Segment<PreferenceTheme>(
                valeur: PreferenceTheme.sombre,
                libelle: t.compte.themeSombre,
                icone: AppIcons.themeSombre,
              ),
            ],
            onChange: ref.read(preferencesLocalesProvider.notifier).theme,
          ),
        ),
        Ecart.vSm,
        Text(
          _legende(theme),
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }

  static String _legende(PreferenceTheme theme) => switch (theme) {
    PreferenceTheme.clair => t.compte.themeClairDetail,
    PreferenceTheme.systeme => t.compte.themeSystemeDetail,
    PreferenceTheme.sombre => t.compte.themeSombreDetail,
  };
}
