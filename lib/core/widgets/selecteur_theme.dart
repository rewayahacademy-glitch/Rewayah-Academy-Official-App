import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../preferences/preferences_locales.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'controle_segmente.dart';

/// Le choix du theme (Apparence), partage par toutes les pages qui le
/// proposent : **un seul petit rectangle, trois bascules cote a cote**, soleil
/// (clair), systeme, lune (sombre) (THEME-SW-1, demande repetee du directeur).
///
/// Il lit et ecrit la meme preference que la bascule de l'en-tete
/// (`preferencesLocalesProvider`) : un choix fait ailleurs se reflete ici.
/// L'ordre visuel suit le sens de lecture, il se miroite donc tout seul en
/// arabe. Au-dessus, une phrase de contexte ; dessous, la ligne de chacune des
/// trois options (quand la choisir, ce qui change), toutes visibles.
///
/// Une page qui propose le theme pose ce composant ; elle ne recompose jamais
/// trois cartes ou trois lignes radio (lib/CLAUDE.md, interdits d'interface).
class SelecteurTheme extends ConsumerWidget {
  /// Cree le selecteur.
  const SelecteurTheme({super.key});

  /// L'ordre des bascules et des lignes : clair, systeme, sombre.
  static const List<PreferenceTheme> _ordre = <PreferenceTheme>[
    PreferenceTheme.clair,
    PreferenceTheme.systeme,
    PreferenceTheme.sombre,
  ];

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
        Text(
          t.compte.themeContexte,
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
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
        for (final PreferenceTheme option in _ordre)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: _LigneOption(option: option, choisie: option == theme),
          ),
      ],
    );
  }
}

/// Une option avec sa ligne courte : quand la choisir, ce qui change. Les
/// trois lignes restent visibles pour qu'on lise chaque consequence avant de
/// choisir (K-58) ; celle de l'option courante est a l'encre forte.
class _LigneOption extends StatelessWidget {
  const _LigneOption({required this.option, required this.choisie});

  final PreferenceTheme option;
  final bool choisie;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final (String libelle, String detail) = switch (option) {
      PreferenceTheme.clair => (t.compte.themeClair, t.compte.themeClairDetail),
      PreferenceTheme.systeme => (
        t.compte.themeSysteme,
        t.compte.themeSystemeDetail,
      ),
      PreferenceTheme.sombre => (
        t.compte.themeSombre,
        t.compte.themeSombreDetail,
      ),
    };
    final TextStyle encre = (choisie ? palette.inkStrong : palette.inkMuted)
        .applyTo(base);
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: libelle,
            style: AppTypography.graisse(encre, FontWeight.w700),
          ),
          const TextSpan(text: ' : '),
          TextSpan(text: detail),
        ],
      ),
      style: encre,
    );
  }
}
