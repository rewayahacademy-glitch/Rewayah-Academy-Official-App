// SALLE-3-ACCUEIL (plan des trois salles, accepte par le directeur le
// 07/11/2026) : la carte « Bienvenue dans l'equipe » de l'espace enseignant
// qui n'a pas encore de Classe. En tete, ce qui reste a configurer, puis le
// rappel des remplacements.
//
// **Une seule liste** : celle de « Premiers pas » (`listeAConfigurerProvider`,
// `reste_a_configurer.dart`) : versement, photo, langues, fuseau,
// disponibilites. Rien n'est calcule ici (E6) ; une lecture absente n'affiche
// pas sa ligne ; une ligne faite disparait. Tant qu'un element n'est pas lu, la
// carte ne dit jamais « tout est configure ».
//
// Le rappel des remplacements ne promet que ce que l'ecran fait : l'offre
// s'affiche sur la page Journee. La notification sur l'appareil (PUSH-1) viendra
// avec son propre texte.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import 'reste_a_configurer.dart';

/// La carte « Bienvenue dans l'equipe ».
class CarteBienvenueEquipe extends ConsumerWidget {
  /// Cree la carte.
  const CarteBienvenueEquipe({super.key});

  /// La cle de la carte.
  static const Key cle = ValueKey<String>('carte-bienvenue-equipe');

  /// La cle de la ligne d'un reste a configurer.
  static Key cleLigne(ResteAConfigurer r) =>
      ValueKey<String>('bienvenue-equipe-${r.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final r = t.enseignant.bienvenue.equipe;
    final ListeAConfigurer liste = ref.watch(listeAConfigurerProvider);
    final List<ResteAConfigurer> restes = liste.restes;
    final String prenom =
        ref.watch(profilEnseignantProvider).value?.prenom.trim() ?? '';

    return AppCard(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(
              r.titre,
              style: palette.inkStrong.applyTo(
                textes.titleLarge ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          // Tant qu'un element n'est pas lu, jamais « tout est configure ».
          if (restes.isNotEmpty || liste.complete)
            TexteSansCoupure(
              restes.isEmpty ? r.toutPret : r.intro,
              style: doux,
            ),
          if (restes.isNotEmpty) ...<Widget>[
            Ecart.vLg,
            Semantics(
              header: true,
              child: TexteSansCoupure(
                r.aConfigurer,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            for (final ResteAConfigurer reste in restes)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: LienFleche(
                  key: cleLigne(reste),
                  libelle: libelleReste(reste),
                  onPress: () => allerVersReste(context, reste, prenom: prenom),
                ),
              ),
          ],
          Ecart.vLg,
          Semantics(
            header: true,
            child: TexteSansCoupure(
              r.remplacementTitre,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
          TexteSansCoupure(r.remplacement, style: doux),
        ],
      ),
    );
  }
}
