import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/selecteur_theme.dart';
import 'carte_rubriques.dart';

/// L'apparence de l'application sur cet appareil
/// (`/tuteur/compte/preferences/apparence`, maquette V4, ecran 02).
///
/// Le theme se choisit avec [SelecteurTheme], le meme composant que
/// l'en-tete (`preferencesLocalesProvider`, lue par `RewayahApp`) : le choix
/// s'applique tout de suite et se garde sur l'appareil.
///
/// « Confort visuel » ne rend **aucun interrupteur** : rien ne lit encore la
/// reduction des animations ou des effets choisie ici (C08 section 2.3), et un
/// interrupteur sans effet ne se rend pas. Les deux lignes disent ce qui est
/// vrai : animations et taille du texte suivent l'appareil.
class ApparenceComptePage extends ConsumerWidget {
  /// Cree la page.
  const ApparenceComptePage({super.key});

  /// La carte « Depliee » du choix de la barre laterale (bureau).
  static const Key barreDeplieeKey = Key('apparence.barre.depliee');

  /// La carte « Repliee » du choix de la barre laterale (bureau).
  static const Key barreReplieeKey = Key('apparence.barre.repliee');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Sur ordinateur, le theme se choisit deja dans l'en-tete : la page porte
    // a sa place un reglage propre au grand ecran, la barre laterale
    // (directeur, 26/09 : ne pas recopier le telephone).
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final String titreBloc = bureau
        ? t.compte.tuteur.pageApparence.barre
        : t.compte.tuteur.pageApparence.theme;
    final String detailBloc = bureau
        ? t.compte.tuteur.pageApparence.barreDetail
        : t.compte.tuteur.pageApparence.themeDetail;
    final bool repliee = ref.watch(navigationReplieeProvider) ?? false;

    return PageShell(
      titre: t.compte.tuteur.pageApparence.titre,
      sousTitre: t.compte.tuteur.pageApparence.sousTitre,
      onRetour: () => GoRouter.of(context).go(Routes.tuteurComptePreferences),
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                titreBloc,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vXs,
            Text(
              detailBloc,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vMd,
            if (bureau)
              ChoiceCardGroup(
                // Reconstruit quand le bouton de repli de la barre change le
                // choix ailleurs.
                key: ValueKey<bool>(repliee),
                coteACote: true,
                autoriserSaisieLibre: false,
                valeurInitiale: ReponseChoix(
                  valeurs: <String>{repliee ? 'repliee' : 'depliee'},
                ),
                options: <OptionChoix>[
                  OptionChoix(
                    cle: barreDeplieeKey,
                    valeur: 'depliee',
                    libelle: t.compte.tuteur.pageApparence.barreDepliee,
                    description:
                        t.compte.tuteur.pageApparence.barreDeplieeDetail,
                  ),
                  OptionChoix(
                    cle: barreReplieeKey,
                    valeur: 'repliee',
                    libelle: t.compte.tuteur.pageApparence.barreRepliee,
                    description:
                        t.compte.tuteur.pageApparence.barreReplieeDetail,
                  ),
                ],
                onChange: (ReponseChoix r) {
                  if (r.valeurs.isEmpty) {
                    return;
                  }
                  ref
                      .read(navigationReplieeProvider.notifier)
                      .choisir(repliee: r.valeurs.contains('repliee'));
                },
              )
            else
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
