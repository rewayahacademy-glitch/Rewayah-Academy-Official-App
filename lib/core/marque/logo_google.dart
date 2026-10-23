import 'package:flutter/widgets.dart';

/// Le logo Google, dessine depuis ses traces officiels.
///
/// **Ce fichier est proprietaire de ses couleurs**, au meme titre que
/// `app_palette.dart` l'est des siennes, et `tool/verifier_jetons.dart` le
/// connait par son chemin. Ce ne sont pas des jetons du produit : ce sont les
/// couleurs d'une marque tierce. Elles ne se declinent pas, ne suivent pas le
/// theme clair/sombre, et **ne se miroitent pas en RTL**
/// (`docs/archive/2026-09-pre-remise-a-plat/design/06-accessibilite.md` section 5, « ne se miroitent pas : [...]
/// les logos »). Le logo se pose tel quel ou pas du tout.
///
/// Les quatre traces sont recopies **mot pour mot** de la ressource officielle
/// Google, dans sa boite de 48 x 48. Ils restent des chaines, lues par
/// [_cheminDepuis], plutot que convertis a la main en appels `Path` : une
/// conversion manuelle ne serait plus comparable a la source, donc
/// invarifiable. Sous cette forme, une relecture suffit.
class LogoGoogle extends StatelessWidget {
  /// Cree le logo.
  const LogoGoogle({super.key, this.taille = 20});

  /// Le cote du carre qui porte le logo, en points logiques.
  final double taille;

  @override
  Widget build(BuildContext context) {
    // Decoratif : le libelle du bouton dit deja « Google ». Le laisser
    // semantique ferait lire le mot deux fois de suite au lecteur d'ecran.
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: taille,
        child: CustomPaint(painter: _PeintreLogoGoogle()),
      ),
    );
  }
}

/// Le cote de la boite dans laquelle les traces officiels sont exprimes.
const double _boite = 48;

/// Les quatre traces officiels, et la couleur de chacun.
const List<(String, Color)> _traces = <(String, Color)>[
  // Bleu.
  (
    'M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 5.08-4.39 '
        '6.64v5.52h7.11c4.16-3.83 6.56-9.47 6.56-16.17z',
    Color(0xFF4285F4),
  ),
  // Vert.
  (
    'M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 2.1-7.45 '
        '2.1-5.73 0-10.58-3.87-12.31-9.07H4.34v5.7C7.96 41.07 15.4 46 24 46z',
    Color(0xFF34A853),
  ),
  // Jaune.
  (
    'M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34C2.85 '
        '17.09 2 20.45 2 24s.85 6.91 2.34 9.88l7.35-5.7z',
    Color(0xFFFBBC05),
  ),
  // Rouge.
  (
    'M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 24 2 '
        '15.4 2 7.96 6.93 4.34 14.12l7.35 5.7c1.73-5.2 6.58-9.07 12.31-9.07z',
    Color(0xFFEA4335),
  ),
];

class _PeintreLogoGoogle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double echelle = size.shortestSide / _boite;
    canvas.save();
    canvas.scale(echelle);
    for (final (String donnees, Color couleur) in _traces) {
      canvas.drawPath(
        _cheminDepuis(donnees),
        Paint()
          ..color = couleur
          ..isAntiAlias = true,
      );
    }
    canvas.restore();
  }

  // Les traces sont des constantes : rien ne change jamais d'une image a
  // l'autre.
  @override
  bool shouldRepaint(_PeintreLogoGoogle ancien) => false;
}

/// Un jeton de trace : soit une lettre de commande, soit un nombre.
///
/// Le signe moins fait office de separateur dans les donnees officielles
/// (`0-1.56-.14`), et un nombre peut s'ecrire sans son zero de tete (`.69`) :
/// c'est pourquoi la lecture se fait par balayage et non par `split`.
final RegExp _jeton = RegExp(
  r'[MmLlHhVvCcSsZz]|-?\d*\.?\d+(?:[eE][-+]?\d+)?',
);

final RegExp _lettre = RegExp(r'^[MmLlHhVvCcSsZz]$');

/// Construit un [Path] a partir des donnees `d` d'un trace SVG.
///
/// Ne couvre que les commandes que les traces de Google emploient
/// reellement : `M L H V C S Z`, absolues et relatives. **Pas d'arcs, pas de
/// quadratiques** : il n'y en a aucun dans la source, et accepter une commande
/// qu'on ne sait pas dessiner produirait un logo faux en silence. Toute
/// commande inconnue leve.
Path _cheminDepuis(String donnees) {
  final Path chemin = Path();
  final List<String> jetons = _jeton
      .allMatches(donnees)
      .map((RegExpMatch m) => m.group(0)!)
      .toList();

  double x = 0;
  double y = 0;
  double xDepart = 0;
  double yDepart = 0;
  // Le second point de controle du dernier cubique, pour la reflexion de `S`.
  double? xControle;
  double? yControle;
  String commande = '';
  int i = 0;

  double suivant() => double.parse(jetons[i++]);

  while (i < jetons.length) {
    if (_lettre.hasMatch(jetons[i])) {
      commande = jetons[i];
      i++;
      if (commande.toUpperCase() == 'Z') {
        chemin.close();
        x = xDepart;
        y = yDepart;
        xControle = null;
        yControle = null;
        continue;
      }
    }

    final bool relatif = commande == commande.toLowerCase();
    final double ancreX = relatif ? x : 0;
    final double ancreY = relatif ? y : 0;

    switch (commande.toUpperCase()) {
      case 'M':
        x = ancreX + suivant();
        y = ancreY + suivant();
        chemin.moveTo(x, y);
        xDepart = x;
        yDepart = y;
        xControle = null;
        yControle = null;
        // Repeter un `M` revient a tracer des lignes, pas a redeplacer.
        commande = relatif ? 'l' : 'L';
      case 'L':
        x = ancreX + suivant();
        y = ancreY + suivant();
        chemin.lineTo(x, y);
        xControle = null;
        yControle = null;
      case 'H':
        x = ancreX + suivant();
        chemin.lineTo(x, y);
        xControle = null;
        yControle = null;
      case 'V':
        y = ancreY + suivant();
        chemin.lineTo(x, y);
        xControle = null;
        yControle = null;
      case 'C':
        final double x1 = ancreX + suivant();
        final double y1 = ancreY + suivant();
        final double x2 = ancreX + suivant();
        final double y2 = ancreY + suivant();
        x = ancreX + suivant();
        y = ancreY + suivant();
        chemin.cubicTo(x1, y1, x2, y2, x, y);
        xControle = x2;
        yControle = y2;
      case 'S':
        // Le premier point de controle est le reflet du precedent autour du
        // point courant. Sans cubique avant, il se confond avec lui.
        final double x1 = xControle == null ? x : 2 * x - xControle;
        final double y1 = yControle == null ? y : 2 * y - yControle;
        final double x2 = ancreX + suivant();
        final double y2 = ancreY + suivant();
        x = ancreX + suivant();
        y = ancreY + suivant();
        chemin.cubicTo(x1, y1, x2, y2, x, y);
        xControle = x2;
        yControle = y2;
      default:
        throw FormatException('commande de trace inconnue', commande);
    }
  }

  return chemin;
}
