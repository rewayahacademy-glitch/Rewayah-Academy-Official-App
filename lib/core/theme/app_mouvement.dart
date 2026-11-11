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

  /// S0.2c (pilote, 24/10/2026) : les surimpressions de la salle plein ecran
  /// au telephone se masquent apres trois secondes sans geste.
  static const Duration masquageSalle = Duration(seconds: 3);

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

  /// Decalage entre deux elements d'une liste echelonnee (A-13, 17/10/2026).
  static const Duration echelon = Duration(milliseconds: 35);

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

  /// Periode d'un battement complet du point de la pastille « En direct »
  /// (ON-AIR-1, demande du directeur du 01/10/2026 : cycle d'environ 1,5 s).
  ///
  /// **Hors du budget de transition**, comme [pulsation] : elle signale un
  /// etat qui dure, elle n'explique pas un changement. Plus lente que
  /// [pulsation] (1,2 s, imminence) pour que les deux ne se confondent pas.
  static const Duration pulsationDirect = Duration(milliseconds: 1500);

  /// Periode d'un passage du reflet lent sur un squelette de chargement
  /// (FLUIDITE-1, `docs/current/DECISION-FLUIDITE-2026-11-07.md` §2 : « un
  /// reflet lumineux lent qui traverse les blocs »).
  ///
  /// **Hors du budget de transition** : une boucle d'attente, qui dure tant
  /// que l'attente dure (la decision leve le plafond de 400 ms pour elle).
  /// Plus lente que [pulsationDirect] : le reflet accompagne, il n'alerte pas.
  /// Aucune boucle sous mouvement reduit.
  static const Duration refletSquelette = Duration(milliseconds: 1800);

  /// La coche de reussite d'`ActionPrincipale` (FLUIDITE-1, decision §2 :
  /// « une reussite se voit ») : le temps ou elle reste lisible, entre son
  /// entree ([apparition]) et sa sortie ([disparitionOpacite]). Jouee une
  /// seule fois, apres la confirmation du serveur ; total sous la seconde.
  static const Duration reussiteMaintien = Duration(milliseconds: 600);

  /// L'entree de l'illustration « la porte et la lumiere » sur la surface de
  /// marque (parcours d'entree, decision du directeur du 25/10/2026,
  /// `docs/current/PARCOURS-ENTREE-2026-10-25.md` §3) : le symbole se dessine,
  /// la porte s'ouvre, la lumiere sort et s'etire au sol, les pas et la
  /// lanterne apparaissent. **Une fois, 1,5 s au plus, jamais en boucle**,
  /// puis la scene reste immobile. **Hors du budget de transition**, comme
  /// [pulsation] : elle raconte l'arrivee, elle n'explique pas un changement.
  /// En mouvement reduit, la meme duree en fondus seuls, meme image finale.
  static const Duration entreeIllustration = Duration(milliseconds: 1500);

  /// Nombre de battements du point « En direct » avant qu'il reste fixe :
  /// trois fois [pulsationDirect], soit 4,5 s, **sous les cinq secondes** au
  /// dela desquelles WCAG 2.2.2 exige une commande d'arret. Le mot « En
  /// direct » reste, le point reste, seul le battement s'arrete.
  static const int battementsDirect = 3;

  /// Rayon maximal du halo du point « En direct », en multiple du diametre du
  /// point (ON-AIR-1). Le halo grossit de 1 a 1 + cette valeur en s'effacant.
  static const double ampleurHaloDirect = 1.2;

  /// Opacite de depart du halo du point « En direct », avant qu'il s'efface.
  /// Posee sur le halo seul, jamais sur le texte.
  static const double opaciteHaloDirect = 0.45;

  /// NAV-REFONTE (09/11/2026), halo du cercle Compte : un tour de lumiere
  /// d'une alerte urgente (rapide). **Hors du budget de transition**, comme
  /// [pulsationDirect] : il signale un etat. [toursHaloUrgent] tours, 4,8 s,
  /// sous les cinq secondes de WCAG 2.2.2, puis une lueur fixe.
  static const Duration tourHaloUrgent = Duration(milliseconds: 1200);

  /// Nombre de tours de la lumiere d'une alerte urgente.
  static const int toursHaloUrgent = 4;

  /// Halo d'une nouveaute a lire : un seul tour, qui ralentit, puis une lueur
  /// fixe.
  static const Duration tourHaloNouveau = Duration(milliseconds: 2000);

  /// Halo de la salle ouverte (etape 2b, 10/11/2026) : une respiration
  /// lente de la lumiere, [respirationsHalo] fois (4,8 s, sous les cinq
  /// secondes de WCAG 2.2.2), puis une lueur fixe. Hors du budget de
  /// transition : il signale un etat.
  static const Duration respirationHalo = Duration(milliseconds: 2400);

  /// Nombre de respirations de la salle ouverte.
  static const int respirationsHalo = 2;

  /// Le retournement unique de la photo vers l'icone d'etat, puis retour
  /// (decision du directeur du 09/11/2026). Aucun retournement sous mouvement
  /// reduit : la pastille seule.
  static const Duration retournementHalo = Duration(milliseconds: 1000);

  /// Temps d'affichage d'un retour local, avant sa disparition.
  static const Duration retourLocalMaintien = Duration(seconds: 3);

  /// Rappel discret recu (30/10/2026) : « Le professeur vous appelle » reste
  /// lisible ce temps, puis s'efface.
  static const Duration rappelRecuMaintien = Duration(seconds: 5);

  /// Rappel discret recu : la vibration courte, quand l'appareil la permet.
  static const Duration vibrationRappel = Duration(milliseconds: 200);

  /// Rappel discret recu : le son doux, court, quand l'appareil le permet.
  static const Duration sonRappel = Duration(milliseconds: 250);

  /// Delai avant qu'un squelette de chargement apparaisse.
  ///
  /// **Sous ce delai, on n'affiche rien du tout** : un squelette qui clignote
  /// coute plus cher qu'il ne rassure (`02-regles-ux.md` section 6). Porte par
  /// `Skeleton` lui-meme, pour qu'aucun ecran n'ait a s'en souvenir.
  static const Duration delaiSquelette = apparition;

  /// Tout ce qui entre. Rapide au depart, s'installe doucement.
  static const Curve selection = Curves.easeOut;
  static const Curve entree = Curves.easeOutCubic;

  /// Courbe du battement du point « En direct » : douce aux deux bouts, sans
  /// rebond (voir [pulsationDirect]).
  static const Curve pulsationCourbe = Curves.easeInOut;

  /// Courbe « emphasized » de Material 3, pour les transitions de page
  /// (A-13, 17/10/2026).
  static const Curve accentuee = Curves.easeInOutCubicEmphasized;

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

  /// L'effet liquide de la navigation (decisions du directeur du 10/11/2026) :
  /// le bord de devant de la goutte, raide, qui part le premier. Amortissement
  /// critique, comme [ressort] : aucun rebond.
  static final SpringDescription ressortGoutteTete =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 520, ratio: 1);

  /// Le bord de derriere de la goutte, plus souple, qui suit : l'ecart entre
  /// les deux etire la goutte dans le sens du mouvement, puis elle se reforme.
  static final SpringDescription ressortGoutteQueue =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 170, ratio: 1);

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
