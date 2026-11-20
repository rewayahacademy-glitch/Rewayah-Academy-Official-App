// VIVANT : la grande case sombre de l'accueil de la direction. Praxis est
// assis sur son bord : il dit le blocage du moment (la phrase s'ecrit, sa
// bouche bat tant qu'elle s'ecrit), puis la case montre les sept prochains
// jours de creneaux d'entretien et les gestes.
//
// La case est sombre dans les deux themes : tout ce qu'elle contient lit la
// palette sombre de l'application (l'accent y est la lavande, jamais le
// violet). Les deux gestes secondaires gardent le theme de la page.
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../core/candidature/attentes_recrutement.dart';
import '../../core/candidature/creneaux_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/vivant/praxis_vivant.dart';
import '../../core/vivant/texte_qui_s_ecrit.dart';
import '../../core/widgets/action_principale.dart';
import 'phrase_praxis.dart';

/// Un geste propose par Praxis : son libelle et l'adresse qu'il ouvre.
typedef GestePraxis = ({String libelle, String adresse, bool principal});

/// La grande case sombre : l'en-tete de la page.
class HerosPraxis extends StatefulWidget {
  /// Cree la case.
  const HerosPraxis({
    required this.phrase,
    required this.maintenant,
    required this.regard,
    required this.grand,
    required this.gestes,
    required this.onOuvrir,
    super.key,
    this.attentes,
    this.creneaux,
    this.date,
    this.hauteurMin = 0,
  });

  /// Ce que dit Praxis.
  final PhrasePraxis phrase;

  /// L'instant courant (salutation, semaine).
  final DateTime maintenant;

  /// Le pointeur, que Praxis suit des yeux.
  final ValueListenable<Offset> regard;

  /// Tablette et ordinateur : Praxis plus grand, la date, le grand salut.
  final bool grand;

  /// Les gestes proposes.
  final List<GestePraxis> gestes;

  /// Ouvre une adresse.
  final ValueChanged<String> onOuvrir;

  /// Les attentes du recrutement, si elles sont lues.
  final AttentesRecrutement? attentes;

  /// Les creneaux d'entretien a venir, s'ils sont lus.
  final List<CreneauDirection>? creneaux;

  /// La date du jour.
  final String? date;

  /// La hauteur minimale de la case.
  final double hauteurMin;

  /// La cle de la date du jour.
  static const Key cleDate = ValueKey<String>('adm01-date');

  /// La cle du jour [i] (0 : aujourd'hui) de la semaine des creneaux.
  static Key cleJour(int i) => ValueKey<String>('vivant-jour-$i');

  /// La largeur de Praxis.
  static double taillePraxis({required bool grand}) => grand ? 144 : 104;

  /// La place a garder au-dessus de la case pour Praxis : il depasse aussi
  /// dans la marge haute de la page (24 de ses points).
  static double assise({required bool grand}) =>
      PraxisVivant.assisePour(taillePraxis(grand: grand)) - AppSpacing.xxl;

  @override
  State<HerosPraxis> createState() => _EtatHerosPraxis();
}

class _EtatHerosPraxis extends State<HerosPraxis> {
  bool _parle = false;

