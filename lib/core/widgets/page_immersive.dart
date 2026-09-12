import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Les deux registres d'un ecran immersif.
///
/// Deux, et pas un parametre de couleur libre : ce sont les deux seuls moments
/// du produit ou l'on sort du fond creme, et chacun a sa raison. Un troisieme
/// registre demanderait d'abord une raison ecrite.
enum RegistreImmersif {
  /// La salle de cours. Registre inverse : une scene video se regarde sur un
  /// fond sombre, et c'est aussi ce qui fait ressortir le bandeau permanent.
  salle,

  /// La lecture du Coran. Fond plus chaud que le reste de l'application, pour
  /// signaler qu'on entre dans un espace different du produit
  /// (`docs/produit/parcours-utilisateurs.md`, direction artistique `ELV-04`).
  lecture,
}

/// La coquille des ecrans sans page : plein cadre, sans titre, sans gouttiere.
///
/// **Le pendant de `PageShell`, pour le cas que `PageShell` ne sait pas tenir.**
/// Tout ecran du produit passe par une coquille, et `tool/verifier_jetons.dart`
/// echoue sur tout `Scaffold` monte dans `lib/features/` : c'est le defaut
/// mesure sur le tunnel d'entree le 11 septembre 2026. Mais la salle et le
/// lecteur de Coran ne veulent ni titre d'ecran, ni colonne bornee, ni
/// gouttiere : la Bible V2 section 22 leur impose l'inverse, `CONTENT > CHROME`,
/// et le Coran ne se traite jamais comme une carte entouree de controles.
///
/// Elle tient donc, et aucun ecran ne les refait :
///
/// - le registre du fond, et **la paire qui va avec** : les textes et les icones
///   poses dedans heritent de l'encre lisible sur ce fond, sans qu'aucun enfant
///   n'ait a la demander ;
/// - la zone sure, parce qu'un contenu plein cadre passe sous l'encoche ;
/// - la gouttiere du gabarit courant sur les seules zones qui en ont besoin,
///   l'entete et les commandes -- le contenu, lui, va au bord ;
/// - l'ordre vertical : entete, contenu, bandeau, commandes. **Le bandeau est
///   entre le contenu et les commandes**, c'est-a-dire a l'endroit que l'on
///   regarde en decidant d'ouvrir son micro.
///
/// Elle ne porte volontairement **pas** le bandeau hors ligne de `PageShell` :
/// en salle, c'est le moteur temps reel qui sait si le lien tient, et deux
/// signaux concurrents finiraient par se contredire a l'ecran.
class PageImmersive extends StatelessWidget {
  /// Cree un ecran immersif.
  const PageImmersive({
    required this.child,
    required this.registre,
    super.key,
    this.entete,
    this.bandeau,
    this.commandes,
  });

  /// Le contenu primaire. Il occupe tout ce qui reste, et va jusqu'aux bords.
  final Widget child;

  /// Le registre du fond.
  final RegistreImmersif registre;

  /// Une ligne de contexte en haut : un etat, une pastille, un rappel.
  /// Discrete par construction, c'est le contenu qui domine.
  final Widget? entete;

  /// Le bandeau permanent, quand l'ecran en a un. Jamais masque.
  final Widget? bandeau;

  /// La rangee de commandes, collee en bas.
  final Widget? commandes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = switch (registre) {
      RegistreImmersif.salle => palette.surfaceInverse,
      RegistreImmersif.lecture => palette.surfaceQuran,
    };
    final Gabarit gabarit = AppGabarit.de(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: paire.background,
      body: SafeArea(
        // Le texte et les icones prennent l'encre de la paire une fois pour
        // toutes : sans cela, chaque libelle de la salle devrait la redemander,
        // et le premier oubli ecrirait en encre sombre sur un fond sombre.
        child: DefaultTextStyle(
          style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
          child: IconTheme(
            data: IconThemeData(color: paire.onBackground, size: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (entete != null)
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: gabarit.gouttiere,
                      vertical: AppSpacing.md,
                    ),
                    child: entete,
                  ),
                Expanded(child: child),
                ?bandeau,
                if (commandes != null)
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: gabarit.gouttiere,
                      vertical: AppSpacing.lg,
                    ),
                    child: commandes,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
