// PE-B5 (directeur, 19/11/2026 : la barre d'etapes de la maquette est « tres
// ordinaire » ; « la meilleure interface et une logique qui ne cache rien font
// 80 % de la confiance ») : la ligne des trois etapes du candidat.
//
// Trois capsules, comme la maquette, mais vivantes : ce qui est fait est
// plein ; la capsule de l'etape en cours se remplit, en ressort, de la part
// deja faite du dossier ; ce qui vient est vide. Chaque capsule se touche
// (elle s'enfonce et revient) : elle dit alors ce qui s'y passe. A cote de
// la position, l'etat de la candidature (pilote, 20/11/2026 : aucun second
// titre, aucun cercle numerote). Rien n'est cache, rien n'est devine : le rang vient de l'etape
// que le serveur rend, la part des lignes du dossier.
//
// Mouvement : a l'arrivee, les traits se remplissent en ressort depuis le
// debut, puis tout se tait. Sous « Reduire les effets », la ligne est posee
// d'emblee, entiere.
import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/vivant/ressort.dart';
import '../../core/vivant/toucher_vivant.dart';
import 'onglet_dossier.dart' show Depliant;
import 'portail_candidature.dart'
    show EnteteSalle, StatutCandidature, sallesDuCandidat;

/// La ligne des etapes du candidat.
class LigneEtapes extends StatefulWidget {
  /// Cree la ligne. [rang] : l'etape en cours, de 1 a 3. [part] : la part
  /// deja faite de l'etape en cours, de 0 a 1. [fermee] : la candidature
  /// n'avance plus (refus, retrait) : la ligne dit ou elle s'est arretee,
  /// sans accent.
  const LigneEtapes({
    required this.rang,
    required this.part,
    super.key,
    this.fermee = false,
    this.etat,
  });

  /// L'etape en cours, de 1 a [sallesDuCandidat].
  final int rang;

  /// La part faite de l'etape en cours.
  final double part;

  /// Vrai quand la candidature n'avance plus.
  final bool fermee;

  /// L'etat de la candidature, en quelques mots (« Votre candidature est
  /// envoyee »), dit a cote de la position tant qu'aucune autre etape n'est
  /// touchee ; `null` : le nom de l'etape.
  final String? etat;

  /// La cle de la station [i] (de 1 a 3).
  static Key cleStation(int i) => ValueKey<String>('etape-station-$i');

  /// La cle de la phrase qui dit ce qui se passe a l'etape touchee.
  static const Key cleDetail = ValueKey<String>('etape-detail');

  /// L'epaisseur du trait.
  static const double trait = AppSpacing.sm;

  /// La part du trait que l'etape en cours peut remplir au plus.
  static const double partMaximale = 0.85;

  /// Le nom de l'etape [i], dans les mots du candidat.
  static String nom(int i) => switch (i) {
    1 => t.recrutement.sallesCandidat.candidature,
    2 => t.recrutement.sallesCandidat.connaissance,
    _ => t.recrutement.sallesCandidat.equipe,
  };

  /// Ce qui se passe a l'etape [i].
  static String detail(int i) => switch (i) {
    1 => t.recrutement.accueil.etapes.detail1,
    2 => t.recrutement.accueil.etapes.detail2,
    _ => t.recrutement.accueil.etapes.detail3,
  };

  @override
  State<LigneEtapes> createState() => _EtatLigneEtapes();
}

