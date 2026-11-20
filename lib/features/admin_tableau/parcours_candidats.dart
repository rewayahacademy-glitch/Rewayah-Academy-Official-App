// VIVANT : le parcours des candidats. Des tuiles familieres, mais vivantes :
// chacune est large comme son nombre de personnes, se remplit comme un niveau
// d'eau et montre les visages des plus anciens quand la lecture les donne ;
// des points passent d'une tuile a la suivante. La ou rien ne passe (des
// entretiens a planifier, aucun creneau ouvert), les points pietinent devant
// un cadenas ferme ; il s'ouvre et passe au vert quand des creneaux existent.
//
// Donnees reelles uniquement : les nombres et les dates viennent de
// `attentes_recrutement()`. Les visages ne s'affichent que pour un etat dont
// toute la file a ete lue (`visages`), sinon « les plus anciens » serait
// faux.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/candidature/attentes_recrutement.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/vivant/niveau_eau.dart';
import '../../core/vivant/nombre_rouleaux.dart';
import '../../core/vivant/ressort.dart';
import '../../core/vivant/surface_penchee.dart';
import '../../core/vivant/toucher_vivant.dart';
import '../../core/widgets/avatar_nom.dart';
import '../admin_candidatures/files_candidatures.dart' show depuisQuand;
import 'adresses_vivant.dart';

/// Le parcours des candidats.
class ParcoursCandidats extends StatefulWidget {
  /// Cree le parcours.
  const ParcoursCandidats({
    required this.attentes,
    required this.maintenant,
    required this.onOuvrir,
    super.key,
    this.visages = const <EtatCandidature, List<String>>{},
  });

  /// Les nombres lus au serveur.
  final AttentesRecrutement attentes;

  /// L'instant courant.
  final DateTime maintenant;

  /// Ouvre une adresse.
  final ValueChanged<String> onOuvrir;

  /// Les noms des plus anciens d'un etat, du plus ancien au plus recent ;
  /// absent : la file de cet etat n'a pas ete lue en entier.
  final Map<EtatCandidature, List<String>> visages;

  /// Les quatre etats du chemin, dans l'ordre ou un candidat les traverse.
  static const List<EtatCandidature> chemin = <EtatCandidature>[
    EtatCandidature.aCompleter,
    EtatCandidature.enExamen,
    EtatCandidature.entretienAPlanifier,
    EtatCandidature.entretienPlanifie,
  ];

  /// L'etat accroche sous « En examen » : le versement pas encore possible.
  static const EtatCandidature versement =
      EtatCandidature.paiementNonDisponible;

  /// Tous les etats montres.
  static const List<EtatCandidature> etats = <EtatCandidature>[
    ...chemin,
    versement,
  ];

  /// La largeur a partir de laquelle les tuiles vont cote a cote.
  static const double seuilEnLigne = 900;

  /// L'espace entre deux tuiles, ou passent les points.
  static const double creux = AppSpacing.titreEcran;

  /// La cle de la tuile d'un etat.
  static Key cleEtat(EtatCandidature e) =>
      ValueKey<String>('vivant-etat-${e.name}');

  /// La cle du cadenas entre « Entretien à planifier » et « Entretien
  /// planifié ».
  static const Key cleCadenas = ValueKey<String>('vivant-cadenas');

  /// La cle des visages d'un etat.
  static Key cleVisages(EtatCandidature e) =>
      ValueKey<String>('vivant-visages-${e.name}');

  @override
  State<ParcoursCandidats> createState() => _EtatParcours();
}

