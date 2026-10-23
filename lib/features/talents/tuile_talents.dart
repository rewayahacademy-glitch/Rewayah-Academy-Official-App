// La tuile du portail `/attente` : « Vos autres talents » (`CAND-07`), sous la
// tuile de partage.
//
// Sobre : une carte entiere qui se touche et mene a la page. **Pas de bouton
// plein** : le portail garde une seule action pleine, celle de l'etat de la
// candidature. Un titre, une ligne : facultatif et sans effet sur la
// candidature d'enseignant tant que la personne n'a pas repondu ; ses reponses
// sont enregistrees ensuite.
//
// **La tuile ne se rend que si le serveur dit que c'est ouvert** (apres l'envoi
// de la candidature, tant qu'elle est en cours) **ou que la personne a des
// reponses a relire ou a retirer** (candidature terminee). Pendant la lecture,
// en cas d'echec, sans lot serveur ou pour un compte qui n'est pas celui d'un
// candidat, elle n'est pas rendue : le portail n'affiche jamais une entree qui
// ne mene nulle part.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/port_autres_competences.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';

/// La tuile du portail.
class TuileTalents extends ConsumerWidget {
  /// Cree la tuile.
  const TuileTalents({super.key});

  /// La cle de la tuile.
  static const Key tuileKey = ValueKey<String>('portail-talents');

  /// La cle du titre.
  static const Key titreKey = ValueKey<String>('portail-talents-titre');

  /// La cle de la ligne qui suit le titre.
  static const Key texteKey = ValueKey<String>('portail-talents-texte');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AutresCompetences? lecture = ref
        .watch(autresCompetencesProvider)
        .value;
    if (lecture == null || !(lecture.ouvert || lecture.aDesReponses)) {
      return const SizedBox.shrink();
    }
    final r = t.recrutement.talents;
    final String texte = !lecture.aDesReponses
        ? r.tuile.facultatif
        : lecture.ouvert
        ? r.tuile.enregistre
        : r.tuile.enregistreClose;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Padding(
      key: tuileKey,
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: AppCard(
        lien: true,
        libelleSemantique: '${r.titre}. $texte',
        onPress: () => GoRouter.maybeOf(context)?.go(Routes.attenteTalents),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconTheme(
              data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
              child: Icon(AppIcons.etoile.repos),
            ),
            Ecart.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TexteSansCoupure(
                    r.titre,
                    key: titreKey,
                    style: palette.inkStrong.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vSm,
                  TexteSansCoupure(
                    texte,
                    key: texteKey,
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
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
