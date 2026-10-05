import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../preferences/preferences_locales.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// La bascule clair / sombre de l'en-tete (maquette V2 ; decisions du
/// coordinateur section 3.5 ; manifeste visuel section 3.4).
///
/// **Elle pilote la meme preference que la page Apparence** (Systeme, Clair,
/// Sombre) : `preferencesLocalesProvider`, appliquee par `RewayahApp` et
/// persistee sur l'appareil (phase 0b). Elle reflete le theme **affiche** :
/// sous « Systeme », le segment actif est celui que le systeme a choisi ;
/// presser l'autre segment quitte « Systeme » pour un choix explicite, que la
/// page Apparence permet de defaire.
///
/// Deux segments soleil et lune dans une pilule `surfaceRaised` a filet ;
/// segment actif `washAccent` et icone d'accent en clair, accent plein et
/// icone sombre en sombre. Chaque segment est une cible de 48, lue « Theme
/// clair » ou « Theme sombre » et annoncee « selectionne ».
///
/// Affichee a partir de la tablette ; sur telephone, le choix est dans
/// Compte > Preferences > Apparence (manifeste section 4.2) : c'est l'ecran
/// qui decide de la poser, pas le composant.
class BasculeTheme extends ConsumerWidget {
  /// Cree la bascule.
  const BasculeTheme({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final bool sombre = Theme.of(context).brightness == Brightness.dark;
    final PreferencesLocalesControleur controleur = ref.read(
      preferencesLocalesProvider.notifier,
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: t.commun.theme.groupe,
      child: DecoratedBox(
        decoration: palette.surfaceRaised.decoration(
          borderRadius: AppRadius.arrondiFull,
          side: palette.contourCarte.asBorderSide(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Segment(
              icone: AppIcons.themeClair,
              libelle: t.commun.theme.clair,
              actif: !sombre,
              themeSombre: sombre,
              onPress: () => controleur.theme(PreferenceTheme.clair),
            ),
            _Segment(
              icone: AppIcons.themeSombre,
              libelle: t.commun.theme.sombre,
              actif: sombre,
              themeSombre: sombre,
              onPress: () => controleur.theme(PreferenceTheme.sombre),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
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

    // Le segment deja actif reste un bouton actif (sinon il serait annonce
    // « desactive ») ; le presser ne change rien.
    return Semantics(
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
                decoration: BoxDecoration(shape: BoxShape.circle, color: fond),
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
    );
  }
}
