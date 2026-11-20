// PE-D8 (directeur, 19/11/2026 : « rien ne pousse la page ») : un avis
// general (nouvelle version, « Vous avez recu un nouveau message », « Cette
// classe n'existe plus ») flotte en haut de l'ecran, PAR-DESSUS le contenu.
// Il ne decale rien : un toucher vise sous lui ne rate plus sa cible.
//
// Contrat de navigation (20/11/2026) §1, surface « Avis » : flotte en haut,
// par-dessus, sur ordinateur comme au telephone. §4 : il se ferme par sa croix
// ou en le glissant vers le haut ; un avis court se retire aussi de lui-meme.
//
// Mouvement (DECISION-MOUVEMENT-2026-11-11, DECISION-FLUIDITE-2026-11-07) :
// entree et sortie par le ressort a amortissement critique de la maison
// (`AppMouvement.ressortDeplacement`), aux durees des jetons ; sous « reduire
// les animations », plus de glissement, seulement le fondu.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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

/// L'entree et la sortie d'un avis : il descend du haut et s'y retire, par le
/// ressort de la maison. [child] `null` : rien.
class PassageAvis extends StatelessWidget {
  /// Cree le passage.
  const PassageAvis({required this.child, super.key});

  /// L'avis a montrer (avec une cle propre a son message), ou `null`.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bool reduit = AppMouvement.mouvementReduit(context);
    return AnimatedSwitcher(
      duration: AppMouvement.deplacementEntree,
      reverseDuration: AppMouvement.deplacementSortie,
      switchInCurve: AppMouvement.ressortDeplacement,
      switchOutCurve: AppMouvement.sortie,
      layoutBuilder: (Widget? courant, List<Widget> precedents) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...precedents, ?courant],
      ),
      transitionBuilder: (Widget enfant, Animation<double> avancement) {
        final Widget fondu = FadeTransition(opacity: avancement, child: enfant);
        if (reduit) return fondu;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(avancement),
          child: fondu,
        );
      },
      child: child ?? const SizedBox.shrink(),
    );
  }
}

/// Un avis flottant : une icone, une phrase, des actions facultatives et une
/// croix. Il se ferme par la croix ou en le glissant vers le haut ; il ne
/// recouvre que la bande du haut, jamais tout l'ecran.
class AvisFlottant extends StatefulWidget {
  /// Cree l'avis.
  const AvisFlottant({
    required this.message,
    required this.onFermer,
    this.icone,
    this.actions = const <Widget>[],
    super.key,
  });

  /// Ce qui se passe, en une phrase.
  final String message;

  /// La fermeture (croix ou glissement vers le haut).
  final VoidCallback onFermer;

  /// L'icone devant la phrase, `null` pour l'icone d'information.
  final IconData? icone;

  /// Les actions, au bout de la phrase (« Mettre a jour », « Plus tard »).
  final List<Widget> actions;

  /// La cle de la croix.
  static const Key cleFermer = ValueKey<String>('avis-flottant-fermer');

  /// La cle de la zone qui se glisse.
  static const Key cleGlisser = ValueKey<String>('avis-flottant-glisser');

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
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = palette.surfaceRaised.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    return Dismissible(
      key: AvisFlottant.cleGlisser,
      direction: DismissDirection.up,
      movementDuration: AppMouvement.deplacementSortie,
      resizeDuration: null,
      onDismissed: (DismissDirection _) => _glisse(),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Container(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.lg,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          decoration: AppElevation.avecFilet(
            // Les couleurs de l'application, pas le jaune d'alerte : un avis
            // informe, il n'alarme pas.
            surface: palette.surfaceRaised,
            filet: palette.borderHairline,
            ombre: palette.ombre,
            arrondi: AppRadius.arrondiMd,
            ombres: AppElevation.niveau2(palette.ombre),
          ),
          child: Row(
            children: <Widget>[
              ExcludeSemantics(
                child: IconTheme(
                  data: palette.inkAccent.asIconTheme(),
                  child: Icon(widget.icone ?? AppIcons.info.repos),
                ),
              ),
              Ecart.hMd,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
    );
  }
}
