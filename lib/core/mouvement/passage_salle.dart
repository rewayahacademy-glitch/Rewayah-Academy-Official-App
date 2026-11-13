// TRANSITIONS-SALLE (directeur, 11/11/2026) : les passages d'un ecran de la
// salle a l'autre (l'arche passe la main, la sortie, le retour depuis
// l'ile), et le fondu d'un support a l'autre.
//
// Regle commune : **aucun passage ne retarde rien**. Le nouvel ecran est
// construit et utilisable des la premiere image ; le passage ne fait que
// peindre par-dessus (un voile qui ne recoit aucun geste) ou regler son
// opacite (qui n'empeche aucun geste). Rien ne se joue au premier montage,
// sauf l'arrivee demandee ([PassageSalle.arrivee]).

import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';

/// La facon de passer d'une etape de la salle a la suivante.
enum FaconPassage {
  /// Aucun mouvement : la nouvelle etape est la, d'un coup.
  aucune,

  /// L'arche passe la main : un voile sombre ([AppPalette.coucheSalle])
  /// s'efface en [AppMouvement.passageArche] sur la salle deja prete.
  voile,

  /// Un fondu court ([AppMouvement.sortieSalle]) : la sortie, volontaire ou
  /// subie. Aucun moment de marque.
  fondu,

  /// La salle se redeplie depuis l'ile, en haut de l'ecran : un leger
  /// agrandissement ([AppMouvement.echelleVersIle]) sur le ressort sans
  /// rebond, et un fondu. En mouvement reduit, le fondu seul.
  depuisIle,
}

/// Les etapes d'un meme ecran de salle ([child]), et le passage de l'une a
/// l'autre.
class PassageSalle extends StatefulWidget {
  /// Cree le passage.
  const PassageSalle({
    required this.etape,
    required this.child,
    this.choisir,
    this.arrivee = FaconPassage.aucune,
    super.key,
  });

  /// L'etape affichee (comparee par `==`).
  final Object etape;

  /// Le passage a jouer quand l'etape change ; `null` : aucun.
  final FaconPassage Function(Object avant, Object apres)? choisir;

  /// Le passage joue une seule fois, au montage (le retour depuis l'ile).
  final FaconPassage arrivee;

  /// L'ecran.
  final Widget child;

  /// La cle du voile de l'arche (tests).
  static const Key cleVoile = ValueKey<String>('passage-salle-voile');

  @override
  State<PassageSalle> createState() => _EtatPassageSalle();
}

class _EtatPassageSalle extends State<PassageSalle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1,
  );
  FaconPassage _facon = FaconPassage.aucune;
  bool _arriveeVue = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _facon = FaconPassage.aucune);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arriveeVue) return;
    _arriveeVue = true;
    if (widget.arrivee != FaconPassage.aucune) _jouer(widget.arrivee);
  }

  @override
  void didUpdateWidget(PassageSalle ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.etape == widget.etape) return;
    final FaconPassage facon =
        widget.choisir?.call(ancien.etape, widget.etape) ?? FaconPassage.aucune;
    if (facon != FaconPassage.aucune) _jouer(facon);
  }

  void _jouer(FaconPassage facon) {
    final bool reduit = AppMouvement.mouvementReduit(context);
    _facon = facon == FaconPassage.depuisIle && reduit
        ? FaconPassage.fondu
        : facon;
    _c.duration = switch (_facon) {
      FaconPassage.voile => AppMouvement.passageArche,
      FaconPassage.depuisIle => AppMouvement.deplacementEntree,
      FaconPassage.fondu || FaconPassage.aucune => AppMouvement.sortieSalle,
    };
    // Interrompu : le nouveau passage repart de zero, l'ancien s'arrete.
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FaconPassage facon = _facon;
    // La meme structure a chaque image : l'ecran n'est jamais remonte par
    // le passage.
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        AnimatedBuilder(
          animation: _c,
          child: widget.child,
          builder: (BuildContext context, Widget? enfant) {
            final double v = _c.value;
            final double opacite = switch (facon) {
              FaconPassage.fondu ||
              FaconPassage.depuisIle => AppMouvement.courbeFondu.transform(v),
              FaconPassage.voile || FaconPassage.aucune => 1,
            };
            final double echelle = facon == FaconPassage.depuisIle
                ? AppMouvement.echelleVersIle +
                      (1 - AppMouvement.echelleVersIle) *
                          AppMouvement.ressortDeplacement.transform(v)
                : 1;
            return Opacity(
              opacity: opacite,
              child: Transform.scale(
                scale: echelle,
                alignment: Alignment.topCenter,
                child: enfant,
              ),
            );
          },
        ),
        if (facon == FaconPassage.voile)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (BuildContext context, Widget? _) => Opacity(
                    opacity: 1 - AppMouvement.courbeFondu.transform(_c.value),
                    child: DecoratedBox(
                      key: PassageSalle.cleVoile,
                      decoration: AppPalette.of(context).coucheSalle
                          .decoration(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Un fondu court quand [cle] change (un support en remplace un autre) :
/// le nouveau contenu apparait en [AppMouvement.fonduEntree], sans jamais
/// se superposer a l'ancien (les deux textes ne se melent pas, LG-FLASH).
/// Rien au premier montage ; rien sous « reduire les animations ».
class FonduAuChangement extends StatefulWidget {
  /// Cree le fondu.
  const FonduAuChangement({required this.cle, required this.child, super.key});

  /// L'identite du contenu (comparee par `==`).
  final Object cle;

  /// Le contenu.
  final Widget child;

  @override
  State<FonduAuChangement> createState() => _EtatFonduAuChangement();
}

class _EtatFonduAuChangement extends State<FonduAuChangement>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1,
    duration: AppMouvement.fonduEntree,
  );
  late final CurvedAnimation _opacite = CurvedAnimation(
    parent: _c,
    curve: AppMouvement.courbeFondu,
  );

  @override
  void didUpdateWidget(FonduAuChangement ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.cle != widget.cle && !AppMouvement.mouvementReduit(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _opacite.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacite, child: widget.child);
}
