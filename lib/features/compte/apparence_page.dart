import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/selecteur_theme.dart';
import 'carte_rubriques.dart';

/// L'apparence de l'application sur cet appareil
/// (`/tuteur/compte/preferences/apparence`, maquette V4, ecran 02).
///
/// Le theme ecrit **la meme preference** que la bascule soleil / lune de
/// l'en-tete (`preferencesLocalesProvider`), lue par `RewayahApp` : le choix
/// s'applique tout de suite et se garde sur l'appareil.
///
/// « Confort visuel » ne rend **aucun interrupteur** : rien ne lit encore la
/// reduction des animations ou des effets choisie ici (C08 section 2.3), et un
/// interrupteur sans effet ne se rend pas. Les deux lignes disent ce qui est
/// vrai : animations et taille du texte suivent l'appareil.
class ApparenceComptePage extends ConsumerWidget {
  /// Cree la page.
  const ApparenceComptePage({super.key, this.onRetour});

  /// Le retour de l'en-tete ; par defaut, les Preferences du tuteur. « Mon
  /// espace » de l'eleve adulte (EA-4) y passe son propre retour.
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return PageShell(
      titre: t.compte.tuteur.pageApparence.titre,
      sousTitre: t.compte.tuteur.pageApparence.sousTitre,
      onRetour:
          onRetour ??
          () => GoRouter.of(context).go(Routes.tuteurComptePreferences),
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                t.compte.tuteur.pageApparence.theme,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
            const SelecteurTheme(),
            Ecart.vXl,
            GroupeReglages(
              titre: t.compte.tuteur.pageApparence.confort,
              lignes: <LigneRubrique>[
                LigneRubrique(
                  icone: AppIcons.reconnexion,
                  libelle: t.compte.tuteur.pageApparence.animations,
                  legende: t.compte.tuteur.pageApparence.animationsDetail,
                ),
                LigneRubrique(
                  icone: AppIcons.texteStructure,
                  libelle: t.compte.tuteur.pageApparence.texte,
                  legende: t.compte.tuteur.pageApparence.texteDetail,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
