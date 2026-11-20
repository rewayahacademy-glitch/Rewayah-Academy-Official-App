// VIVANT (directeur, 20/11/2026) : le haut de l'accueil de la direction en
// bento vivant. Une grande case sombre ou Praxis, assis sur le bord, dit le
// blocage du moment ; une case haute (les pieces a valider) ; deux petites
// (conversations non lues, courriels du jour en niveau d'eau) ; puis le
// parcours des candidats, chaque case large comme son groupe.
//
// **Donnees reelles uniquement.** Chaque case lit une lecture serveur qui
// existe deja ; une case sans lecture (capacite indisponible, echec) ne
// s'affiche pas. Aucun nombre d'exemple.
//
// Contrat de navigation §2 : une case qui porte un nombre ouvre la liste deja
// filtree, empilee (`push`), le filtre dans l'adresse.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/attentes_recrutement.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_prevenir_candidats.dart';
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
import '../../core/vivant/praxis_vivant.dart';
import '../../core/vivant/surface_penchee.dart';
import '../../core/vivant/toucher_vivant.dart';
import '../admin_candidatures/adresse_candidatures.dart';
import '../admin_candidatures/files_candidatures.dart' show depuisQuand;
import 'phrase_praxis.dart';

/// L'adresse de la liste des candidatures, deja filtree par [filtre].
String adresseCandidaturesFiltree(FiltreCandidatures filtre) => Uri(
  path: Routes.adminPersonnesCandidatures,
  queryParameters: requeteEnAdresse(RequeteCandidatures(filtre: filtre)),
).toString();

/// Le filtre d'une file par etat : en cours, hors pause, comme la puce de la
/// liste (`files_candidatures.dart`), pour que la liste ouverte ait la
/// longueur du nombre affiche.
FiltreCandidatures filtreEtat(EtatCandidature etat) => FiltreCandidatures(
  etat: etat,
  enPause: false,
  issue: IssueCandidature.enCours,
);

/// Le filtre « piece a valider » : en cours, hors pause (cle serveur
/// `pieceEnAttente`).
const FiltreCandidatures filtrePieces = FiltreCandidatures(
  pieceEnAttente: true,
  enPause: false,
  issue: IssueCandidature.enCours,
);

/// Le haut de l'accueil, en bento vivant.
class BentoVivant extends StatefulWidget {
  /// Cree le bento.
  const BentoVivant({
    required this.phrase,
    required this.maintenant,
    super.key,
    this.attentes,
    this.messagesNonLus,
    this.courriels,
  });

  /// Ce que dit Praxis.
  final PhrasePraxis phrase;

  /// L'instant courant (salutation, anciennete).
  final DateTime maintenant;

  /// Les attentes du recrutement ; `null` : non lues, leurs cases ne
  /// s'affichent pas.
  final AttentesRecrutement? attentes;

  /// Les conversations non lues ; `null` ou 0 : la case ne s'affiche pas (la
  /// lecture rend 0 quand elle n'aboutit pas : un 0 n'y est pas une preuve).
  final int? messagesNonLus;

  /// L'etat de la file des courriels ; `null` : non lu.
  final EtatFileCourriels? courriels;

  /// La largeur a partir de laquelle la grille a quatre colonnes.
  static const double seuilQuatre = 960;

  /// La largeur a partir de laquelle la grille a deux colonnes.
  static const double seuilDeux = 600;

  /// La case sombre de Praxis.
  static const Key cleHeros = ValueKey<String>('vivant-heros');

  /// La case des pieces a valider.
  static const Key clePieces = ValueKey<String>('vivant-pieces');

  /// La case des conversations non lues.
  static const Key cleMessages = ValueKey<String>('vivant-messages');

  /// La case des courriels du jour.
  static const Key cleCourriels = ValueKey<String>('vivant-courriels');

  /// La case d'un etat du parcours.
  static Key cleEtat(EtatCandidature e) =>
      ValueKey<String>('vivant-etat-${e.name}');

  @override
  State<BentoVivant> createState() => _EtatBentoVivant();
}

class _EtatBentoVivant extends State<BentoVivant> {
  /// Le pointeur, que Praxis suit des yeux.
  final ValueNotifier<Offset> _regard = ValueNotifier<Offset>(Offset.zero);

  @override
  void dispose() {
    _regard.dispose();
    super.dispose();
  }

  void _ouvrir(String adresse) =>
      unawaited(GoRouter.of(context).push<void>(adresse));

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AttentesRecrutement? attentes = widget.attentes;
    final int messages = widget.messagesNonLus ?? 0;
    final EtatFileCourriels? courriels = widget.courriels;
    final v = t.admin.tableau.vivant;

