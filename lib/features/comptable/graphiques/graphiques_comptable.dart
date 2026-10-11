// Les graphiques du Comptable (COMPTA-GRAPH-1, decision du directeur du
// 11/10 qui leve DR-09 ; maquettes FIN-CPT-W01 a W06, M01 a M03).
//
// Dessines en `CustomPainter` (aucune dependance de graphique), avec les
// couleurs des jetons existants seulement (`AppPalette`, aucune couleur
// litterale). Trois regles tiennent ensemble :
//
// - **les montants masques masquent aussi le dessin** : la forme d'une barre
//   ou d'une courbe dit le montant aussi surement que le chiffre. Masques,
//   les graphiques ne sont pas dessines, une phrase le dit (meme principe
//   que `JaugeSensible`, CPT-DIR-2) ;
// - **jamais la couleur seule** : chaque serie a sa legende ecrite, et
//   chaque graphique a son alternative accessible, le tableau des valeurs
//   (`TableauValeurs`), dont les montants se masquent comme les autres ;
// - **le lecteur d'ecran lit le resume** que l'ecran donne, pas le dessin.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/comptable/visibilite_montants.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/montant_sensible.dart';

/// Les couleurs des graphiques, prises dans les jetons existants.
class CouleursGraphiques {
  const CouleursGraphiques._(
    this.categories,
    this.entrees,
    this.sorties,
    this.axe,
  );

  /// Les couleurs de l'anneau, une par part, dans l'ordre.
  final List<Color> categories;

  /// La couleur des entrees et des encaissements.
  final Color entrees;

  /// La couleur des sorties et des decaissements.
  final Color sorties;

  /// La couleur des axes et de la grille.
  final Color axe;

  /// Lit les couleurs du theme courant.
  factory CouleursGraphiques.de(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return CouleursGraphiques._(
      <Color>[
        p.surfacePrimary.background,
        p.surfaceSuccess.background,
        p.surfaceWarning.background,
        p.surfaceAlert.background,
        p.surfaceInverse.background,
        p.surfaceMiseEnAvant.background,
        p.surfaceQuran.background,
      ],
      p.surfaceSuccess.background,
      p.surfaceAlert.background,
      p.borderResting.asBorderSide().color,
    );
  }
}

/// Un graphique et son alternative accessible.
///
/// Montants affiches : le [dessin], sa [legende] et, sous « Voir les
/// valeurs », le [tableau]. Montants masques : une phrase a la place du
/// dessin (le tableau, lui, reste lisible, ses montants etant masques un a
/// un).
class GraphiqueSensible extends ConsumerStatefulWidget {
  /// Cree le graphique.
  const GraphiqueSensible({
    required this.titre,
    required this.resume,
    required this.dessin,
    required this.tableau,
    super.key,
    this.legende,
    this.hauteur = 160,
  });

  /// Le titre du graphique.
  final String titre;

  /// Ce que lit le lecteur d'ecran a la place du dessin.
  final String resume;

  /// Le dessin, ou `null` quand il n'y a rien a dessiner.
  final Widget dessin;

  /// Les series nommees, avec leur couleur, ecrites sous le dessin.
  final Widget? legende;

  /// L'alternative accessible : le tableau des valeurs.
  final Widget tableau;

  /// La hauteur du dessin.
  final double hauteur;

  @override
  ConsumerState<GraphiqueSensible> createState() => _GraphiqueSensibleEtat();
}

class _GraphiqueSensibleEtat extends ConsumerState<GraphiqueSensible> {
  bool _valeurs = false;

  @override
  Widget build(BuildContext context) {
    final bool affiche = ref.watch(visibiliteMontantsProvider);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final g = t.comptable.graphiques;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              widget.titre,
              style: palette.inkStrong.applyTo(
                textes.titleSmall ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vMd,
          if (affiche) ...<Widget>[
            Semantics(
              label: widget.resume,
              excludeSemantics: true,
              child: SizedBox(
                key: const ValueKey<String>('graphique-dessin'),
                height: widget.hauteur,
                child: widget.dessin,
              ),
            ),
            if (widget.legende != null) ...<Widget>[Ecart.vMd, widget.legende!],
          ] else
            Semantics(
              label: t.comptable.commun.montantMasque,
              excludeSemantics: true,
              child: Container(
                key: const ValueKey<String>('graphique-masque'),
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: palette.surfaceSunken.decoration(),
                child: Text(
                  g.masque,
                  textAlign: TextAlign.center,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            ),
          Ecart.vSm,
          LienFleche(
            key: const ValueKey<String>('graphique-valeurs-lien'),
            libelle: _valeurs ? g.masquerValeurs : g.voirValeurs,
            alignerEnDebut: true,
            onPress: () => setState(() => _valeurs = !_valeurs),
          ),
          if (_valeurs) ...<Widget>[Ecart.vSm, widget.tableau],
        ],
      ),
    );
  }
}

/// Une entree de legende : la couleur et son mot.
class LegendeGraphique extends StatelessWidget {
  /// Cree la legende.
  const LegendeGraphique({required this.entrees, super.key});

