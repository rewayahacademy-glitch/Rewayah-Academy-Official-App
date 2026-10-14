import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import 'brand_logo.dart';

/// La zone de marque du tunnel d'entree.
///
/// Deux formes :
/// - [logo] vrai (LOGO-APP, 10/10/2026) : le logo vertical du directeur
///   (`BrandLogo`, README du logo : « Connexion [...] : `logo-vertical`,
///   centre, dans un espace degage »), violet de marque, lu « Rewayah
///   Academy » comme une image titre puisque le nom n'est plus ecrit en
///   texte. Pose par la connexion seulement ;
/// - [logo] faux : le nom du produit en texte, en `inkAccent`, pour les pages
///   que ce lot ne touche pas (l'ecran de demarrage, qui recevra une
///   animation propre sur decision du directeur du 10/10 ; la presentation
///   publique, chantier K-64 ; la recuperation d'acces, tache secondaire a
///   retour ou le formulaire doit rester au-dessus de la ligne de flottaison
///   d'une fenetre basse ; le depot de piece).
class MarquePage extends StatelessWidget {
  /// Cree la zone de marque.
  const MarquePage({super.key, this.logo = false});

  /// Vrai pour le logo vertical, faux pour le mot-marque en texte.
  final bool logo;

  /// La hauteur du logo vertical, hors zone de protection (25 % de chaque
  /// cote) : bien au-dessus du minimum de 56 du README.
  static const double hauteurLogo = 96;

  /// La hauteur du logo sur une fenetre basse (moins de [fenetreBasse]) :
  /// le logo cede de la place au formulaire, sans descendre au minimum.
  static const double hauteurLogoCompacte = 64;

  /// La hauteur de fenetre sous laquelle le logo prend sa taille compacte.
  static const double fenetreBasse = 720;

  @override
  Widget build(BuildContext context) {
    if (logo) {
      return Semantics(
        header: true,
        child: BrandLogo(
          variante: VarianteLogo.vertical,
          hauteur: MediaQuery.sizeOf(context).height < fenetreBasse
              ? hauteurLogoCompacte
              : hauteurLogo,
          libelle: t.commun.marque,
        ),
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // Le mot-marque est un titre : DM Sans (`titleLarge`, 22/28, 600). **Il est
    // toujours plus petit que le titre de l'ecran qu'il surmonte** (HIER-1,
    // revue du directeur du 01/10 : « Rewayah Academy » et « Apprendre le
    // Coran... » etaient a la meme taille) : le titre d'ecran prend un
    // `headline*`, la marque un cran en dessous. `display*` porte les valeurs
    // chiffrees en Jakarta tabulaire (revue phase 0, jetons D6).
    //
    // Aucun mot coupe a 320 px, texte x2 (PUB-1 : la marque partage sa ligne
    // avec la croix de la presentation) : le mot le plus long se reduit juste
    // assez pour tenir ; a l'echelle 1, rien ne change.
    return Semantics(
      header: true,
      child: TexteSansCoupure(
        t.commun.marque,
        textAlign: TextAlign.center,
        style: palette.inkAccent.applyTo(
          textes.titleLarge ?? const TextStyle(),
        ),
      ),
    );
  }
}
