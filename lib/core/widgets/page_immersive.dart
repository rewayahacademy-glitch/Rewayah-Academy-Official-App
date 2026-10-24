import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_contour.dart';
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
  /// (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`, direction artistique `ELV-04`).
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
    this.surface,
    this.lateraleEnPaysage = false,
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

  /// La paire de fond, quand l'ecran impose la surface de l'application plutot
  /// que celle de son registre (le Mushaf de Medine, MUSHAF-15L : le fond de
  /// la page est la surface de l'application, jamais un parchemin). Sans elle,
  /// le registre decide.
  final AppColorPair? surface;

  /// D9 (24/10/2026) : sur un telephone en paysage, l'en-tete, le bandeau et
  /// les commandes passent dans une colonne laterale, et le contenu primaire
  /// (la page du Coran en salle) prend toute la hauteur. Faux par defaut :
  /// les autres ecrans immersifs gardent leur composition.
  final bool lateraleEnPaysage;

  /// La hauteur d'ecran sous laquelle un paysage est un telephone couche.
  static const double hauteurTelephonePaysage = AppSpacing.respiration * 8;

  /// La largeur de la colonne laterale d'un telephone en paysage.
  static const double largeurColonneLaterale = AppSpacing.respiration * 5;

  /// Vrai sur un telephone couche (paysage et ecran bas).
  static bool telephonePaysage(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape &&
      MediaQuery.sizeOf(context).height < hauteurTelephonePaysage;

  /// La cle de la zone du contenu primaire (tests de geometrie, SALLE-200-1).
  static const Key contenuKey = ValueKey<String>('page-immersive-contenu');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire =
        surface ??
        switch (registre) {
          RegistreImmersif.salle => palette.surfaceInverse,
          RegistreImmersif.lecture => palette.surfaceQuran,
        };
    final Gabarit gabarit = AppGabarit.de(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool texteAgrandi =
        MediaQuery.textScalerOf(context).scale(1) >
        AppContour.seuilTexteAgrandi;

    return Scaffold(
      backgroundColor: paire.background,
      body: SafeArea(
        // Le texte et les icones prennent l'encre de la paire une fois pour
        // toutes : sans cela, chaque libelle de la salle devrait la redemander,
        // et le premier oubli ecrirait en encre sombre sur un fond sombre.
        child: DefaultTextStyle(
          style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
          child: IconTheme(
            data: IconThemeData(
              color: paire.onBackground,
              size: AppSpacing.xxl,
            ),
            child: lateraleEnPaysage && telephonePaysage(context)
                ? _lateral(texteAgrandi)
                : Column(
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
                      Expanded(
                        child: KeyedSubtree(key: contenuKey, child: child),
                      ),
                      ?bandeau,
                      if (commandes != null)
                        Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: gabarit.gouttiere,
                            // SALLE-200-1 : texte tres agrandi, les commandes
                            // compactes se serrent pour laisser le support respirer.
                            vertical: texteAgrandi
                                ? AppSpacing.sm
                                : AppSpacing.lg,
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

  /// Le telephone couche : le contenu a gauche sur toute la hauteur, la
  /// colonne laterale a droite (en-tete en haut, bandeau et commandes en
  /// bas). Les commandes se reduisent si la colonne est trop etroite, sans
  /// jamais deborder.
  Widget _lateral(bool texteAgrandi) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Expanded(
        child: KeyedSubtree(key: contenuKey, child: child),
      ),
      SizedBox(
        width: largeurColonneLaterale,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ?entete,
              const Spacer(),
              ?bandeau,
              if (commandes != null)
                FittedBox(fit: BoxFit.scaleDown, child: commandes),
            ],
          ),
        ),
      ),
    ],
  );
}