class _EtatParcours extends State<ParcoursCandidats>
    with SingleTickerProviderStateMixin<ParcoursCandidats>, VieDesRessorts {
  // Les largeurs suivent les nombres en ressort ; la barriere se leve.
  final List<Ressort> _parts = <Ressort>[
    for (int i = 0; i < 4; i++) Ressort(1, raideur: 170, frein: 17),
  ];
  final Ressort _barriere = Ressort(0, raideur: 120, frein: 9);
  bool _pret = false;

  @override
  Iterable<Ressort> get ressorts => <Ressort>[..._parts, _barriere];

  // Les points avancent doucement tant que le parcours est a l'ecran.
  @override
  bool get toujours => true;

  bool get _ferme =>
      widget.attentes.etat(EtatCandidature.entretienAPlanifier).nombre > 0 &&
      widget.attentes.creneauxOuverts == 0;

  bool get _ouvert => widget.attentes.creneauxOuverts > 0;

  int get _plusGrand => ParcoursCandidats.etats.fold<int>(
    1,
    (int m, EtatCandidature x) => math.max(m, widget.attentes.etat(x).nombre),
  );

  double _part(EtatCandidature x) =>
      math.sqrt(widget.attentes.etat(x).nombre / _plusGrand);

  void _viser() {
    for (int i = 0; i < 4; i++) {
      // Large comme son nombre, sans jamais devenir illisible.
      _parts[i].cible = math.max(0.62, _part(ParcoursCandidats.chemin[i]));
    }
    _barriere.cible = _ferme ? 0 : 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pret) return;
    _pret = true;
    _viser();
    for (final Ressort r in ressorts) {
      r.poser();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => reveil());
  }

  @override
  void didUpdateWidget(ParcoursCandidats oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attentes != widget.attentes) {
      _viser();
      WidgetsBinding.instance.addPostFrameCallback((_) => reveil());
    }
  }

  void _ouvrirEtat(EtatCandidature x) =>
      widget.onOuvrir(adresseCandidaturesFiltree(filtreEtat(x)));

  Widget _tuile(EtatCandidature x, {bool petite = false}) => _TuileEtat(
    key: ParcoursCandidats.cleEtat(x),
    etat: x,
    attente: widget.attentes.etat(x),
    part: _part(x),
    bloque: _ferme && x == EtatCandidature.entretienAPlanifier,
    petite: petite,
    maintenant: widget.maintenant,
    visages: widget.visages[x],
    onPress: () => _ouvrirEtat(x),
  );

  Widget _cadenas(AppPalette palette) {
    final double b = _barriere.x.clamp(0, 1);
    final bool ferme = _barriere.cible == 0;
    final AppColorPair paire = ferme
        ? palette.surfaceAlert
        : palette.surfaceSuccess;
    final Widget disque = SizedBox.square(
      dimension: AppSpacing.titreEcran,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(
            palette.surfaceAlert.background,
            palette.surfaceSuccess.background,
            b,
          ),
        ),
        child: Transform.rotate(
          angle: -b * 0.5,
          child: Icon(
            (ferme ? AppIcons.verrou : AppIcons.verrouOuvert).repos,
            size: AppSpacing.xxl,
            color: paire.onBackground,
          ),
        ),
      ),
    );
    final String libelle = ferme
        ? t.admin.tableau.vivant.ouvrirCreneaux
        : t.admin.candidatures.attentes.creneauxOuverts(
            n: widget.attentes.creneauxOuverts,
          );
    return KeyedSubtree(
      key: ParcoursCandidats.cleCadenas,
      // Ferme, il mene la ou les creneaux s'ouvrent ; ouvert, il montre le
      // planning des creneaux.
      child: ToucherVivant(
        onPress: () => widget.onOuvrir(Routes.adminPersonnesCreneauxEntretien),
        libelleSemantique: ferme
            ? '${t.admin.candidatures.attentes.aucunCreneau} $libelle'
            : libelle,
        arrondiFocus: AppRadius.arrondiFull,
        enfoncement: 0.9,
        child: disque,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.admin.tableau.vivant;
    // Le cadenas n'existe que si quelque chose se joue a ce passage : des
    // entretiens bloques, ou des creneaux ouverts.
    final bool avecCadenas = _ferme || _ouvert;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Ecart.vSm,
        Text(v.parcoursTitre, style: textes.titleMedium),
        Text(
          v.parcoursAide,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double utile =
                c.maxWidth / MediaQuery.textScalerOf(context).scale(1);
            return utile >= ParcoursCandidats.seuilEnLigne
                ? _enLigne(palette, c.maxWidth, avecCadenas: avecCadenas)
                : _empile(palette, avecCadenas: avecCadenas);
          },
        ),
      ],
    );
  }

  Widget _enLigne(
    AppPalette palette,
    double largeur, {
    required bool avecCadenas,
  }) {
    const double creux = ParcoursCandidats.creux;
    final double somme = _parts.fold<double>(
      0,
      (double s, Ressort r) => s + r.x,
    );
    final double total = largeur - creux * 3;
    final List<double> l = <double>[
      for (final Ressort r in _parts) total * r.x / somme,
    ];
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    Widget lien(int i) => SizedBox(
      width: creux,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _PeintreLien(
                  temps: temps,
                  // Devant la barriere fermee, les points pietinent.
                  pietine: i == 2 && _ferme && _barriere.x < 0.5,
                  rail: palette.borderHairline.asBorderSide().color,
                  point: i == 2
                      ? (_ferme
                            ? palette.pointsStatut.alerte.pastille().color!
                            : palette.pointsStatut.succes.pastille().color!)
                      : palette.surfacePrimary.background,
                  versLaGauche: rtl,
                  immobile: effetsReduits,
                ),
              ),
            ),
          ),
          if (i == 2 && avecCadenas) _cadenas(palette),
        ],
      ),
    );
    // Le versement : une tuile plus petite, accrochee sous « En examen ».
    const double retrait = AppSpacing.xxxl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < 4; i++) ...<Widget>[
                if (i > 0) lien(i - 1),
                SizedBox(
                  width: l[i],
                  child: _tuile(ParcoursCandidats.chemin[i]),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: l[0] + creux + retrait),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: AppSpacing.titreEcran,
                height: AppSpacing.xxl,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _PeintreLien(
                      temps: temps,
                      pietine: false,
                      rail: palette.borderHairline.asBorderSide().color,
                      point: palette.pointsStatut.attention.pastille().color!,
                      versLaGauche: false,
                      vertical: true,
                      immobile: effetsReduits,
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.max(160, math.min(280, l[1] - retrait)),
                ),
                child: _tuile(ParcoursCandidats.versement, petite: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _empile(AppPalette palette, {required bool avecCadenas}) {
    Widget passage({bool cadenas = false}) => SizedBox(
      height: cadenas ? AppSpacing.respiration : AppSpacing.xxxl,
      child: Center(
        child: cadenas
            ? _cadenas(palette)
            : ExcludeSemantics(
                child: Icon(
                  AppIcons.suiteEnBas.repos,
                  size: AppSpacing.xxl,
                  color: palette.inkMuted.asIconTheme().color,
                ),
              ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _tuile(EtatCandidature.aCompleter),
        passage(),
        _tuile(EtatCandidature.enExamen),
        passage(),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.section),
          child: _tuile(ParcoursCandidats.versement, petite: true),
        ),
        passage(),
        _tuile(EtatCandidature.entretienAPlanifier),
        passage(cadenas: avecCadenas),
        _tuile(EtatCandidature.entretienPlanifie),
      ],
    );
  }
}

