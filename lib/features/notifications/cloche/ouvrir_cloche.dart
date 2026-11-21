// Ouvrir la cloche (CLOCHE-C, decision du directeur du 21/11/2026, regle 1) :
// a 840 points et plus, le panneau ancre de 400 sous la cloche
// (`AppBottomSheet.ouvrirAncre`) ; en dessous, la feuille du bas
// (`AppBottomSheet.ouvrir`, 90 % de la hauteur au plus, poignee, croix).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import 'contenu_cloche.dart';

/// La largeur du panneau de la cloche (decision du 21/11, regle 1).
const double largeurPanneauCloche = AppPage.largeurVolet;

/// La cle du panneau d'ordinateur, pour les tests.
const ValueKey<String> clePanneauCloche = ValueKey<String>('cloche-panneau');

/// Ouvre la cloche depuis [contexte], celui du bouton (le panneau s'ancre sous
/// lui). [cheminPage] : la page complete du role, ou nul (le candidat).
Future<void> ouvrirCloche(BuildContext contexte, {String? cheminPage}) {
  final GoRouter? routeur = GoRouter.maybeOf(contexte);
  void aller(String chemin) {
    if (routeur == null) return;
    // BUREAU-NAV : dans le bureau, l'objet d'une notification s'empile ;
    // ailleurs, et pour la page complete, il remplace.
    if (chemin != cheminPage && chemin.startsWith('${Routes.admin}/')) {
      unawaited(routeur.push<void>(chemin));
    } else {
      routeur.go(chemin);
    }
  }

  final double largeur = MediaQuery.sizeOf(contexte).width;
  if (largeur < AppGabarit.seuilEtendu) {
    return AppBottomSheet.ouvrir<void>(
      contexte,
      titre: t.notifications.titre,
      libelleFermer: t.commun.fermer,
      // Le titre, « Tout marquer comme lu » et la croix sur une rangee.
      actionTitre: (BuildContext _) => const ActionToutLireCloche(),
      constructeur: (BuildContext feuille) => ContenuCloche(
        forme: FormeCloche.feuille,
        cheminPage: cheminPage,
        naviguer: (String chemin) {
          Navigator.of(feuille).pop();
          aller(chemin);
        },
      ),
    );
  }

  final RenderBox? boite = contexte.findRenderObject() as RenderBox?;
  final Rect ancre = boite == null || !boite.hasSize
      ? Rect.fromLTWH(largeur - AppSpacing.xxl, 0, 0, AppSpacing.section)
      : boite.localToGlobal(Offset.zero) & boite.size;
  return AppBottomSheet.ouvrirAncre<void>(
    contexte,
    ancre: ancre,
    largeur: largeurPanneauCloche,
    cle: clePanneauCloche,
    constructeur: (BuildContext panneau) => ContenuCloche(
      forme: FormeCloche.panneau,
      cheminPage: cheminPage,
      naviguer: (String chemin) {
        Navigator.of(panneau).pop();
        aller(chemin);
      },
    ),
  );
}
