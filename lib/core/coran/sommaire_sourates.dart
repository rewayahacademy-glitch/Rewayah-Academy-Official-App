// SOMMAIRE-SOURATES (directeur, 11/11/2026 : « on ne retrouve une sourate que
// par le numero de page ; la table des sourates manque, alors qu'elle est
// standard depuis 14 siecles »).
//
// LA table des sourates, une seule pour toute l'application : de 1, Al-Fatiha,
// a 114, An-Nas, dans l'ordre du mushaf. Chaque ligne porte le numero d'ordre,
// le nom ARABE (lu du corpus, jamais recopie), le nom translittere du corpus,
// et la page ou la sourate commence dans le Mushaf de Medine.
//
// Deux lecteurs l'emploient : la feuille « Aller a » du lecteur de l'eleve
// (`navigation_coran_feuille.dart`) et la bibliotheque de la salle
// (`panneau_enseignant.dart`). Elle ne defile pas elle-meme : c'est la surface
// qui la porte qui defile (DECISION-DEFILEMENT-2026-11-01 : une seule barre de
// defilement, jamais un cadre de hauteur fixe).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';
import '../widgets/pressable.dart';
import '../widgets/skeleton.dart';
import 'pages_depart_sourates.dart';
import 'service_coran.dart';

/// La table des 114 sourates.
class SommaireSourates extends ConsumerWidget {
  /// Cree la table.
  const SommaireSourates({
    required this.onChoisir,
    required this.libelleSemantique,
    super.key,
    this.invitationIndisponible,
  });

  /// Appele au toucher d'une sourate, avec la page ou elle commence.
  final void Function(Sourate sourate, int page) onChoisir;

  /// Ce que le lecteur d'ecran dit d'une ligne : l'ACTE, qui depend de
  /// l'endroit (« Aller a la sourate ... », « Presenter le debut de ... »).
  final String Function(Sourate sourate, int page) libelleSemantique;

  /// La phrase sous « La liste des sourates n'a pas pu etre lue », quand
  /// l'endroit a mieux a dire que la phrase commune (la salle : « Ce que
  /// votre classe voit n'a pas change. »).
  final String? invitationIndisponible;

  /// La cle de la ligne de la sourate [numero] (tests).
  static Key cleLigne(int numero) =>
      ValueKey<String>('sommaire-sourate-$numero');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Sourate>?> sourates = ref.watch(souratesProvider);
    final List<Sourate>? liste = sourates.value;

    if (liste == null) {
      return sourates.isLoading
          ? const Skeleton.liste(lignes: 6)
          : EmptyState(
              message: t.tc.coran.sommaire.indisponible,
              invitation:
                  invitationIndisponible ??
                  t.tc.coran.sommaire.indisponibleDetail,
              icone: AppIcons.horsLigne,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(souratesProvider),
            );
    }
    if (liste.isEmpty) {
      return EmptyState(
        message: t.tc.coran.sommaire.absent,
        invitation: t.tc.coran.sommaire.absentDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }

    // L'ordre du mushaf, quel que soit l'ordre de la lecture.
    final List<Sourate> ordonnees = <Sourate>[...liste]
      ..sort((Sourate a, Sourate b) => a.numero.compareTo(b.numero));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Sourate sourate in ordonnees)
          if (pageDeDepartDeLaSourate(sourate.numero) case final int page)
            _LigneSourate(
              key: cleLigne(sourate.numero),
              sourate: sourate,
              page: page,
              libelleSemantique: libelleSemantique(sourate, page),
              onPress: () => onChoisir(sourate, page),
            ),
      ],
    );
  }
}

/// Une sourate de la table : numero, nom arabe, nom translittere, page.
class _LigneSourate extends StatelessWidget {
  const _LigneSourate({
    required this.sourate,
    required this.page,
    required this.libelleSemantique,
    required this.onPress,
    super.key,
  });

  final Sourate sourate;
  final int page;
  final String libelleSemantique;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      AppTypography.tabulaire(textes.bodySmall ?? const TextStyle()),
    );

    return Pressable(
      libelleSemantique: libelleSemantique,
      onPress: onPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            // Le numero d'ordre, sur une colonne de largeur egale de 1 a 114.
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: AppSpacing.xxxl),
              child: Text(
                '${sourate.numero}',
                style: palette.inkMuted.applyTo(
                  AppTypography.tabulaire(
                    textes.labelLarge ?? const TextStyle(),
                  ),
                ),
              ),
            ),
            Ecart.hSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Le nom arabe, en premier : la police arabe des documents,
                  // de droite a gauche, quelle que soit la langue de l'ecran.
                  Text(
                    sourate.nomArabe,
                    textDirection: TextDirection.rtl,
                    style: palette.surfaceRaised.applyTo(
                      AppTypography.document(
                        taille: _tailleNomArabe,
                        interligne: _interligneNomArabe,
                      ),
                    ),
                  ),
                  Text(
                    sourate.nomTranslittere,
                    style: palette.surfaceRaised.applyTo(
                      textes.labelLarge ?? const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
            Ecart.hSm,
            Text(t.tc.coran.navigation.pageNumero(page: page), style: discret),
            Ecart.hSm,
            Icon(AppIcons.chevron.repos, size: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Le nom arabe se lit d'abord : un cran au-dessus du nom translittere.
  static const double _tailleNomArabe = 24;
  static const double _interligneNomArabe = 1.5;
}
