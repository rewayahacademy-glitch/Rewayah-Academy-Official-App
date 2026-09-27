import 'package:flutter/widgets.dart';

/// Le budget de mouvement de l'application.
///
/// Source : `docs/archive/2026-09-pre-remise-a-plat/design/04-systeme-mouvement.md`, valeurs resumees dans
/// `docs/archive/2026-09-pre-remise-a-plat/produit/design-tokens.md` section 11.
///
/// **C'est le seul fichier du depot autorise a poser une duree d'animation
/// litterale ou a nommer une [Curve]** : `tool/verifier_jetons.dart` echoue sur
/// tout `Duration(milliseconds: ...)` et tout `Curves.` ailleurs dans `lib/`.
/// Les durees metier, elles, restent libres : une pause de priere en minutes ou
/// un cache de vingt-quatre heures ne sont pas du mouvement.
///
/// Le mouvement a une fonction : expliquer un changement, donner un retour,
/// maintenir la continuite dans l'espace. Un mouvement qui ne fait aucun des
/// trois se retire.
abstract final class AppMouvement {
  /// La pression d'un element. Tenu par `Pressable`.
  static const Duration retourTactile = Duration(milliseconds: 100);

  /// Bascule, case cochee, pastille qui change d'etat, survol.
  static const Duration micro = Duration(milliseconds: 120);

  /// Une ligne qui entre ou sort d'une liste, un bandeau, un retour local.
  static const Duration apparition = Duration(milliseconds: 180);

  /// Passage d'une page a l'autre.
  static const Duration navigation = Duration(milliseconds: 220);

  /// Ouverture d'une feuille de bas d'ecran.
  static const Duration feuilleOuverture = Duration(milliseconds: 180);

  /// Fermeture d'une feuille. **La sortie est toujours plus courte que
  /// l'entree**, d'environ un tiers.
  static const Duration feuilleFermeture = Duration(milliseconds: 120);

  /// Plafond absolu. Une animation plus longue que ca n'explique plus, elle
  /// fait attendre.
  static const Duration plafond = Duration(milliseconds: 400);

  /// La disparition d'un element : l'opacite part avant la hauteur.
  static const Duration disparitionOpacite = Duration(milliseconds: 120);

  /// Periode d'un battement complet de la pulsation d'`ELV-02`.
  ///
  /// **Hors du budget de transition, et c'est voulu** : le plafond de 400 ms
  /// borne ce qui explique un changement, pas ce qui signale une imminence en
  /// continu. Un battement de 400 ms serait une alarme.
  ///
  /// **Un seul element peut pulser a l'ecran**, et c'est celui-la : le bloc
  /// "cours dans moins de 5 minutes". Deux pulsations simultanees annulent le
  /// sens des deux (`04-systeme-mouvement.md` section 4).
  static const Duration pulsation = Duration(milliseconds: 1200);

  /// Temps d'affichage d'un retour local, avant sa disparition.
  static const Duration retourLocalMaintien = Duration(seconds: 3);

  /// Delai avant qu'un squelette de chargement apparaisse.
  ///
  /// **Sous ce delai, on n'affiche rien du tout** : un squelette qui clignote
  /// coute plus cher qu'il ne rassure (`02-regles-ux.md` section 6). Porte par
  /// `Skeleton` lui-meme, pour qu'aucun ecran n'ait a s'en souvenir.
  static const Duration delaiSquelette = apparition;

  /// Tout ce qui entre. Rapide au depart, s'installe doucement.
  static const Curve selection = Curves.easeOut;
  static const Curve entree = Curves.easeOutCubic;

  /// Tout ce qui sort.
  static const Curve sortie = Curves.easeInCubic;

  /// Reserve aux rotations continues et aux barres de progression
  /// indeterminees. Interdit partout ailleurs.
  static const Curve progressionIndeterminee = Curves.linear;

  /// Ressort des feuilles et du conteneur partage.
  ///
  /// Amortissement critique : aucun rebond visible, seulement une arrivee qui
  /// n'est pas mecanique. `bounceOut` et `elasticOut` n'existent pas dans ce
  /// produit, y compris en mode enfant.
  static final SpringDescription ressort = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 220,
    ratio: 1,
  );

  /// Translation verticale d'un element qui entre dans une liste.
  static const double translationAjout = 8;

  /// Translation verticale d'un retour local.
  static const double translationRetourLocal = 12;

  /// Translation horizontale d'une transition de page. **Le sens s'inverse en
  /// RTL** : une page qui entre par la droite en francais entre par la gauche
  /// en arabe.
  static const double translationNavigation = 16;

  /// Opacite du voile sous une feuille de bas d'ecran.
  static const double opaciteVoile = 0.32;

  /// La duree effective d'une animation, preference systeme comprise.
  ///
  /// Quand le systeme signale la reduction du mouvement, tout retombe a
  /// [disparitionOpacite] : il reste un fondu, jamais un glissement.
  static Duration duree(BuildContext context, Duration voulue) =>
      mouvementReduit(context) ? Duration.zero : voulue;

  /// La translation effective d'un motif, preference systeme comprise.
  ///
  /// Sous reduction du mouvement, une translation vaut zero : il ne reste que
  /// l'opacite.
  static double translation(BuildContext context, double voulue) =>
      mouvementReduit(context) ? 0 : voulue;

  /// Vrai quand le systeme demande de reduire le mouvement.
  ///
  /// Ce n'est pas une case a cocher : supprimer une animation qui portait du
  /// sens supprime le sens avec elle. La pulsation d'`ELV-02` se remplace alors
  /// par une bordure fixe `borderStrong`, jamais par rien
  /// (`04-systeme-mouvement.md` section 5).
  static bool mouvementReduit(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