  /// Les couples couleur et libelle.
  final List<(Color, String)> entrees;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final (Color couleur, String libelle) in entrees)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExcludeSemantics(
                child: SizedBox(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  child: ColoredBox(color: couleur),
                ),
              ),
              Ecart.hXs,
              Flexible(child: Text(libelle, style: style)),
            ],
          ),
      ],
    );
  }
}

/// L'alternative accessible : une ligne par point, ses valeurs en dessous.
/// Les montants se masquent comme partout ailleurs.
class TableauValeurs extends StatelessWidget {
  /// Cree le tableau.
  const TableauValeurs({required this.lignes, super.key});

  /// Les lignes : un titre et des valeurs nommees.
  final List<LigneValeurs> lignes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey<String>('graphique-tableau'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.md,
      children: <Widget>[
        for (final LigneValeurs ligne in lignes)
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xs,
              children: <Widget>[
                Text(
                  ligne.titre,
                  style: palette.inkStrong.applyTo(
                    textes.labelLarge ?? const TextStyle(),
                  ),
                ),
                // Le nom au-dessus du montant : au texte agrandi, ils ne se
                // disputent pas la largeur.
                for (final (String cle, Montant montant) in ligne.valeurs)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        cle,
                        style: palette.inkMuted.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      ),
                      MontantSensible(montant),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Une ligne du tableau des valeurs.
class LigneValeurs {
  /// Cree la ligne.
  const LigneValeurs(this.titre, this.valeurs);

  /// Le titre (un mois, un jour, un coffre).
  final String titre;

  /// Les valeurs : le nom de la serie et son montant.
  final List<(String, Montant)> valeurs;
}

/// L'anneau de repartition (les coffres).
class AnneauRepartition extends StatelessWidget {
  /// Cree l'anneau. [valeurs] et [couleurs] ont la meme longueur.
  const AnneauRepartition({
    required this.valeurs,
    required this.couleurs,
    super.key,
  });

  /// La grandeur de chaque part, positive ou nulle.
  final List<double> valeurs;

  /// La couleur de chaque part.
  final List<Color> couleurs;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(
      painter: _PeintreAnneau(
        valeurs: valeurs,
        couleurs: couleurs,
        fond: CouleursGraphiques.de(context).axe,
        separation: AppPalette.of(context).surfaceRaised.background,
      ),
    ),
  );
}

class _PeintreAnneau extends CustomPainter {
  _PeintreAnneau({
    required this.valeurs,
    required this.couleurs,
    required this.fond,
    required this.separation,
  });

  final List<double> valeurs;
  final List<Color> couleurs;
  final Color fond;
  final Color separation;

  @override
  void paint(Canvas canvas, Size size) {
    final double cote = math.min(size.width, size.height);
    final double epaisseur = cote / 5;
    final Rect cadre = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: cote - epaisseur,
      height: cote - epaisseur,
    );
    final Paint trait = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = epaisseur;
    final double total = valeurs.fold<double>(0, (double s, double v) => s + v);
    if (total <= 0) {
      canvas.drawArc(cadre, 0, 2 * math.pi, false, trait..color = fond);
      return;
    }
    double debut = -math.pi / 2;
    for (int i = 0; i < valeurs.length; i++) {
      final double balayage = 2 * math.pi * valeurs[i] / total;
      if (balayage <= 0) continue;
      canvas.drawArc(
        cadre,
        debut,
        balayage,
        false,
        trait..color = couleurs[i % couleurs.length],
      );
      // Un filet entre deux parts : deux couleurs voisines se distinguent
      // sans la teinte seule.
      canvas.drawArc(
        cadre,
        debut,
        0.01,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = epaisseur
          ..color = separation,
      );
      debut += balayage;
    }
  }

  @override
  bool shouldRepaint(_PeintreAnneau ancien) =>
      ancien.valeurs != valeurs ||
      ancien.couleurs != couleurs ||
      ancien.fond != fond;
}

/// Deux barres par periode : les entrees et les sorties.
class BarresPeriodes extends StatelessWidget {
  /// Cree les barres. [entrees] et [sorties] ont la meme longueur.
  const BarresPeriodes({
    required this.entrees,
    required this.sorties,
    super.key,
    this.debut,
    this.fin,
  });

  /// Les entrees de chaque periode.
  final List<double> entrees;

  /// Les sorties de chaque periode.
  final List<double> sorties;

  /// Le mot de la premiere periode, sous les barres.
  final String? debut;

  /// Le mot de la derniere periode, sous les barres.
  final String? fin;

  @override
  Widget build(BuildContext context) {
    final CouleursGraphiques c = CouleursGraphiques.de(context);
    final TextStyle style = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.labelSmall ?? const TextStyle());
    return Column(
      children: <Widget>[
        Expanded(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _PeintreBarres(
                entrees: entrees,
                sorties: sorties,
                couleurEntrees: c.entrees,
                couleurSorties: c.sorties,
                axe: c.axe,
              ),
            ),
          ),
        ),
        if (debut != null || fin != null) ...<Widget>[
          Ecart.vXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text(debut ?? '', style: style)),
              Flexible(child: Text(fin ?? '', style: style)),
            ],
          ),
        ],
      ],
    );
  }
}