/// La tuile d'un etat : son nom, son nombre a rouleaux, puis l'eau, ou se
/// lisent les visages des plus anciens et depuis quand le plus ancien attend.
class _TuileEtat extends StatelessWidget {
  const _TuileEtat({
    required this.etat,
    required this.attente,
    required this.part,
    required this.bloque,
    required this.petite,
    required this.maintenant,
    required this.onPress,
    super.key,
    this.visages,
  });

  final EtatCandidature etat;
  final Attente attente;
  final double part;
  final bool bloque;
  final bool petite;
  final DateTime maintenant;
  final VoidCallback onPress;
  final List<String>? visages;

  static const double rayon = AppRadius.lg;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.admin.candidatures.etats;
    final String nom = switch (etat) {
      EtatCandidature.aCompleter => e.aCompleter,
      EtatCandidature.enExamen => e.enExamen,
      EtatCandidature.paiementNonDisponible => e.versementImpossible,
      EtatCandidature.entretienAPlanifier => e.entretienAPlanifier,
      EtatCandidature.entretienPlanifie => e.entretienPlanifie,
      EtatCandidature.decisionEnAttente => e.decisionEnAttente,
    };
    final int n = attente.nombre;
    final bool vide = n == 0;
    final bool versement = etat == EtatCandidature.paiementNonDisponible;
    // Le fond pale de la tuile, et l'eau pleine avec son encre.
    final AppColorPair fond = bloque
        ? palette.washAlert
        : versement
        ? palette.washWarning
        : palette.washAccent;
    final AppColorPair eau = bloque
        ? palette.surfaceAlert
        : versement
        ? palette.surfaceWarning
        : palette.surfacePrimary;
    final Color encre = vide
        ? palette.surfaceCanvas.onBackground
        : fond.onBackground;
    final Color douce =
        palette.inkMuted.applyTo(const TextStyle()).color ?? encre;
    final String? depuis = bloque
        ? t.admin.candidatures.attentes.aucunCreneau
        : depuisQuand(attente.plusAncien, maintenant);
    final String? pied = vide ? t.admin.candidatures.attentes.rien : depuis;
    final TextStyle styleNom = AppTypography.graisse(
      (textes.bodySmall ?? const TextStyle()).copyWith(
        color: vide ? douce : encre,
      ),
      FontWeight.w600,
    );
    final TextStyle stylePied = AppTypography.graisse(
      (textes.bodySmall ?? const TextStyle()).copyWith(
        color: vide ? douce : eau.onBackground,
      ),
      FontWeight.w600,
    );
    final List<String> noms = (visages ?? const <String>[]).take(3).toList();
    final double marge = petite ? AppSpacing.md : AppSpacing.lg;

