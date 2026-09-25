// Le rail de l'enseignant, desktop (image CLV-06).
//
// Logo Rewayah Academy, puis Journee, Classes (active), Ressources, Profil :
// les entrees de la matrice. Ni « Foyer », ni « Seance en direct ». Quitter
// la salle par le rail passe par la meme confirmation que Quitter.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';
import '../tc_catalogue/routes_tc_b.dart';
import 'dock_seance.dart';

/// La largeur du rail (image : ≈ 232).
const double largeurRailSeance =
    AppSpacing.respiration * 3 + AppSpacing.section;

/// Le rail : rien si [onNaviguer] est nul.
class RailSeance extends StatelessWidget {
  const RailSeance({required this.onNaviguer, this.groupeId, super.key});

  final ValueChanged<String>? onNaviguer;

  /// La Classe de la seance ; sans elle, « Classes » reste affichee, active,
  /// sans lien.
  final String? groupeId;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<String>? naviguer = onNaviguer;
    if (naviguer == null) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final String? groupe = groupeId;
    VoidCallback sortirVers(String route) =>
        () => confirmerQuitterSeance(
          context,
          () => naviguer(route),
          cahier: true,
        );
    return Semantics(
      container: true,
      label: t.salle.seance.rail.navigation,
      child: DecoratedBox(
        key: const ValueKey<String>('rail-seance'),
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          border: BorderDirectional(end: palette.borderHairline.asBorderSide()),
        ),
        child: SizedBox(
          width: largeurRailSeance,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _Marque(),
                Ecart.vXxxl,
                _Entree(
                  icone: AppIcons.maison,
                  libelle: t.salle.seance.rail.journee,
                  onPress: sortirVers(Routes.enseignantJournee),
                ),
                Ecart.vSm,
                _Entree(
                  icone: AppIcons.classes,
                  libelle: t.salle.seance.rail.classes,
                  actif: true,
                  onPress: groupe == null
                      ? null
                      : sortirVers(Routes.groupePour(groupe)),
                ),
                Ecart.vSm,
                _Entree(
                  icone: AppIcons.livreOuvert,
                  libelle: t.salle.seance.rail.ressources,
                  onPress: sortirVers(RoutesTcB.bibliotheque),
                ),
                Ecart.vSm,
                _Entree(
                  icone: AppIcons.profil,
                  libelle: t.salle.seance.rail.profil,
                  onPress: sortirVers(Routes.enseignantProfil),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Marque extends StatelessWidget {
  const _Marque();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          IconTheme(
            data: palette.inkAccent.asIconTheme(size: AppSpacing.section),
            child: Icon(AppIcons.livreOuvert.repos),
          ),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  t.salle.seance.rail.marque,
                  maxLines: 1,
                  style: palette.inkStrong.applyTo(
                    theme.textTheme.titleMedium ?? const TextStyle(),
                  ),
                ),
                Text(
                  t.salle.seance.rail.sousMarque,
                  maxLines: 1,
                  style: palette.inkMuted.applyTo(
                    theme.textTheme.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Entree extends StatelessWidget {
  const _Entree({
    required this.icone,
    required this.libelle,
    required this.onPress,
    this.actif = false,
  });

  final AppIcon icone;
  final String libelle;
  final VoidCallback? onPress;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Widget ligne = DecoratedBox(
      decoration: actif
          ? palette.washAccent.decoration(
              borderRadius: AppRadius.arrondiMd,
              side: palette.inkAccent.asBorderSide(),
            )
          : const BoxDecoration(),
      child: SizedBox(
        height: AppSpacing.titreEcran + AppSpacing.sm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: <Widget>[
              IconTheme(
                data: (actif ? palette.inkAccent : palette.inkStrong)
                    .asIconTheme(size: AppSpacing.xxl),
                child: Icon(icone.resoudre(selectionne: actif)),
              ),
              Ecart.hLg,
              Expanded(
                child: Text(
                  libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (actif
                      ? palette.washAccent.applyTo
                      : palette.inkStrong.applyTo)(
                        Theme.of(context).textTheme.titleSmall ??
                            const TextStyle(),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final VoidCallback? action = onPress;
    return Semantics(
      selected: actif,
      child: action == null
          ? ligne
          : Pressable(
              onPress: action,
              libelleSemantique: libelle,
              arrondiFocus: AppRadius.arrondiMd,
              child: ligne,
            ),
    );
  }
}
