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
/// arabe. Dessous, une seule ligne courte ; les trois definitions des options
/// sont retirees (garde-cap, 11/11/2026 : les libelles et icones suffisent).
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
          t.compte.themeContexte,
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}
