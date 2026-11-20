// PE-D8 (directeur, 19/11/2026 : « rien ne pousse la page ») : un avis
// general (nouvelle version, « Vous avez recu un nouveau message », « Cette
// classe n'existe plus ») flotte en haut de l'ecran, PAR-DESSUS le contenu.
// Il ne decale rien : un toucher vise sous lui ne rate plus sa cible.
//
// Contrat de navigation (20/11/2026) §1, surface « Avis » : flotte en haut,
// par-dessus, sur ordinateur comme au telephone. §4 : il se ferme par sa croix
// ou en le glissant vers le haut ; un avis court se retire aussi de lui-meme.
//
// Forme (directeur, 20/11/2026 : « le visuel ne respecte pas les elements des
// maquettes qu'on a valide, avec un petit message qui surgit du haut pour
// quelques secondes ») : une pilule large comme son texte, centree, sur la
// surface inverse du theme (sombre sur clair, claire sur sombre), un point
// d'accent devant la phrase, ses actions dedans. Plus de carte pleine largeur
// ni de croix : un avis court part seul ; un avis qui reste porte sa croix.
//
// Mouvement : il tombe du haut par `AppMouvement.ressortAvis` (il depasse sa
// place de quelques points puis s'y pose) et repart vers le haut en
// accelerant ; sous « reduire les animations », seulement le fondu.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/bouton_icone.dart';

/// La couche des avis : [child] (toute l'application) et, par-dessus, en
/// haut, les [avis]. Rien ne prend de place dans la page.
class CoucheAvis extends StatelessWidget {
  /// Cree la couche.
  const CoucheAvis({required this.child, required this.avis, super.key});

  /// L'application.
  final Widget child;

  /// Les avis, de haut en bas ; chacun ne rend rien tant qu'il n'a rien a
  /// dire.
  final List<Widget> avis;

  /// La largeur la plus grande d'un avis (celle d'un formulaire) : sur
  /// ordinateur il ne barre pas tout l'ecran.
  static const double largeurMax = AppPage.largeurFormulaire;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      child,
      PositionedDirectional(
        top: 0,
        start: 0,
        end: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: largeurMax),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // Chaque avis est large comme son texte, centre.
                  spacing: AppSpacing.sm,
                  children: avis,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/// L'entree et la sortie d'un avis : il tombe du haut, depasse sa place de
/// quelques points, s'y pose, puis repart vers le haut. [child] `null` : rien.
class PassageAvis extends StatelessWidget {
  /// Cree le passage.
  const PassageAvis({required this.child, super.key});

  /// L'avis a montrer (avec une cle propre a son message), ou `null`.
  final Widget? child;

  /// D'ou tombe l'avis, en hauteurs d'avis au-dessus de sa place.
  static const double _hauteurDeChute = 1.4;

  @override
  Widget build(BuildContext context) {
    final bool reduit = AppMouvement.mouvementReduit(context);
    return AnimatedSwitcher(
      duration: AppMouvement.avisEntree,
      reverseDuration: AppMouvement.deplacementSortie,
      // Les courbes sont posees ci-dessous, une par propriete.
      switchInCurve: AppMouvement.sansCourbe,
      switchOutCurve: AppMouvement.sansCourbe,
      layoutBuilder: (Widget? courant, List<Widget> precedents) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...precedents, ?courant],
      ),
      transitionBuilder: (Widget enfant, Animation<double> avancement) {
        final Widget fondu = FadeTransition(
          opacity: CurvedAnimation(
            parent: avancement,
            curve: AppMouvement.courbeFondu,
          ),
          child: enfant,
        );
        if (reduit) return fondu;
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, -_hauteurDeChute),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: avancement,
                  // Il tombe et rebondit.
                  curve: AppMouvement.ressortAvis,
                  // Au retour le controleur va de 1 a 0 : cette courbe le
                  // fait partir doucement puis filer vers le haut.
                  reverseCurve: AppMouvement.entree,
                ),
              ),
          child: fondu,
        );
      },
      child: child ?? const SizedBox.shrink(),
    );
  }
}

/// Un avis flottant : une pilule, un point d'accent (ou une icone), une
/// phrase et des actions facultatives. Il se ferme en le glissant vers le
/// haut, par Echap, ou par sa croix quand il en porte une ([croix]) ; il ne
/// recouvre qu'un petit morceau du haut de l'ecran.
class AvisFlottant extends StatefulWidget {
  /// Cree l'avis.
  const AvisFlottant({
    required this.message,
    required this.onFermer,
    this.icone,
    this.actions = const <Widget>[],
    this.croix = false,
    super.key,
  });

  /// Ce qui se passe, en une phrase.
  final String message;

  /// La fermeture (glissement vers le haut, Echap, croix).
  final VoidCallback onFermer;