    final Widget corps;
    if (petite) {
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              marge,
              marge,
              marge,
              AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                NombreRouleaux(
                  n,
                  style: (textes.headlineSmall ?? const TextStyle()).copyWith(
                    color: vide ? douce : encre,
                  ),
                ),
                Ecart.hMd,
                Expanded(child: Text(nom, style: styleNom)),
              ],
            ),
          ),
          if (vide)
            const SizedBox(height: AppSpacing.sm)
          else
            SizedBox(
              height: AppSpacing.lg,
              child: NiveauEau(niveau: 0.7, couleur: eau.background),
            ),
        ],
      );
    } else {
      // Deux blocs : le nom et le nombre en haut, l'eau en bas. La place en
      // trop (tuile etiree par son rang, hauteur minimale) va entre les
      // deux : l'eau touche toujours le bas de la tuile.
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(marge, marge, marge, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(nom, style: styleNom),
                NombreRouleaux(
                  n,
                  style: (textes.displaySmall ?? const TextStyle()).copyWith(
                    color: vide ? douce : encre,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // La surface de l'eau : elle monte avec le nombre.
              if (!vide)
                SizedBox(
                  height: AppSpacing.md + 28 * part.clamp(0, 1),
                  child: NiveauEau(niveau: 0.72, couleur: eau.background),
                )
              else
                Ecart.vMd,
              ColoredBox(
                color: vide
                    ? fond.background.withValues(alpha: 0)
                    : eau.background,
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    marge,
                    AppSpacing.xs,
                    marge,
                    marge,
                  ),
                  // Les visages, puis la phrase a cote ; dessous quand la tuile
                  // est etroite (jamais une colonne d'une lettre de large).
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (noms.isNotEmpty)
                        _Visages(
                          key: ParcoursCandidats.cleVisages(etat),
                          noms: noms,
                          anneau: eau.background,
                        ),
                      if (pied != null) Text(pied, style: stylePied),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final ShapeBorder forme = AppRadius.coinContinu(
      petite ? AppRadius.md : rayon,
    );
    final Widget tuile = DecoratedBox(
      decoration: ShapeDecoration(
        color: vide ? null : fond.background,
        shape: AppRadius.coinContinu(
          petite ? AppRadius.md : rayon,
          bordure: vide
              ? palette.borderResting.asBorderSide()
              : BorderSide.none,
        ),
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: forme,
          textDirection: Directionality.of(context),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: petite ? 0 : 184),
          child: corps,
        ),
      ),
    );
    return SurfacePenchee(
      force: 0.035,
      child: ToucherVivant(
        onPress: onPress,
        enfoncement: 0.97,
        arrondiFocus: BorderRadius.all(
          Radius.circular(petite ? AppRadius.md : rayon),
        ),
        libelleSemantique: <String>['$n $nom', ?pied].join(', '),
        child: tuile,
      ),
    );
  }
}