class _PeintreBarres extends CustomPainter {
  _PeintreBarres({
    required this.entrees,
    required this.sorties,
    required this.couleurEntrees,
    required this.couleurSorties,
    required this.axe,
  });

  final List<double> entrees;
  final List<double> sorties;
  final Color couleurEntrees;
  final Color couleurSorties;
  final Color axe;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = entrees.length;
    if (n == 0) return;
    final double haut = <double>[...entrees, ...sorties, 1].reduce(math.max);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = axe
        ..strokeWidth = 1,
    );
    final double colonne = size.width / n;
    final double barre = colonne / 3;
    for (int i = 0; i < n; i++) {
      final double x = i * colonne + barre / 2;
      for (final (int rang, double v, Color couleur) in <(int, double, Color)>[
        (0, entrees[i], couleurEntrees),
        (1, i < sorties.length ? sorties[i] : 0, couleurSorties),
      ]) {
        final double h = v <= 0 ? 0 : size.height * v / haut;
        canvas.drawRect(
          Rect.fromLTWH(x + rang * barre, size.height - h, barre, h),
          Paint()..color = couleur,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PeintreBarres ancien) =>
      ancien.entrees != entrees ||
      ancien.sorties != sorties ||
      ancien.couleurEntrees != couleurEntrees ||
      ancien.couleurSorties != couleurSorties;
}

/// Une ou deux courbes sur une meme echelle (flux sur trente jours,
/// evolution sur six mois).
class CourbesTemporelles extends StatelessWidget {
  /// Cree les courbes. Les [series] ont la meme longueur.
  const CourbesTemporelles({
    required this.series,
    required this.couleurs,
    super.key,
    this.debut,
    this.fin,
  });

  /// Les valeurs de chaque courbe, du plus ancien au plus recent.
  final List<List<double>> series;

  /// La couleur de chaque courbe.
  final List<Color> couleurs;

  /// Le mot du premier point, sous la courbe.
  final String? debut;

  /// Le mot du dernier point, sous la courbe.
  final String? fin;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.labelSmall ?? const TextStyle());
    return Column(
      children: <Widget>[
        Expanded(
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _PeintreCourbes(
                series: series,
                couleurs: couleurs,
                axe: CouleursGraphiques.de(context).axe,
              ),
            ),
          ),
        ),
        if (debut != null || fin != null) ...<Widget>[
          Ecart.vXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: Text(debut ?? '', style: style)),
              Flexible(child: Text(fin ?? '', style: style)),
            ],
          ),
        ],
      ],
    );
  }
}

class _PeintreCourbes extends CustomPainter {
  _PeintreCourbes({
    required this.series,
    required this.couleurs,
    required this.axe,
  });

  final List<List<double>> series;
  final List<Color> couleurs;
  final Color axe;

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> tous = <double>[
      for (final List<double> s in series) ...s,
    ];
    if (tous.isEmpty) return;
    final double bas = math.min(0, tous.reduce(math.min));
    final double haut = math.max(tous.reduce(math.max), bas + 1);
    double y(double v) => size.height - size.height * (v - bas) / (haut - bas);
    canvas.drawLine(
      Offset(0, y(0)),
      Offset(size.width, y(0)),
      Paint()
        ..color = axe
        ..strokeWidth = 1,
    );
    for (int k = 0; k < series.length; k++) {
      final List<double> s = series[k];
      if (s.isEmpty) continue;
      final Path chemin = Path();
      for (int i = 0; i < s.length; i++) {
        final double x = s.length == 1
            ? size.width / 2
            : size.width * i / (s.length - 1);
        if (i == 0) {
          chemin.moveTo(x, y(s[i]));
        } else {
          chemin.lineTo(x, y(s[i]));
        }
      }
      canvas.drawPath(
        chemin,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = couleurs[k % couleurs.length],
      );
    }
  }

  @override
  bool shouldRepaint(_PeintreCourbes ancien) =>
      ancien.series != series || ancien.couleurs != couleurs;
}

/// Une mini-courbe sans axe, pour un indicateur (Entrees, Sorties).
class MiniCourbe extends StatelessWidget {
  /// Cree la mini-courbe.
  const MiniCourbe({required this.valeurs, required this.couleur, super.key});

  /// Les valeurs, du plus ancien au plus recent.
  final List<double> valeurs;

  /// La couleur du trait.
  final Color couleur;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: AppSpacing.xxxl,
      child: CustomPaint(
        painter: _PeintreCourbes(
          series: <List<double>>[valeurs],
          couleurs: <Color>[couleur],
          axe: couleur.withValues(alpha: 0),
        ),
        size: Size.infinite,
      ),
    ),
  );
}