  void _ecriture(bool ecrit) {
    if (mounted && _parle != ecrit) setState(() => _parle = ecrit);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData page = Theme.of(context);
    final bool pageSombre = page.brightness == Brightness.dark;
    final AppPalette claire = AppPalette.claire();
    final ThemeData nuit = AppTheme.pour(
      AppMetriques.of(context).mode,
      Brightness.dark,
    );
    final AppPalette sombre = nuit.extension<AppPalette>()!;
    // Clair : l'encre inversee de la palette claire. Sombre : le lavis
    // d'accent, plus haut que le fond de la page.
    final AppColorPair paire = pageSombre
        ? sombre.washAccent
        : claire.surfaceInverse;
    final Color lavande = claire.surfaceActionDouce.background;
    final TextTheme textes = nuit.textTheme;
    final TextStyle petit = (textes.bodySmall ?? const TextStyle()).copyWith(
      color: lavande,
    );
    final v = t.admin.tableau.vivant;
    final String? texte = widget.phrase.texte;
    final AttentesRecrutement? a = widget.attentes;
    final List<CreneauDirection>? liste = widget.creneaux;
    final String? jour = widget.date;
    final int heure = widget.maintenant.hour;
    final String salut = heure < 12
        ? v.bonjour
        : heure < 18
        ? v.bonApresMidi
        : v.bonsoir;
    final bool grand = widget.grand;
    final double taille = HerosPraxis.taillePraxis(grand: grand);
    // Le haut du texte laisse sa place a Praxis : rien ne passe sous ses
    // pieds.
    final EdgeInsetsDirectional placePraxis = EdgeInsetsDirectional.only(
      end: taille + AppSpacing.sm,
    );
    final TextStyle styleSalut = paire.applyTo(
      (grand ? textes.headlineLarge : textes.headlineMedium) ??
          const TextStyle(),
    );
    final ShapeBorder forme = AppRadius.coinContinu(AppRadius.lg);
    final double marge = grand ? AppSpacing.xxl : AppSpacing.xl;
    final int parRang = grand ? 2 : 1;
    final List<Widget> boutons = <Widget>[
      for (final GestePraxis g in widget.gestes)
        if (g.principal)
          // Le seul bouton plein de la page : la lavande pleine de la
          // palette sombre, jamais le violet sur le sombre.
          ActionPrincipale(
            libelle: g.libelle,
            onPress: () => widget.onOuvrir(g.adresse),
            pleineLargeur: false,
            compacte: true,
            pilule: true,
          )
        else
          // Les gestes secondaires gardent le theme de la page : des
          // pilules claires sur la case sombre en clair.
          Theme(
            data: page,
            child: ActionPrincipale(
              libelle: g.libelle,
              onPress: () => widget.onOuvrir(g.adresse),
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              compacte: true,
              pilule: true,
            ),
          ),
    ];
    final Widget contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (jour != null)
              Padding(
                padding: placePraxis,
                child: Text(jour, key: HerosPraxis.cleDate, style: petit),
              ),
            Padding(
              padding: placePraxis,
              child: Semantics(
                header: true,
                // Une seule ligne, reduite si la place manque a cote de
                // Praxis : « Bon après-midi. » ne se coupe jamais.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    salut,
                    maxLines: 1,
                    style: grand
                        ? styleSalut.copyWith(
                            fontSize: AppSpacing.titreEcran,
                            height: 1.1,
                          )
                        : styleSalut,
                  ),
                ),
              ),
            ),
            if (texte != null) ...<Widget>[
              Ecart.vMd,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: TexteQuiSEcrit(
                  texte,
                  key: ValueKey<String>(texte),
                  style: (textes.bodyLarge ?? const TextStyle()).copyWith(
                    color: lavande,
                  ),
                  onEcriture: _ecriture,
                ),
              ),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (a != null || liste != null) Ecart.vLg,
            if (a != null)
              Text(
                a.creneauxOuverts == 0
                    ? t.admin.candidatures.attentes.aucunCreneau
                    : t.admin.candidatures.attentes.creneauxOuverts(
                        n: a.creneauxOuverts,
                      ),
                style: AppTypography.graisse(petit, FontWeight.w600),
              ),
            if (liste != null) ...<Widget>[
              Ecart.vSm,
              _Semaine(
                creneaux: liste,
                maintenant: widget.maintenant,
                paire: paire,
                lavande: lavande,
                textes: textes,
              ),
            ],
            if (boutons.isNotEmpty) ...<Widget>[
              Ecart.vSm,
              // Deux gestes par rang au plus (un seul au telephone) : la
              // hauteur de la case se calcule sans surprise.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (int i = 0; i < boutons.length; i += parRang)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.sm,
                      children: <Widget>[
                        for (final Widget b in boutons.skip(i).take(parRang))
                          Flexible(child: b),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
    return Theme(
      data: nuit,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: <Widget>[
          DecoratedBox(
            decoration: ShapeDecoration(color: paire.background, shape: forme),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: forme,
                textDirection: Directionality.of(context),
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  // Deux grands disques a peine visibles : la case a du
                  // relief sans une couleur de plus.
                  PositionedDirectional(
                    end: -72,
                    top: -88,
                    child: _Disque(300, lavande.withValues(alpha: 0.06)),
                  ),
                  PositionedDirectional(
                    end: 40,
                    bottom: -120,
                    child: _Disque(220, lavande.withValues(alpha: 0.04)),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: widget.hauteurMin),
                    child: Padding(
                      padding: EdgeInsets.all(marge),
                      child: contenu,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            end: AppSpacing.xxl,
            top: -PraxisVivant.assisePour(taille),
            child: IgnorePointer(
              child: PraxisVivant(
                humeur: widget.phrase.humeur,
                taille: taille,
                assis: true,
                parle: _parle,
                regard: widget.regard,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Disque extends StatelessWidget {
  const _Disque(this.diametre, this.couleur);

  final double diametre;
  final Color couleur;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox.square(
      dimension: diametre,
      child: DecoratedBox(
        decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
      ),
    ),
  );
}

/// Les sept prochains jours de creneaux d'entretien : un jour sans creneau
/// libre reste vide (un filet) ; un jour ouvert est plein, plus haut, et
/// porte son nombre (jamais la couleur seule).
class _Semaine extends StatelessWidget {
  const _Semaine({
    required this.creneaux,
    required this.maintenant,
    required this.paire,
    required this.lavande,
    required this.textes,
  });

  final List<CreneauDirection> creneaux;
  final DateTime maintenant;
  final AppColorPair paire;
  final Color lavande;
  final TextTheme textes;

  @override
  Widget build(BuildContext context) {
    final DateTime jour0 = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    int libres(DateTime jour) => creneaux
        .where(
          (CreneauDirection c) =>
              c.etat == EtatCreneau.libre &&
              c.debut.year == jour.year &&
              c.debut.month == jour.month &&
              c.debut.day == jour.day &&
              c.debut.isAfter(maintenant),
        )
        .length;
    return Semantics(
      label: t.admin.tableau.vivant.semaineCreneaux,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: <Widget>[
          for (int i = 0; i < 7; i++)
            () {
              final DateTime jour = DateTime(
                jour0.year,
                jour0.month,
                jour0.day + i,
              );
              final int n = libres(jour);
              final bool ouvert = n > 0;
              final Color encre = ouvert ? paire.background : lavande;
              final TextStyle style = AppTypography.graisse(
                (textes.labelMedium ?? const TextStyle()).copyWith(
                  color: encre,
                ),
                FontWeight.w700,
              );
              return ConstrainedBox(
                key: HerosPraxis.cleJour(i),
                constraints: BoxConstraints(
                  minWidth: AppSpacing.section,
                  minHeight: ouvert
                      ? AppSpacing.titreEcran
                      : AppSpacing.section,
                ),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: ouvert
                        ? lavande
                        : paire.onBackground.withValues(alpha: 0.07),
                    shape: AppRadius.coinContinu(
                      AppRadius.sm,
                      bordure: ouvert
                          ? BorderSide.none
                          : BorderSide(color: lavande.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          t.admin.tableau.vivant.joursInitiales[jour.weekday -
                              1],
                          style: style,
                        ),
                        if (ouvert) Text('$n', style: style),
                      ],
                    ),
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}
