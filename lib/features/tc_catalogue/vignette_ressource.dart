import 'package:flutter/material.dart';

import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/couverture_ressource.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// La couverture d'une ressource.
///
/// **Ce n'est pas une grille d'icones generiques identiques**, et c'est le
/// seul reproche que la spec adresse nommement a l'existant (section 6.1).
/// Trois axes deterministes la composent : une teinte, un motif, un
/// monogramme -- seize combinaisons, chacune portant deux lettres differentes.
/// La meme ressource a toujours la meme couverture, sur tous les appareils.
///
/// **Aucune couleur n'est posee ici.** Les teintes sortent des paires du
/// theme, qui est READ-ONLY, et le motif est peint dans l'encre de sa propre
/// paire. Une palette de couvertures administree -- l'equivalent de celle des
/// groupes, decision D-18 -- est demandee a Agent Z dans
/// `docs/teaching-core/TC_CONTRACT_REQUEST_B.md`.
///
/// [image] est le point d'entree de la couverture **deposee**, celle que
/// `cover_asset` designe. Elle est fournie par l'appelant et non chargee ici :
/// aucun bucket Storage de supports n'existe, et une vignette qui tenterait de
/// signer une URL inventerait un service.
class VignetteRessource extends StatelessWidget {
  /// Cree une vignette.
  const VignetteRessource({
    required this.couverture,
    super.key,
    this.image,
    this.compacte = false,
  });

  /// La couverture calculee ou deposee.
  final CouvertureRessource couverture;

  /// La couverture deposee, quand l'appelant sait la charger.
  final Widget? image;

  /// Vrai dans une liste dense : le monogramme y passe au registre inferieur.
  final bool compacte;

  /// Le rapport hauteur sur largeur d'une couverture.
  ///
  /// Celui d'un livre, pas un carre : c'est ce qui la rend reconnaissable
  /// comme couverture avant meme qu'on lise son titre.
  static const double rapport = 3 / 4;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = teinte(palette, couverture.indexTeinte);

    return AspectRatio(
      aspectRatio: rapport,
      child: ClipRRect(
        borderRadius: AppRadius.arrondiMd,
        child: DecoratedBox(
          decoration: paire.decoration(borderRadius: AppRadius.arrondiMd),
          // La couverture est decorative : le titre, le type et l'etat hors
          // ligne sont lus a cote par la carte. Un lecteur d'ecran qui
          // epellerait « CO » avant le titre ne dirait rien de plus.
          child: ExcludeSemantics(
            child:
                image ??
                Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CustomPaint(
                      painter: _MotifPeintre(
                        motif: couverture.motif,
                        encre: paire.onBackground,
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: FittedBox(
                          child: Text(
                            couverture.monogramme,
                            style: paire.applyTo(
                              (compacte
                                      ? textes.headlineSmall
                                      : textes.displaySmall) ??
                                  const TextStyle(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: IconTheme(
                          data: IconThemeData(
                            color: paire.onBackground,
                            size: AppSpacing.lg,
                          ),
                          child: Icon(iconeDe(couverture.type).repos),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  /// La paire d'une teinte de couverture.
  ///
  /// L'index 0 est celui du Coran : `surfaceQuran` n'est employee nulle part
  /// ailleurs dans le produit, et un mushaf qui changerait de couleur d'un
  /// catalogue a l'autre perdrait le seul repere qu'un enfant a avant de
  /// savoir lire le titre.
  ///
  /// Les trois autres sont des paires **douces**. Aucune n'est `washAlert` ni
  /// `washWarning` : une couverture n'annonce pas un probleme, et employer le
  /// registre d'alerte pour decorer viderait ce registre de son sens partout
  /// ailleurs.
  static AppColorPair teinte(AppPalette palette, int index) => switch (index) {
    0 => palette.surfaceQuran,
    1 => palette.washAccent,
    2 => palette.washFamily,
    _ => palette.washSuccess,
  };

  /// L'icone de coin d'un type de ressource.
  static AppIcon iconeDe(TypeRessource type) => switch (type) {
    TypeRessource.quran => AppIcons.coran,
    TypeRessource.texteStructure => AppIcons.texteStructure,
    TypeRessource.pdf => AppIcons.fichierPdf,
    TypeRessource.image => AppIcons.image,
    TypeRessource.lecon => AppIcons.lecon,
  };
}

/// Le peintre des quatre motifs.
///
/// Un `CustomPainter` et non quatre assets : quatre images embarquees
/// peseraient sur les 20 Mo que `docs/produit/bibliotheque-contenu.md` fixe a
/// l'application entiere, pour un dessin qui tient en vingt lignes.
class _MotifPeintre extends CustomPainter {
  const _MotifPeintre({required this.motif, required this.encre});

  final MotifCouverture motif;
  final Color encre;

  /// La part de l'encre reprise par le motif.
  ///
  /// Assez pour qu'il se voie, assez peu pour que le monogramme reste le
  /// premier plan : une couverture se lit d'abord, se decore ensuite.
  static const double opaciteMotif = 0.14;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pinceau = Paint()
      ..color = encre.withValues(alpha: opaciteMotif)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide / 40;
    final double pas = size.shortestSide / 5;

    switch (motif) {
      case MotifCouverture.lignes:
        for (double x = -size.height; x < size.width; x += pas) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.height, 0),
            pinceau,
          );
        }
      case MotifCouverture.arcs:
        for (double r = pas; r < size.longestSide; r += pas) {
          canvas.drawCircle(Offset(0, size.height), r, pinceau);
        }
      case MotifCouverture.grille:
        for (double x = pas; x < size.width; x += pas) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), pinceau);
        }
        for (double y = pas; y < size.height; y += pas) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), pinceau);
        }
      case MotifCouverture.points:
        final Paint plein = Paint()
          ..color = encre.withValues(alpha: opaciteMotif);
        for (double x = pas / 2; x < size.width; x += pas) {
          for (double y = pas / 2; y < size.height; y += pas) {
            canvas.drawCircle(Offset(x, y), pinceau.strokeWidth * 2, plein);
          }
        }
    }
  }

  @override
  bool shouldRepaint(_MotifPeintre ancien) =>
      ancien.motif != motif || ancien.encre != encre;
}
