// VIVANT : un nombre qui change en roulant, comme un compteur a rouleaux.
import 'package:flutter/widgets.dart';

import '../theme/app_typography.dart';
import 'ressort.dart';

/// Affiche [valeur] ; quand elle change, l'ancienne sort par le haut et la
/// nouvelle monte, en ressort, puis tout se tait.
///
/// Chiffres tabulaires : la largeur ne tremble pas pendant le passage. Le
/// lecteur d'ecran ne lit que la valeur courante.
class NombreRouleaux extends StatefulWidget {
  /// Cree le compteur.
  const NombreRouleaux(
    this.valeur, {
    required this.style,
    super.key,
    this.miseEnForme,
  });

  /// Le nombre affiche.
  final int valeur;

  /// Son style (couleur comprise).
  final TextStyle style;

  /// Comment ecrire le nombre (un separateur de milliers, par exemple). Nul :
  /// le nombre brut, comme avant.
  final String Function(int valeur)? miseEnForme;

  String _ecrire(int v) => miseEnForme?.call(v) ?? '$v';

  @override
  State<NombreRouleaux> createState() => _EtatNombreRouleaux();
}

class _EtatNombreRouleaux extends State<NombreRouleaux>
    with SingleTickerProviderStateMixin<NombreRouleaux>, VieDesRessorts {
  final Ressort _passage = Ressort(1, raideur: 260, frein: 17);
  int? _ancienne;

  @override
  Iterable<Ressort> get ressorts => <Ressort>[_passage];

  @override
  void didUpdateWidget(NombreRouleaux ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.valeur != widget.valeur) {
      _ancienne = ancien.valeur;
      _passage
        ..x = 0
        ..v = 0
        ..cible = 1;
      reveil();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.tabulaire(widget.style);
    final double p = _passage.x;
    final Widget courant = Text(
      widget._ecrire(widget.valeur),
      style: style,
      maxLines: 1,
    );
    if (!enMouvement || _ancienne == null) return courant;
    return ClipRect(
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: <Widget>[
          ExcludeSemantics(
            child: FractionalTranslation(
              translation: Offset(0, -p),
              child: Opacity(
                opacity: (1 - p).clamp(0, 1),
                child: Text(
                  widget._ecrire(_ancienne!),
                  style: style,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          FractionalTranslation(
            translation: Offset(0, 1 - p),
            child: Opacity(opacity: p.clamp(0, 1), child: courant),
          ),
        ],
      ),
    );
  }
}
