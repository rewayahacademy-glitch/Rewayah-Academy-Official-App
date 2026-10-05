// Le titre de page de l'Administration des communications et son repli
// (revue COM-R, R-09 et R-15).
//
// Le titre de la spec est « Administration des communications ». Un titre
// de page passe a la ligne entre ses mots, et un mot trop long se reduit
// jusqu'a `echelleMinimaleLisible` (`TexteSansCoupure`, COUPE-MOTS-1) ; a
// 320 et texte x2, « Administration » ne tient pas meme reduit et serait
// coupe au milieu. Dans ce seul cas, le titre se replie sur le nom de
// l'onglet ouvert (« Annonces », « Modération », « Messages »), qui tient :
// jamais un mot coupe, jamais une ellipse.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart' show echelleMinimaleLisible;
import '../i18n/strings.g.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_spacing.dart';

/// Le titre de l'Administration des communications pour une page de
/// [largeurPage] de large, ou [repli] quand un de ses mots ne tient pas a
/// l'echelle minimale lisible.
String titreAdministrationCommunications(
  BuildContext context, {
  required double largeurPage,
  required String repli,
}) {
  final String titre = t.com.socle.navigation.provisoire.administrationTitre;
  final double gouttiere = AppGabarit.de(context).gouttiere;
  final double largeur =
      math.min(largeurPage, AppPage.largeurMaxContenu) - 2 * gouttiere;
  final TextStyle? style = Theme.of(context).textTheme.headlineLarge;
  final TextDirection sens = Directionality.of(context);
  for (final String mot in titre.split(' ')) {
    if (mot.isEmpty) continue;
    final TextPainter mesure = TextPainter(
      text: TextSpan(text: mot, style: style),
      textDirection: sens,
      textScaler: const TextScaler.linear(echelleMinimaleLisible),
      maxLines: 1,
    )..layout();
    final double largeurMot = mesure.width;
    mesure.dispose();
    if (largeurMot > largeur) return repli;
  }
  return titre;
}
