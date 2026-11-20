// VIVANT : une phrase qui s'ecrit devant soi, une fois, puis ne bouge plus.
import 'package:flutter/widgets.dart';

import 'ressort.dart';

/// Ecrit [texte] lettre a lettre, puis se tait : au repos, c'est un `Text`
/// ordinaire. Quand [texte] change, la nouvelle phrase s'ecrit a son tour.
///
/// La place est reservee des la premiere image (la suite de la phrase est
/// posee, invisible) : rien ne saute pendant l'ecriture. Le lecteur d'ecran
/// lit toujours la phrase entiere. Sous « Reduire les effets », la phrase
/// est la, entiere, d'emblee.
class TexteQuiSEcrit extends StatefulWidget {
  /// Cree la phrase.
  const TexteQuiSEcrit(
    this.texte, {
    required this.style,
    super.key,
    this.onEcriture,
  });

  /// La phrase.
  final String texte;

  /// Son style (couleur comprise).
  final TextStyle style;

  /// Appele quand l'ecriture commence (vrai) et quand elle finit (faux).
  final ValueChanged<bool>? onEcriture;

  /// Les lettres ecrites par seconde.
  static const double cadence = 70;

  @override
  State<TexteQuiSEcrit> createState() => _EtatTexteQuiSEcrit();
}

class _EtatTexteQuiSEcrit extends State<TexteQuiSEcrit>
    with SingleTickerProviderStateMixin<TexteQuiSEcrit>, VieDesRessorts {
  late Characters _lettres = widget.texte.characters;
  double _ecrites = 0;
  bool _lance = false;
  bool _annonce = false;

  bool get _fini => _ecrites >= _lettres.length;

  @override
  Iterable<Ressort> get ressorts => const <Ressort>[];

  @override
  bool get finiAussi => _fini;

  void _dire({required bool ecrit}) {
    if (_annonce == ecrit) return;
    _annonce = ecrit;
    widget.onEcriture?.call(ecrit);
  }

  void _commencer() {
    if (!mounted) return;
    _ecrites = 0;
    reveil();
    _dire(ecrit: !_fini);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lance) return;
    _lance = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _commencer());
  }

  @override
  void didUpdateWidget(TexteQuiSEcrit ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.texte != widget.texte) {
      _lettres = widget.texte.characters;
      _ecrites = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _commencer());
    }
  }

  @override
  void surPoseSansMouvement() => _ecrites = _lettres.length.toDouble();

  @override
  void surPas(double dt) {
    _ecrites += dt * TexteQuiSEcrit.cadence;
    if (_fini) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dire(ecrit: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fini || !_lance) {
      // Avant la premiere image, la phrase entiere tient la place (et le
      // lecteur d'ecran) ; elle est invisible tant que rien n'est ecrit.
      return Text(
        widget.texte,
        style: _fini ? widget.style : _invisible(widget.style),
      );
    }
    final int n = _ecrites.floor().clamp(0, _lettres.length);
    return Semantics(
      label: widget.texte,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: _lettres.take(n).string),
              TextSpan(
                text: _lettres.skip(n).string,
                style: _invisible(widget.style),
              ),
            ],
          ),
          style: widget.style,
        ),
      ),
    );
  }
}

TextStyle _invisible(TextStyle style) =>
    style.copyWith(color: style.color?.withValues(alpha: 0));
