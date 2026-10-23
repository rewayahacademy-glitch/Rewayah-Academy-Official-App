// La tuile du portail `/attente` : « Aidez une personne a apprendre la parole
// d'Allah. » (« une sœur » pour une femme), CAND-06.
//
// Une carte entiere qui se touche et mene a la page de partage. **Pas de
// bouton plein** : le portail garde une seule action pleine, celle de l'etat de
// la candidature.
//
// **Tres peu de mots** (directeur, 22/10/2026 : « la fierte de participer a un
// geste noble et la simplicite ») : l'invitation, puis la mention
// « Facultatif ». Ni explication, ni hadith, ni description de l'offre : la
// page et la carte les portent. **Elle parle de la personne qui apprendra,
// jamais de l'academie.** Le mot suit le genre du profil (« une sœur » pour une
// femme, « une personne » sinon), lu comme la carte, jamais devine.
//
// Sans lien d'offre (aucune adresse de site connue), la tuile n'est pas rendue :
// elle mene a une carte qui ne pourrait pas exister.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/partage_offre/lien_offre.dart';
import '../../core/partage_offre/personnalisation_carte.dart';
import '../../core/partage_offre/port_genre_partageur.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';

/// La tuile du portail.
class TuilePartageOffre extends ConsumerWidget {
  /// Cree la tuile.
  const TuilePartageOffre({super.key});

  /// La cle de la tuile.
  static const Key tuileKey = ValueKey<String>('portail-partage');

  /// La cle de l'invitation.
  static const Key titreKey = ValueKey<String>('portail-partage-titre');

  /// La cle de la mention « Facultatif ».
  static const Key facultatifKey = ValueKey<String>(
    'portail-partage-facultatif',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(lienOffreProvider) == null) {
      return const SizedBox.shrink();
    }
    final c = t.recrutement.partage;
    // Le genre se lit sur le profil ; tant qu'il ne l'est pas, ou s'il ne se lit
    // pas, l'invitation est la neutre.
    final String invitation = invitationPartage(
      VarianteCarte.depuisGenre(ref.watch(genrePartageurProvider).value),
    );
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    return Padding(
      key: tuileKey,
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: AppCard(
        lien: true,
        libelleSemantique: '$invitation ${c.facultatif}',
        onPress: () => GoRouter.maybeOf(context)?.go(Routes.attentePartage),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconTheme(
              data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
              child: Icon(AppIcons.partager.repos),
            ),
            Ecart.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TexteSansCoupure(
                    invitation,
                    key: titreKey,
                    style: palette.inkStrong.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vSm,
                  TexteSansCoupure(
                    c.facultatif,
                    key: facultatifKey,
                    style: muet,
                  ),
                ],
              ),
            ),
            Ecart.hSm,
            ExcludeSemantics(
              child: IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.chevron.repos),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