    final Widget heros = _Heros(
      key: BentoVivant.cleHeros,
      phrase: widget.phrase,
      heure: widget.maintenant.hour,
      attentes: attentes,
      regard: _regard,
      onPress: switch (widget.phrase.sujet) {
        SujetPraxis.creneaux => () => _ouvrir(
          Routes.adminPersonnesCreneauxEntretien,
        ),
        SujetPraxis.pieces => () => _ouvrir(
          adresseCandidaturesFiltree(filtrePieces),
        ),
        SujetPraxis.dossiers => () => _ouvrir(Routes.adminPersonnesDossiers),
        SujetPraxis.demandes => () => _ouvrir(Routes.adminOperationsDemandes),
        SujetPraxis.messages => () => _ouvrir(
          Routes.adminCommunicationsMessages,
        ),
        SujetPraxis.calme || SujetPraxis.silence => null,
      },
    );

    final Widget? pieces = attentes == null
        ? null
        : CaseNombre(
            key: BentoVivant.clePieces,
            nombre: attentes.pieceAValider.nombre,
            libelle: t.admin.candidatures.attentes.pieceAValider,
            detail: depuisQuand(
              attentes.pieceAValider.plusAncien,
              widget.maintenant,
            ),
            icone: AppIcons.dossiers,
            paire: palette.washAccent,
            onPress: () => _ouvrir(adresseCandidaturesFiltree(filtrePieces)),
          );
    final Widget? caseMessages = messages <= 0
        ? null
        : CaseNombre(
            key: BentoVivant.cleMessages,
            nombre: messages,
            libelle: v.messagesNonLus,
            icone: AppIcons.envoyerMessage,
            // L'accent plein : violet en clair, lavande en sombre.
            paire: palette.surfacePrimary,
            onPress: () => _ouvrir(Routes.adminCommunicationsMessages),
          );
    final Widget? caseCourriels = courriels == null
        ? null
        : CaseNombre(
            key: BentoVivant.cleCourriels,
            nombre: courriels.partis24h,
            libelle: v.courriels,
            detail: v.courrielsSur(max: courriels.parJour),
            icone: AppIcons.envoyerMessage,
            paire: palette.surfaceRaised,
            niveau: courriels.parJour <= 0
                ? 0
                : (courriels.partis24h / courriels.parJour).clamp(0, 1),
            onPress: () => _ouvrir(Routes.adminOperationsCourriels),
          );
    final List<Widget> petites = <Widget>[?caseMessages, ?caseCourriels];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool quatre = c.maxWidth >= BentoVivant.seuilQuatre;
        final bool deux = c.maxWidth >= BentoVivant.seuilDeux;
        final Widget? colonnePetites = petites.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: <Widget>[
                  for (final Widget p in petites) Expanded(child: p),
                ],
              );
        final List<Widget> blocs = <Widget>[
          // La place de Praxis, assis sur le bord de sa case.
          const SizedBox(height: _Heros.assise),
          if (quatre)
            _Rang(
              cases: <(int, Widget)>[
                (2, heros),
                if (pieces != null) (1, pieces),
                if (colonnePetites != null) (1, colonnePetites),
              ],
            )
          else if (deux) ...<Widget>[
            heros,
            if (pieces != null || colonnePetites != null)
              _Rang(
                cases: <(int, Widget)>[
                  if (pieces != null) (1, pieces),
                  if (colonnePetites != null) (1, colonnePetites),
                ],
              ),
          ] else ...<Widget>[heros, ?pieces, ...petites],
          if (attentes != null)
            ParcoursCandidats(
              attentes: attentes,
              maintenant: widget.maintenant,
              enLigne: deux,
              onOuvrir: _ouvrir,
            ),
        ];
        return MouseRegion(
          onHover: (PointerEvent e) => _regard.value = e.position,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: blocs,
          ),
        );
      },
    );
  }
}

/// Un rang de cases de meme hauteur : celle de la plus haute.
class _Rang extends StatelessWidget {
  const _Rang({required this.cases});

  final List<(int, Widget)> cases;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: <Widget>[
        for (final (int flex, Widget enfant) in cases)
          Expanded(flex: flex, child: enfant),
      ],
    ),
  );
}

/// Une case du bento : coin a courbe continue, marge de 16, fond d'une paire
/// de la palette. Avec [onPress], elle s'enfonce au toucher et penche au
/// survol.
class CaseVivante extends StatelessWidget {
  /// Cree la case.
  const CaseVivante({
    required this.paire,
    required this.child,
    super.key,
    this.onPress,
    this.libelleSemantique,
    this.niveau,
    this.filet = false,
    this.hauteurMin = 128,
  });

  /// Le rayon d'une case.
  static const double rayon = AppRadius.lg;

  /// La marge interieure d'une case.
  static const double marge = AppSpacing.lg;

  /// Le fond et son encre.
  final AppColorPair paire;

  /// Le contenu.
  final Widget child;

