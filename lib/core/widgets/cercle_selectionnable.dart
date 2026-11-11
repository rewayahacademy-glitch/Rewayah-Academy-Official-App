import 'dart:math' as math;

// Le rond d'une photo qui se choisit : le cercle Compte de la barre flottante,
// puis les profils de l'Accueil (decisions du directeur du 10/11/2026,
// relayees par le garde-cap : « la barre est un laboratoire, ce qu'on y
// construit sera reutilise ailleurs »).
//
// Au repos, un rond clair et la photo au centre ; choisi, le rond grandit,
// la photo aussi, et le bord prend la couleur d'accent. Le passage de l'un a
// l'autre suit le ressort de l'application (`AppMouvement.ressort`, sans
// rebond visible) ; sous « reduire les animations », il est immediat. La
// place reservee est celle du rond choisi : rien ne bouge autour.

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_elevation.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';

/// Les mesures d'un [CercleSelectionnable] : le rond et la photo, au repos et
/// choisi.
@immutable
class MesuresCercle {
  /// Cree les mesures.
  const MesuresCercle({
    required this.rondRepos,
    required this.photoRepos,
    required this.rondChoisi,
    required this.photoChoisi,
  }) : assert(photoRepos < rondRepos && photoChoisi < rondChoisi),
       assert(rondRepos <= rondChoisi);

  /// Le cercle Compte de la barre (decision du directeur du 10/11/2026) :
  /// non choisi, un rond de 58 et une photo de 48 (bord de 5) ; choisi, un
  /// rond de 64 et une photo de 52, bord d'accent.
  static const MesuresCercle compte = MesuresCercle(
    rondRepos: 58,
    photoRepos: 48,
    rondChoisi: 64,
    photoChoisi: 52,
  );

  /// Les memes proportions, pour un rond de repos de [rond] (les profils de
  /// l'Accueil : « garde la meme proportion du bord »).
  factory MesuresCercle.proportionnelles(double rond) {
    final double k = rond / compte.rondRepos;
    return MesuresCercle(
      rondRepos: rond,
      photoRepos: compte.photoRepos * k,
      rondChoisi: compte.rondChoisi * k,
      photoChoisi: compte.photoChoisi * k,
    );
  }

  /// Le rond au repos.
  final double rondRepos;

  /// La photo au repos.
  final double photoRepos;

  /// Le rond choisi : aussi la place reservee.
  final double rondChoisi;

  /// La photo choisie.
  final double photoChoisi;
}

/// Un rond de photo qui grandit quand il est choisi, au ressort.
///
/// Purement visuel : le nom lu et le toucher sont portes par le bouton qui
/// l'entoure. [photo] recoit le diametre courant de la photo.
class CercleSelectionnable extends StatefulWidget {
  /// Cree le rond.
  const CercleSelectionnable({
    required this.choisi,
    required this.photo,
    this.mesures = MesuresCercle.compte,
    this.ombre = true,
    this.matiere,
    this.fonduAccent,
    super.key,
  });

  /// LIQUIDE-MATIERE : le fondu de la couleur de selection sur la
  /// destination (0 pendant le detachement, puis 1). Choisi, l'accent
  /// l'attend ; quitte, il disparait des que le fondu retombe a 0. La
  /// taille suit le ressort des le toucher. Nul : l'accent suit la taille.
  final Animation<double>? fonduAccent;

  /// LIQUIDE-MATIERE (directeur, 11/11/2026) : le fond du rond au repos,
  /// celui de la pilule dont il est un morceau (la barre flottante), sans
  /// contour ; la photo garde son fin liseré clair, qui est son bord a elle.
  /// Nul : le fond du rond est lui-meme le liseré (les profils de l'Accueil).
  final Color? matiere;

  /// Vrai quand le rond est choisi (la destination ou le profil ouvert).
  final bool choisi;

  /// Construit la photo au diametre donne.
  final Widget Function(double diametre) photo;

  /// Les mesures du rond.
  final MesuresCercle mesures;

  /// L'ombre douce qui detache le rond du fond (la barre flottante) ; les
  /// profils de l'Accueil, poses sur la page, n'en ont pas.
  final bool ombre;

  @override
  State<CercleSelectionnable> createState() => _EtatCercleSelectionnable();
}

/// L'epaisseur du liseré de la photo, quand le rond est de matiere.
const double _lisere = 1.5;

class _EtatCercleSelectionnable extends State<CercleSelectionnable>
    with SingleTickerProviderStateMixin {
  // 0 : au repos ; 1 : choisi. Sans borne : le ressort ne rebondit pas.
  late final AnimationController _choix = AnimationController.unbounded(
    vsync: this,
    value: widget.choisi ? 1 : 0,
  );

  @override
  void didUpdateWidget(CercleSelectionnable ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.choisi == widget.choisi) return;
    final double cible = widget.choisi ? 1 : 0;
    if (AppMouvement.mouvementReduit(context)) {
      _choix.value = cible;
      return;
    }
    _choix.animateWith(
      SpringSimulation(AppMouvement.ressort, _choix.value, cible, 0),
    );
  }

  @override
  void dispose() {
    _choix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final MesuresCercle m = widget.mesures;
    return SizedBox.square(
      dimension: m.rondChoisi,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable?>[
            _choix,
            widget.fonduAccent,
          ]),
          builder: (BuildContext context, Widget? _) {
            final double t = _choix.value.clamp(0, 1).toDouble();
            final double rond = m.rondRepos + (m.rondChoisi - m.rondRepos) * t;
            final double photo =
                m.photoRepos + (m.photoChoisi - m.photoRepos) * t;
            // Le bord : clair au repos (le fin liseré blanc), accent choisi.
            final Color clair =
                widget.matiere ?? palette.lisereClair(epaisseur: 1).color;
            final Color accent = palette.inkAccent.asBorderSide().color;
            // Choisi : la couleur attend la rupture du cou (le fondu), la
            // taille non. Quitte : la couleur part des le toucher, pour que
            // le rond rejoigne la pilule en simple matiere.
            final Animation<double>? fondu = widget.fonduAccent;
            final double tCouleur = fondu != null
                ? math.min(t, fondu.value)
                : t;
            return DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(clair, accent, tCouleur),
                boxShadow: widget.ombre
                    ? AppElevation.niveau1(palette.ombre)
                    : null,
              ),
              child: SizedBox.square(
                dimension: rond,
                child: Center(
                  child: widget.matiere == null
                      ? widget.photo(photo)
                      : DecoratedBox(
                          // Le liseré de la photo : son bord, pas la matiere.
                          position: DecorationPosition.foreground,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              palette.lisereClair(epaisseur: _lisere),
                            ),
                          ),
                          child: widget.photo(photo),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
