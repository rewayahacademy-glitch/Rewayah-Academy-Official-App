// RUBAN-TELEPHONE (directeur, 11/11/2026 : « pense aux transitions ... il
// faut que tout soit bien coordonne ») : le passage des visages entre la
// grille (mode Classe) et le ruban (la vignette, la capsule, la bande de
// cote), MODES-AFFICHAGE §5.
//
// Version coordonnee, pas un vol : la grille qui part retrecit vers la place
// du ruban en s'effacant ([FaconVisages.sortie]) pendant que le cadre du
// ruban arrive en grandissant depuis cette place ([FaconVisages.entree]) ;
// au retour, la grille revient en grandissant depuis la meme place, plus
// vite. Jetons du lot TRANSITIONS-SALLE (D-025) seulement : le ressort sans
// rebond pour l'echelle, le fondu pour l'opacite.
//
// Regles : **aucun passage ne retarde rien** (le contenu est construit et
// utilisable des la premiere image ; le passage ne regle que l'echelle et
// l'opacite, et une sortie ne recoit ni geste ni lecture) ; il ne se joue
// qu'une fois, au montage, et seulement si on le demande ([jouer]) : une
// reconnexion, un masquage des commandes ou une reconstruction ne le
// rejouent pas ; « reduire les animations » : le fondu seul, sans echelle.

import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';

/// Le sens du passage.
enum FaconVisages {
  /// Le contenu arrive : il grandit depuis [PassageVisages.alignement] et
  /// apparait.
  entree,

  /// Le contenu part : il retrecit vers [PassageVisages.alignement] et
  /// s'efface, sans recevoir de geste ni etre lu ; [PassageVisages.onFini]
  /// dit quand le retirer.
  sortie,
}

/// Un passage des visages, joue une seule fois au montage.
class PassageVisages extends StatefulWidget {
  /// Cree le passage.
  const PassageVisages({
    required this.jouer,
    required this.facon,
    required this.duree,
    required this.child,
    this.alignement = AlignmentDirectional.topEnd,
    this.echelle = 1,
    this.onFini,
    super.key,
  });

  /// Vrai : le passage se joue au montage ; faux : le contenu est la, tel
  /// quel (le passage n'est jamais joue apres coup).
  final bool jouer;

  /// Entree ou sortie.
  final FaconVisages facon;

  /// La duree voulue (un jeton de [AppMouvement]).
  final Duration duree;

  /// La place du ruban, vers laquelle (ou depuis laquelle) le contenu se
  /// met a l'echelle.
  final AlignmentGeometry alignement;

  /// L'echelle a l'autre bout du passage (la taille du cadre du ruban
  /// rapportee a celle du contenu) ; 1 : un fondu seul.
  final double echelle;

  /// Le contenu.
  final Widget child;

  /// Appele a la fin d'une sortie (ou tout de suite si elle ne se joue pas).
  final VoidCallback? onFini;

  /// La cle de la couche qui porte le passage (tests).
  static const Key cle = ValueKey<String>('passage-visages');

  @override
  State<PassageVisages> createState() => _EtatPassageVisages();
}

class _EtatPassageVisages extends State<PassageVisages>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1,
  );
  bool _reduit = false;
  bool _vu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vu) return;
    _vu = true;
    _reduit = AppMouvement.mouvementReduit(context);
    if (!widget.jouer) {
      if (widget.facon == FaconVisages.sortie) _finir();
      return;
    }
    _c
      ..duration = _reduit ? AppMouvement.fonduEntree : widget.duree
      ..addStatusListener((AnimationStatus s) {
        if (s == AnimationStatus.completed) _finir();
      })
      ..forward(from: 0);
  }

  void _finir() {
    final VoidCallback? fini = widget.onFini;
    if (fini == null) return;
    // Jamais pendant une construction : la fin est signalee apres l'image.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fini();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool sortie = widget.facon == FaconVisages.sortie;
    final Alignment alignement = widget.alignement.resolve(
      Directionality.maybeOf(context) ?? TextDirection.ltr,
    );
    // La meme structure a chaque image : le contenu n'est jamais remonte.
    final Widget passage = AnimatedBuilder(
      key: PassageVisages.cle,
      animation: _c,
      child: widget.child,
      builder: (BuildContext context, Widget? enfant) {
        final double v = _c.value;
        final double fondu = AppMouvement.courbeFondu.transform(v);
        final double ressort = AppMouvement.ressortDeplacement.transform(v);
        final double opacite = sortie ? 1 - fondu : fondu;
        final double echelle = _reduit
            ? 1
            : sortie
            ? 1 + (widget.echelle - 1) * ressort
            : widget.echelle + (1 - widget.echelle) * ressort;
        return Opacity(
          opacity: opacite.clamp(0, 1).toDouble(),
          child: Transform.scale(
            scale: echelle,
            alignment: alignement,
            child: enfant,
          ),
        );
      },
    );
    if (!sortie) return passage;
    return IgnorePointer(child: ExcludeSemantics(child: passage));
  }
}