  /// Le geste ; sans lui, la case est un rapport.
  final VoidCallback? onPress;

  /// Ce que lit le lecteur d'ecran pour toute la case.
  final String? libelleSemantique;

  /// Le niveau d'eau (0 a 1) ; `null` : pas d'eau.
  final double? niveau;

  /// Un filet au lieu d'un fond (case vide).
  final bool filet;

  /// La hauteur minimale.
  final double hauteurMin;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ShapeBorder forme = AppRadius.coinContinu(rayon);
    final double? eau = niveau;
    Widget c = DecoratedBox(
      decoration: ShapeDecoration(
        color: filet ? null : paire.background,
        shape: AppRadius.coinContinu(
          rayon,
          bordure: filet
              ? palette.borderResting.asBorderSide()
              : BorderSide.none,
        ),
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: forme,
          textDirection: Directionality.of(context),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            if (eau != null && eau > 0)
              Positioned.fill(
                child: NiveauEau(
                  niveau: eau,
                  // Une teinte de l'encre de la case : le texte reste
                  // lisible au-dessus comme au-dessous de la surface.
                  couleur: paire.onBackground.withValues(alpha: 0.14),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: hauteurMin),
              child: Padding(
                padding: const EdgeInsets.all(marge),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
    final VoidCallback? geste = onPress;
    if (geste == null) return c;
    c = ToucherVivant(
      onPress: geste,
      libelleSemantique: libelleSemantique,
      arrondiFocus: const BorderRadius.all(Radius.circular(rayon)),
      child: c,
    );
    return SurfacePenchee(child: c);
  }
}

/// Une case-chiffre : un grand nombre a rouleaux, son libelle, une icone.
class CaseNombre extends StatelessWidget {
  /// Cree la case.
  const CaseNombre({
    required this.nombre,
    required this.libelle,
    required this.icone,
    required this.paire,
    super.key,
    this.detail,
    this.onPress,
    this.niveau,
    this.filet = false,
    this.alerte,
  });

  /// Le nombre.
  final int nombre;

  /// Ce qu'il compte.
  final String libelle;

  /// Une precision (anciennete, plafond).
  final String? detail;

  /// L'icone, en haut au bord de fin.
  final AppIcon icone;

  /// Le fond et son encre.
  final AppColorPair paire;

  /// Le geste.
  final VoidCallback? onPress;

  /// Le niveau d'eau.
  final double? niveau;

  /// Case vide : un filet, pas de fond.
  final bool filet;

  /// Une phrase d'alerte, avec un cadenas (jamais la couleur seule).
  final String? alerte;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Color encre = paire.onBackground;
    final TextStyle petit = AppTypography.graisse(
      (textes.bodySmall ?? const TextStyle()).copyWith(color: encre),
      FontWeight.w600,
    );
    final String? precision = alerte ?? detail;
    return CaseVivante(
      paire: paire,
      onPress: onPress,
      niveau: niveau,
      filet: filet,
      libelleSemantique: <String>['$nombre', libelle, ?precision].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: NombreRouleaux(
                  nombre,
                  style: (textes.displaySmall ?? const TextStyle()).copyWith(
                    color: encre,
                  ),
                ),
              ),
              Icon(
                (alerte != null ? AppIcons.verrou : icone).repos,
                size: AppSpacing.xxl,
                color: encre,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(libelle, style: petit),
                if (precision != null)
                  Text(
                    precision,
                    style: (textes.bodySmall ?? const TextStyle()).copyWith(
                      color: encre,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La grande case sombre : Praxis est assis sur son bord et dit le blocage du
/// moment. Sombre dans les deux themes ; le texte d'accent y est la lavande,
/// jamais le violet.
class _Heros extends StatelessWidget {
  const _Heros({
    required this.phrase,
    required this.heure,
    required this.regard,
    super.key,
    this.attentes,
    this.onPress,
  });

  /// La largeur de Praxis.
  static const double taillePraxis = 96;

  /// La part de Praxis qui depasse au-dessus de la case.
  static const double assise = 48;

  final PhrasePraxis phrase;
  final int heure;
  final ValueNotifier<Offset> regard;
  final AttentesRecrutement? attentes;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppPalette claire = AppPalette.claire();
    final bool sombre = Theme.of(context).brightness == Brightness.dark;
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.admin.tableau.vivant;
    // Clair : l'encre inversee de la palette claire. Sombre : le lavis
    // d'accent, plus haut que le fond de la page.
    final AppColorPair paire = sombre
        ? palette.washAccent
        : claire.surfaceInverse;
    final Color lavande = sombre
        ? paire.onBackground
        : claire.surfaceActionDouce.background;
    final String? texte = phrase.texte;
    final AttentesRecrutement? a = attentes;
    final String salut = heure < 12
        ? v.bonjour
        : heure < 18
        ? v.bonApresMidi
        : v.bonsoir;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: <Widget>[
        CaseVivante(
          paire: paire,
          onPress: onPress,
          hauteurMin: 160,
          libelleSemantique: <String>[salut, ?texte].join(' '),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: taillePraxis + AppSpacing.lg,
                    ),
                    child: Text(
                      salut,
                      style: paire.applyTo(
                        textes.titleLarge ?? const TextStyle(),
                      ),
                    ),
                  ),
                  if (texte != null) ...<Widget>[
                    Ecart.vMd,
                    // Praxis est assis au-dessus : le texte lui laisse sa
                    // place, rien ne passe sous lui.
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: taillePraxis + AppSpacing.lg,
                      ),
                      child: Text(
                        texte,
                        style: (textes.bodyLarge ?? const TextStyle()).copyWith(
                          color: lavande,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (a != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Text(
                    a.creneauxOuverts == 0
                        ? t.admin.candidatures.attentes.aucunCreneau
                        : t.admin.candidatures.attentes.creneauxOuverts(
                            n: a.creneauxOuverts,
                          ),
                    style: (textes.bodySmall ?? const TextStyle()).copyWith(
                      color: lavande,
                    ),
                  ),
                ),
            ],
          ),
        ),
        PositionedDirectional(
          end: AppSpacing.xxl,
          top: -assise,
          child: IgnorePointer(
            child: PraxisVivant(
              humeur: phrase.humeur,
              taille: taillePraxis,
              regard: regard,
            ),
          ),
        ),
      ],
    );
  }
}

/// Le parcours des candidats : une case par etat, large comme son groupe,
/// remplie comme un niveau d'eau. La ou rien ne passe (des entretiens a
/// planifier, aucun creneau ouvert), la case le dit avec un cadenas.
class ParcoursCandidats extends StatelessWidget {
  /// Cree le parcours.
  const ParcoursCandidats({
    required this.attentes,
    required this.maintenant,
    required this.enLigne,
    required this.onOuvrir,
    super.key,
  });

  /// Les nombres lus au serveur.
  final AttentesRecrutement attentes;

  /// L'instant courant.
  final DateTime maintenant;

  /// Les cases cote a cote (tablette, ordinateur) ou empilees (telephone).
  final bool enLigne;

  /// Ouvre une adresse, empilee.
  final ValueChanged<String> onOuvrir;

  /// Les etats du parcours, dans l'ordre ou un candidat les traverse.
  static const List<EtatCandidature> etats = <EtatCandidature>[
    EtatCandidature.aCompleter,
    EtatCandidature.enExamen,
    EtatCandidature.paiementNonDisponible,
    EtatCandidature.entretienAPlanifier,
    EtatCandidature.entretienPlanifie,
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.admin.candidatures.etats;
    final v = t.admin.tableau.vivant;
    final int plusGrand = etats.fold<int>(
      1,
      (int m, EtatCandidature x) => math.max(m, attentes.etat(x).nombre),
    );
    String nom(EtatCandidature x) => switch (x) {
      EtatCandidature.aCompleter => e.aCompleter,
      EtatCandidature.enExamen => e.enExamen,
      EtatCandidature.paiementNonDisponible => e.versementImpossible,
      EtatCandidature.entretienAPlanifier => e.entretienAPlanifier,
      EtatCandidature.entretienPlanifie => e.entretienPlanifie,
      EtatCandidature.decisionEnAttente => e.decisionEnAttente,
    };
    final List<(int, Widget)> cases = <(int, Widget)>[
      for (final EtatCandidature x in etats)
        () {
          final Attente at = attentes.etat(x);
          final bool bloque =
              x == EtatCandidature.entretienAPlanifier &&
              at.nombre > 0 &&
              attentes.creneauxOuverts == 0;
          final double part = math.sqrt(at.nombre / plusGrand);
          return (
            // Large comme son groupe, sans jamais devenir illisible.
            (math.max(0.62, part) * 100).round(),
            CaseNombre(
              key: BentoVivant.cleEtat(x),
              nombre: at.nombre,
              libelle: nom(x),
              detail: depuisQuand(at.plusAncien, maintenant),
              alerte: bloque
                  ? t.admin.candidatures.attentes.aucunCreneau
                  : null,
              icone: AppIcons.suivant,
              paire: bloque ? palette.washAlert : palette.washAccent,
              filet: at.nombre == 0,
              niveau: at.nombre == 0 ? null : 0.2 + 0.5 * part,
              onPress: () =>
                  onOuvrir(adresseCandidaturesFiltree(filtreEtat(x))),
            ),
          );
        }(),
    ];
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
        if (enLigne)
          _Rang(cases: cases)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: <Widget>[for (final (int _, Widget c) in cases) c],
          ),
      ],
    );
  }
}