  /// L'icone devant la phrase ; `null` : le point d'accent.
  final IconData? icone;

  /// Les actions, au bout de la phrase (« Mettre a jour », « Plus tard »).
  /// Elles sont rendues dans le theme inverse, celui de la pilule.
  final List<Widget> actions;

  /// Vrai : l'avis porte une croix. A reserver a l'avis qui ne part pas seul
  /// et dont aucune action ne le ferme.
  final bool croix;

  /// La cle de la croix.
  static const Key cleFermer = ValueKey<String>('avis-flottant-fermer');

  /// La cle de la zone qui se glisse.
  static const Key cleGlisser = ValueKey<String>('avis-flottant-glisser');

  /// La cle de la pilule, pour les tests.
  static const Key clePilule = ValueKey<String>('avis-flottant-pilule');

  @override
  State<AvisFlottant> createState() => _EtatAvisFlottant();
}

class _EtatAvisFlottant extends State<AvisFlottant> {
  /// Vrai une fois glisse hors de l'ecran : il ne se redessine plus (un
  /// `Dismissible` parti ne doit pas rester dans l'arbre pendant la sortie).
  bool _parti = false;

  /// Vrai une fois ferme par Echap : un second appui ne ferme rien de plus.
  bool _fermeParEchap = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_touche);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_touche);
    super.dispose();
  }

  /// Contrat de navigation §9 : Echap ferme la surface du dessus ; l'avis
  /// est la couche la plus haute de l'application.
  bool _touche(KeyEvent evenement) {
    if (_parti || _fermeParEchap) return false;
    if (evenement is! KeyDownEvent ||
        evenement.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    _fermeParEchap = true;
    widget.onFermer();
    return true;
  }

  void _glisse() {
    setState(() => _parti = true);
    widget.onFermer();
  }

  @override
  Widget build(BuildContext context) {
    if (_parti) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = AppPalette.of(context);
    // La pilule est un morceau de l'autre theme : sombre sur une page claire,
    // claire sur une page sombre. Ses enfants (point, actions, croix) lisent
    // donc la palette inverse.
    final AppPalette inverse = palette.estSombre
        ? AppPalette.claire()
        : AppPalette.sombre();
    final ThemeData themeInverse = theme.copyWith(
      // Meme ecriture que `choice_card_group.dart` (le compilateur refuse
      // `ThemeExtension<dynamic>` ici) : les autres extensions restent, seule
      // la palette change.
      extensions: <ThemeExtension<ThemeExtension<dynamic>>>[
        ...theme.extensions.values
            .where((ThemeExtension<dynamic> e) => e is! AppPalette)
            .cast<ThemeExtension<ThemeExtension<dynamic>>>(),
        inverse,
      ],
    );
    final TextStyle corps = palette.surfaceInverse.applyTo(
      theme.textTheme.bodyMedium ?? const TextStyle(),
    );
    final bool avecFin = widget.croix || widget.actions.isNotEmpty;
    return Dismissible(
      key: AvisFlottant.cleGlisser,
      direction: DismissDirection.up,
      movementDuration: AppMouvement.deplacementSortie,
      resizeDuration: null,
      onDismissed: (DismissDirection _) => _glisse(),
      child: Semantics(
        container: true,
        liveRegion: true,
        onDismiss: widget.onFermer,
        child: Theme(
          data: themeInverse,
          child: Container(
            key: AvisFlottant.clePilule,
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              end: avecFin ? AppSpacing.xs : AppSpacing.lg,
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceInverse.background,
              borderRadius: AppRadius.arrondiLg,
              boxShadow: AppElevation.niveau3(palette.ombre),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ExcludeSemantics(
                  child: widget.icone == null
                      ? _PointAccent(encre: inverse.inkAccent)
                      : IconTheme(
                          data: inverse.inkAccent.asIconTheme(),
                          child: Icon(widget.icone),
                        ),
                ),
                Ecart.hMd,
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      children: <Widget>[
                        Text(widget.message, style: corps),
                        ...widget.actions,
                      ],
                    ),
                  ),
                ),
                if (widget.croix)
                  BoutonIcone(
                    key: AvisFlottant.cleFermer,
                    icone: AppIcons.fermer,
                    libelle: t.racine.avis.fermer,
                    infobulle: t.racine.avis.fermer,
                    onPress: widget.onFermer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le point d'accent devant la phrase : un disque plein, de l'encre d'accent
/// du theme de la pilule.
class _PointAccent extends StatelessWidget {
  const _PointAccent({required this.encre});

  final AppInkColor encre;

  static const double _diametre = AppSpacing.sm;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _diametre,
    child: DecoratedBox(
      decoration: ShapeDecoration(
        // Un trait epais comme le rayon remplit le disque.
        shape: CircleBorder(side: encre.asBorderSide(width: _diametre / 2)),
      ),
    ),
  );
}