/// Les plus anciens d'un etat, en visages qui se chevauchent : le plus
/// ancien devant.
class _Visages extends StatelessWidget {
  const _Visages({required this.noms, required this.anneau, super.key});

  final List<String> noms;
  final Color anneau;

  static const double diametre = AppAvatar.petit;
  static const double pas = AppSpacing.xxl;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: diametre + pas * (noms.length - 1) + AppSpacing.xs,
      height: diametre + AppSpacing.xs,
      child: Stack(
        children: <Widget>[
          for (int k = noms.length - 1; k >= 0; k--)
            PositionedDirectional(
              start: k * pas,
              top: 0,
              child: DecoratedBox(
                // Un anneau de la couleur de l'eau detache chaque visage.
                decoration: BoxDecoration(
                  color: anneau,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs / 2),
                  child: AvatarNom(
                    prenom: noms[k],
                    disposition: DispositionAvatar.vertical,
                    diametre: diametre,
                    afficherNom: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Le lien entre deux tuiles : un rail et trois points qui passent, ou qui
/// pietinent devant la barriere fermee. Immobile sous « Reduire les effets » :
/// les points restent poses, l'information (ca passe, ca bloque) demeure.
class _PeintreLien extends CustomPainter {
  _PeintreLien({
    required this.temps,
    required this.pietine,
    required this.rail,
    required this.point,
    required this.versLaGauche,
    required this.immobile,
    this.vertical = false,
  });

  final double temps;
  final bool pietine;
  final Color rail;
  final Color point;
  final bool versLaGauche;
  final bool immobile;
  final bool vertical;

  @override
  void paint(Canvas c, Size s) {
    final double t = immobile ? 0.4 : temps;
    final Paint trait = Paint()
      ..color = rail
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Paint plein = Paint()..color = point;
    if (vertical) {
      final double x = s.width / 2;
      c.drawLine(Offset(x, 4), Offset(x, s.height - 4), trait);
      final double p = (t * 0.35) % 1;
      c.drawCircle(Offset(x, 4 + (s.height - 8) * p), 2.6, plein);
      return;
    }
    final double y = s.height / 2;
    const double a = 5;
    final double b = s.width - 5;
    double x(double dx) => versLaGauche ? s.width - dx : dx;
    c.drawLine(Offset(x(a), y), Offset(x(b), y), trait);
    for (int k = 0; k < 3; k++) {
      if (pietine) {
        c.drawCircle(
          Offset(
            x(a + 3 + k * 5.5 + math.sin(t * 3 + k) * 1.2),
            y + (k - 1) * 7.0,
          ),
          3,
          plein,
        );
      } else {
        final double p = (t * 0.45 + k / 3) % 1;
        c.drawCircle(
          Offset(x(a + (b - a) * p), y - math.sin(p * math.pi) * 5),
          3.2 * math.sin(p * math.pi) + 0.8,
          plein,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PeintreLien ancien) =>
      ancien.temps != temps ||
      ancien.pietine != pietine ||
      ancien.point != point ||
      ancien.rail != rail ||
      ancien.immobile != immobile;
}