class _EtatLigneEtapes extends State<LigneEtapes>
    with SingleTickerProviderStateMixin<LigneEtapes>, VieDesRessorts {
  // L'avancement dessine : de 0 a [_cible], en longueurs de trait (0 a 2).
  final Ressort _avance = Ressort(0, raideur: 90, frein: 13);
  // La station en cours gonfle a l'arrivee, puis se pose.
  final Ressort _gonfle = Ressort(1, raideur: 260, frein: 12);
  bool _lance = false;

  /// L'etape dont le detail est montre ; l'etape en cours par defaut.
  late int _montree = widget.rang;

  // Vrai des qu'une etape a ete touchee : son detail se deplie alors.
  bool _touchee = false;

  @override
  Iterable<Ressort> get ressorts => <Ressort>[_avance, _gonfle];

  /// Le trait de l'etape en cours ne touche jamais la station suivante : on
  /// n'y est pas tant que le serveur ne le dit pas.
  double get _cible =>
      (widget.rang - 1) +
      widget.part.clamp(0, 1).toDouble() * LigneEtapes.partMaximale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lance) return;
    _lance = true;
    _avance.cible = _cible;
    _gonfle
      ..x = 0.7
      ..cible = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) => reveil());
  }

  @override
  void didUpdateWidget(LigneEtapes ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.rang != widget.rang) _montree = widget.rang;
    if (ancien.rang != widget.rang || ancien.part != widget.part) {
      _avance.cible = _cible;
      if (ancien.rang != widget.rang) {
        _gonfle
          ..x = 0.7
          ..cible = 1;
      }
      reveil();
    }
  }

  void _montrer(int i) {
    setState(() {
      // Retoucher l'etape montree replie son detail.
      _touchee = !(_touchee && _montree == i);
      _montree = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.recrutement.accueil.etapes;
    final String position = e.position(n: widget.rang, total: sallesDuCandidat);
    final Color plein = widget.fermee
        ? palette.borderStrong.asBorderSide().color
        : palette.surfacePrimary.background;
    final Color vide = palette.borderHairline.asBorderSide().color;
    // A cote de la position : l'etat de la candidature ; une autre etape
    // touchee dit son nom.
    final String? etat = widget.etat;
    final bool ditEtat = etat != null && _montree == widget.rang;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int i = 1; i <= sallesDuCandidat; i++) ...<Widget>[
              if (i > 1) Ecart.hSm,
              Expanded(
                child: _Segment(
                  key: LigneEtapes.cleStation(i),
                  rang: i,
                  enCours: i == widget.rang,
                  faite: i < widget.rang,
                  montree: _touchee && i == _montree,
                  echelle: i == widget.rang ? _gonfle.x : 1,
                  // La part pleine du segment [i] : il se remplit en ressort.
                  rempli: (_avance.x - (i - 1)).clamp(0, 1).toDouble(),
                  plein: plein,
                  vide: vide,
                  onPress: () => _montrer(i),
                ),
              ),
            ],
          ],
        ),
        // « Etape 1 sur 3 · Votre candidature est a completer ».
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          children: <Widget>[
            Text(
              e.position(n: _montree, total: sallesDuCandidat),
              key: EnteteSalle.rangKey,
              semanticsLabel: _montree == widget.rang ? position : null,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Semantics(
              header: ditEtat,
              child: Text(
                ditEtat ? etat : LigneEtapes.nom(_montree),
                key: ditEtat
                    ? StatutCandidature.titreKey
                    : _montree == widget.rang
                    ? EnteteSalle.salleKey
                    : null,
                style: palette.inkStrong.applyTo(
                  textes.titleSmall ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
        // Ce qui se passe a l'etape touchee : une ligne, qui se deplie.
        Depliant(
          child: _touchee
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    ditEtat
                        ? '${LigneEtapes.nom(_montree)}. '
                              '${LigneEtapes.detail(_montree)}'
                        : LigneEtapes.detail(_montree),
                    key: LigneEtapes.cleDetail,
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Un segment de la ligne : une capsule qui se remplit. Elle se touche (elle
/// s'enfonce, revient en ressort) et dit alors ce qui se passe a cette etape.
class _Segment extends StatelessWidget {
  const _Segment({
    required this.rang,
    required this.enCours,
    required this.faite,
    required this.montree,
    required this.echelle,
    required this.rempli,
    required this.plein,
    required this.vide,
    required this.onPress,
    super.key,
  });

  final int rang;
  final bool enCours;
  final bool faite;
  final bool montree;
  final double echelle;
  final double rempli;
  final Color plein;
  final Color vide;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final e = t.recrutement.accueil.etapes;
    final String etat = faite
        ? e.faite
        : enCours
        ? e.enCours
        : e.aVenir;
    return ToucherVivant(
      onPress: onPress,
      enfoncement: 0.94,
      libelleSemantique: e.lecture(
        position: e.position(n: rang, total: sallesDuCandidat),
        nom: LigneEtapes.nom(rang),
        etat: etat,
      ),
      child: SizedBox(
        // La cible tactile : 48 de haut autour d'une capsule fine.
        height: AppTouchTarget.standard,
        child: Center(
          child: Transform.scale(
            scaleY: echelle,
            child: DecoratedBox(
              // L'etape touchee porte un contour : jamais la couleur seule.
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: montree
                      ? palette.inkAccent.asBorderSide(width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: _Trait(part: rempli, plein: plein, vide: vide),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Trait extends StatelessWidget {
  const _Trait({required this.part, required this.plein, required this.vide});

  final double part;
  final Color plein;
  final Color vide;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: AppRadius.arrondiFull,
      child: SizedBox(
        height: LigneEtapes.trait,
        child: ColoredBox(
          color: vide,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: part,
              heightFactor: 1,
              child: ColoredBox(color: plein),
            ),
          ),
        ),
      ),
    ),
  );
}
