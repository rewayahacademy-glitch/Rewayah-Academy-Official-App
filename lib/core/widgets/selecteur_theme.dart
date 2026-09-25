import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../preferences/preferences_locales.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';
import 'pressable.dart';

/// Le seul selecteur de theme de l'application (lot T, decision du
/// directeur du 25/09 : « simplifier au maximum », icones soleil, lune,
/// systeme disposees verticalement).
///
/// Trois icones dans une pilule `surfaceRaised` a filet, dans cet ordre :
/// soleil (Clair), lune (Sombre), ecran (Selon le systeme). Il ecrit
/// `preferencesLocalesProvider`, lue par `RewayahApp` et persistee sur
/// l'appareil ; « Selon le systeme » est le choix par defaut. Il reflete le
/// **choix** (pas le theme affiche) : sous « Selon le systeme », c'est
/// l'ecran qui est actif.
///
/// Deux poses, un seul composant :
/// - [SelecteurTheme.new] : sur une carte standard, le choix courant a
///   gauche et la pilule verticale a droite (Compte > Preferences >
///   Apparence, Reglages des autres roles) ;
/// - [SelecteurTheme.entete] : la pilule seule, horizontale, a l'endroit
///   familier de l'en-tete (tablette et bureau ; c'est l'ecran qui decide
///   de la poser).
///
/// Chaque icone est une cible de 48, lue « Theme clair », « Theme sombre »
/// ou « Theme selon le systeme » et annoncee « selectionne » ; une bulle
/// donne le meme libelle au survol.
class SelecteurTheme extends ConsumerWidget {
  /// La pilule verticale sur une carte standard.
  const SelecteurTheme({super.key}) : _entete = false;

  /// La pilule seule, horizontale, pour l'en-tete.
  const SelecteurTheme.entete({super.key}) : _entete = true;

  final bool _entete;

  /// L'ordre des icones : soleil, lune, systeme.
  static const List<PreferenceTheme> ordre = <PreferenceTheme>[
    PreferenceTheme.clair,
    PreferenceTheme.sombre,
    PreferenceTheme.systeme,
  ];

  /// Le libelle lu et affiche d'un choix.
  static String libelle(PreferenceTheme theme) => switch (theme) {
    PreferenceTheme.clair => t.commun.theme.clair,
    PreferenceTheme.sombre => t.commun.theme.sombre,
    PreferenceTheme.systeme => t.commun.theme.systeme,
  };

  static AppIcon _icone(PreferenceTheme theme) => switch (theme) {
    PreferenceTheme.clair => AppIcons.themeClair,
    PreferenceTheme.sombre => AppIcons.themeSombre,
    PreferenceTheme.systeme => AppIcons.tabletteOuOrdinateur,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PreferenceTheme choix = ref.watch(
      preferencesLocalesProvider.select((PreferencesLocales p) => p.theme),
    );
    final Widget pilule = _Pilule(
      choix: choix,
      direction: _entete ? Axis.horizontal : Axis.vertical,
      onChoix: ref.read(preferencesLocalesProvider.notifier).theme,
    );
    if (_entete) {
      return pilule;
    }

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                libelle(choix),
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
          ),
          Ecart.hMd,
          pilule,
        ],
      ),
    );
  }
}

class _Pilule extends StatelessWidget {
  const _Pilule({
    required this.choix,
    required this.direction,
    required this.onChoix,
  });

  final PreferenceTheme choix;
  final Axis direction;
  final ValueChanged<PreferenceTheme> onChoix;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool sombre = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: t.commun.theme.groupe,
      child: DecoratedBox(
        decoration: palette.surfaceRaised.decoration(
          borderRadius: AppRadius.arrondiFull,
          side: palette.contourCarte.asBorderSide(),
        ),
        child: Flex(
          direction: direction,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final PreferenceTheme theme in SelecteurTheme.ordre)
              _Icone(
                icone: SelecteurTheme._icone(theme),
                libelle: SelecteurTheme.libelle(theme),
                actif: theme == choix,
                themeSombre: sombre,
                onPress: () => onChoix(theme),
              ),
          ],
        ),
      ),
    );
  }
}

class _Icone extends StatelessWidget {
  const _Icone({
    required this.icone,
    required this.libelle,
    required this.actif,
    required this.themeSombre,
    required this.onPress,
  });

  final AppIcon icone;
  final String libelle;
  final bool actif;
  final bool themeSombre;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Le role de l'accent s'echange d'un theme a l'autre (manifeste 6.2) :
    // pastille douce et icone d'accent en clair, accent plein et icone
    // sombre en sombre.
    final Color? fond = !actif
        ? null
        : themeSombre
        ? palette.surfacePrimary.background
        : palette.washAccent.background;
    final IconThemeData theme = !actif
        ? palette.inkMuted.asIconTheme(size: AppSpacing.xl)
        : themeSombre
        ? IconThemeData(
            color: palette.surfacePrimary.onBackground,
            size: AppSpacing.xl,
          )
        : palette.inkAccent.asIconTheme(size: AppSpacing.xl);

    // L'icone deja active reste un bouton actif (sinon elle serait annoncee
    // « desactivee ») ; la presser ne change rien.
    return Tooltip(
      message: libelle,
      excludeFromSemantics: true,
      child: Semantics(
        selected: actif,
        inMutuallyExclusiveGroup: true,
        child: Pressable(
          onPress: actif ? () {} : onPress,
          libelleSemantique: libelle,
          arrondiFocus: AppRadius.arrondiFull,
          child: ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppTouchTarget.standard,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fond,
                  ),
                  child: Center(
                    child: IconTheme(
                      data: theme,
                      child: Icon(actif ? icone.actif : icone.repos),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
