import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../icons/app_icons.dart';
import '../preferences/preferences_locales.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/controle_segmente.dart';
import 'strings.g.dart';

/// Le choix de la langue de l'application (lot 22 a, PREFERENCES-WEB) :
/// **un seul petit rectangle, trois bascules**, Systeme, Francais, العربية,
/// construit comme [SelecteurTheme] (THEME-SW-1) avec le meme
/// [ControleSegmente] : une phrase de contexte au-dessus, la ligne courte de
/// chaque option dessous, toutes visibles (K-58).
///
/// Il ecrit `preferencesLocalesProvider` ; `persistanceLangueProvider`
/// (monte par `RewayahApp`) applique la langue et la garde sur l'appareil.
/// Les noms des langues s'ecrivent chacun dans sa propre langue, pour qu'on
/// retrouve la sienne quelle que soit celle qui est affichee.
class SelecteurLangue extends ConsumerWidget {
  /// Cree le selecteur.
  const SelecteurLangue({super.key});

  /// La cle du segment d'une option, pour les tests.
  static Key segmentKey(PreferenceLangue option) =>
      ValueKey<String>('langue-app-${option.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final PreferenceLangue langue = ref.watch(
      preferencesLocalesProvider.select((PreferencesLocales p) => p.langue),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.commun.langue.contexte,
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: t.commun.langue.groupe,
          child: ControleSegmente<PreferenceLangue>(
            rectangle: true,
            valeur: langue,
            segments: <Segment<PreferenceLangue>>[
              for (final PreferenceLangue option in PreferenceLangue.values)
                Segment<PreferenceLangue>(
                  valeur: option,
                  libelle: _libelle(option),
                  icone: option == PreferenceLangue.systeme
                      ? AppIcons.tabletteOuOrdinateur
                      : null,
                ),
            ],
            onChange: ref.read(preferencesLocalesProvider.notifier).langue,
          ),
        ),
        Ecart.vSm,
        for (final PreferenceLangue option in PreferenceLangue.values)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: _LigneOption(option: option, choisie: option == langue),
          ),
      ],
    );
  }
}

String _libelle(PreferenceLangue option) => switch (option) {
  PreferenceLangue.systeme => t.commun.langue.systeme,
  PreferenceLangue.francais => t.commun.langue.francais,
  PreferenceLangue.arabe => t.commun.langue.arabe,
};

/// Une option avec sa ligne courte ; celle de l'option courante est a
/// l'encre forte.
class _LigneOption extends StatelessWidget {
  const _LigneOption({required this.option, required this.choisie});

  final PreferenceLangue option;
  final bool choisie;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final String detail = switch (option) {
      PreferenceLangue.systeme => t.commun.langue.systemeDetail,
      PreferenceLangue.francais => t.commun.langue.francaisDetail,
      PreferenceLangue.arabe => t.commun.langue.arabeDetail,
    };
    final TextStyle encre = (choisie ? palette.inkStrong : palette.inkMuted)
        .applyTo(base);
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: _libelle(option),
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

/// Le nom de la langue affichee en ce moment (« Français », « العربية ») :
/// pour les lignes qui disent la langue de l'interface sans la changer.
String nomLangueAffichee() => LocaleSettings.currentLocale == AppLocale.ar
    ? t.commun.langue.arabe
    : t.commun.langue.francais;
