// VIVANT (directeur, 20/11/2026) : l'accueil de la direction, une seule page
// et une seule grammaire. Une grande case sombre ou Praxis, assis sur le
// bord, dit le blocage du moment, montre les sept prochains jours de creneaux
// d'entretien et propose les gestes ; une case haute (la pile des pieces a
// valider, qu'on feuillette) ; deux petites (conversations non lues,
// courriels des 24 heures en reservoir) ; le parcours des candidats, chaque
// tuile large comme son nombre ; les cases-chiffres de l'academie ; la case
// large « Ce qui a changé ».
//
// **Donnees reelles uniquement.** Chaque case lit une lecture serveur qui
// existe deja ; une case sans lecture (capacite indisponible, echec) ne
// s'affiche pas. Aucun nombre d'exemple, aucun nombre affiche deux fois.
//
// Contrat de navigation §2 : une case qui porte un nombre ouvre la liste deja
// filtree, le filtre dans l'adresse ; une personne (une carte de la pile, un
// nom) ouvre SON dossier. La page s'ouvre par `go` : l'adresse du navigateur
// la dit (un rechargement rend le meme ecran, contrat §5), et le retour du
// bureau (`retourBureau`, BUREAU-NAV) ramene au parent logique.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/accueil/signaux_accueils.dart';
import '../../core/admin/service_admin.dart';
import '../../core/candidature/attentes_recrutement.dart';
import '../../core/candidature/creneaux_direction.dart';
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
import '../../core/vivant/surface_penchee.dart';
import '../../core/vivant/toucher_vivant.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bouton_outil.dart';
import '../../core/widgets/halo_lumiere.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/lumiere_autour.dart';
import 'adresses_vivant.dart';
import 'heros_praxis.dart';
import 'parcours_candidats.dart';
import 'phrase_praxis.dart';
import 'pile_pieces.dart';

export 'adresses_vivant.dart';
export 'parcours_candidats.dart';

/// Un nom de la case « Dossiers à valider » : ce qui se lit, et le geste qui
/// ouvre SON dossier.
typedef NomDossier = ({String libelle, VoidCallback onOuvrir});

/// Un outil de l'accueil au telephone : une destination sans autre entree.
typedef OutilAccueil = ({
  Key? cle,
  AppIcon icone,
  String libelle,
  String adresse,
});

/// L'accueil de la direction, en bento vivant.
class BentoVivant extends StatefulWidget {
  /// Cree le bento.
  const BentoVivant({
    required this.phrase,
    required this.maintenant,
    required this.indicateurs,
    required this.dossiers,
    required this.activite,
    super.key,
    this.nomsDossiers = const <NomDossier>[],
    this.dossiersErreur,
    this.attentes,
    this.messagesNonLus,
    this.dernierMessage,
    this.courriels,
    this.creneaux,
    this.pieces,
    this.piecesPlusAncienneDabord = false,
    this.visages = const <EtatCandidature, List<String>>{},
    this.date,
    this.lumieres = const <MotifDirection, NatureHalo?>{},
    this.alertes,
    this.outils = const <OutilAccueil>[],
  });

  /// Ce que dit Praxis.
  final PhrasePraxis phrase;

  /// L'instant courant (salutation, anciennete, semaine).
  final DateTime maintenant;

  /// Les six compteurs de l'academie, lus au serveur.
  final IndicateursAdmin indicateurs;

  /// Les dossiers d'identite a valider (ceux de la file affichee).
  final int dossiers;

  /// Les plus anciens dossiers d'identite : chaque nom ouvre SON dossier.
  final List<NomDossier> nomsDossiers;

  /// La phrase a la place des noms quand la file n'a pas pu etre lue.
  final String? dossiersErreur;

  /// La case large « Ce qui a changé ».
  final Widget Function({required bool deuxColonnes}) activite;

  /// Les attentes du recrutement ; `null` : non lues, leurs cases ne
  /// s'affichent pas.
  final AttentesRecrutement? attentes;

  /// Les conversations non lues ; `null` ou 0 : la case ne s'affiche pas (la
  /// lecture rend 0 quand elle n'aboutit pas : un 0 n'y est pas une preuve).
  final int? messagesNonLus;

  /// Le dernier message non lu : qui, puis sa premiere ligne.
  final (String, String)? dernierMessage;

  /// L'etat de la file des courriels ; `null` : non lu.
  final EtatFileCourriels? courriels;

  /// Les creneaux d'entretien a venir ; `null` : non lus, la semaine ne
  /// s'affiche pas.
  final List<CreneauDirection>? creneaux;

  /// Les candidatures de la file des pieces a valider, dans l'ordre de la
  /// pile ; `null` : non lues.
  final List<LigneCandidature>? pieces;

  /// Vrai : toute la file des pieces est lue, la plus ancienne en premier.
  final bool piecesPlusAncienneDabord;

  /// Les noms des plus anciens d'un etat du parcours, quand toute sa file est
  /// lue.
  final Map<EtatCandidature, List<String>> visages;

  /// La date du jour, sur grand ecran.
  final String? date;

  /// Les lumieres des cases (LUMIERE-ACCUEILS 4), par motif.
  final Map<MotifDirection, NatureHalo?> lumieres;

  /// Les alertes ouvertes non urgentes, apres les cases ; `null` : aucune.
  final Widget? alertes;

  /// Les destinations sans autre entree (telephone) ; vide : aucune case.
  final List<OutilAccueil> outils;

  /// La largeur a partir de laquelle la grille a quatre colonnes.
  static const double seuilQuatre = 960;

  /// La largeur a partir de laquelle la grille a deux colonnes.
  static const double seuilDeux = 600;

  /// En dessous (telephone etroit, ou texte tres agrandi), les cases-chiffres
  /// ne vont plus par deux : une par ligne, aucun mot coupe.
  static const double seuilPaires = 300;

  /// La hauteur du premier rang (Praxis, la pile, les deux petites cases).
  static const double hauteurRang = 388;

  /// La case sombre de Praxis.
  static const Key cleHeros = ValueKey<String>('vivant-heros');

  /// La date du jour, dans la case de Praxis.
  static const Key cleDate = HerosPraxis.cleDate;

  /// Le jour [i] (0 : aujourd'hui) de la semaine des creneaux.
  static Key cleJour(int i) => HerosPraxis.cleJour(i);

  /// La case des pieces a valider.
  static const Key clePieces = ValueKey<String>('vivant-pieces');

  /// La case des conversations non lues.
  static const Key cleMessages = ValueKey<String>('vivant-messages');

  /// La case des courriels des 24 heures.
  static const Key cleCourriels = ValueKey<String>('vivant-courriels');

  /// Les cases-chiffres de l'academie.
  static const Key cleDossiers = ValueKey<String>('vivant-dossiers');

  /// « Demandes à trancher ».
  static const Key cleDemandes = ValueKey<String>('vivant-demandes');

  /// « Élèves sans enseignant ».
  static const Key cleEleves = ValueKey<String>('vivant-eleves');

  /// « Cahiers manquants ».
  static const Key cleCahiers = ValueKey<String>('vivant-cahiers');

  /// « Incidents (24 h) ».
  static const Key cleIncidents = ValueKey<String>('vivant-incidents');

  /// « Accès échus ».
  static const Key cleEchus = ValueKey<String>('vivant-echus');

  /// La case des outils (telephone).
  static const Key cleOutils = ValueKey<String>('vivant-outils');

  /// Le cadenas entre « Entretien à planifier » et « Entretien planifié ».
  static const Key cleCadenas = ParcoursCandidats.cleCadenas;

  /// La case d'un etat du parcours.
  static Key cleEtat(EtatCandidature e) => ParcoursCandidats.cleEtat(e);

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

  void _ouvrir(String adresse) => GoRouter.of(context).go(adresse);

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AttentesRecrutement? attentes = widget.attentes;
    final int messages = widget.messagesNonLus ?? 0;
    final EtatFileCourriels? courriels = widget.courriels;
    final IndicateursAdmin ind = widget.indicateurs;
    final v = t.admin.tableau.vivant;
    final tb = t.admin.tableau;
    final String adressePieces = adresseCandidaturesFiltree(filtrePieces);
    final int nbPieces = attentes?.pieceAValider.nombre ?? 0;

    // Les cases-chiffres de l'academie. Discretes a zero (un filet), une
    // teinte seulement quand le nombre demande un geste ; l'alerte franche
    // est reservee aux incidents.
    Widget lumiere(MotifDirection? motif, Widget c) => motif == null
        ? c
        : LumiereAutour(
            nature: widget.lumieres[motif],
            arrondi: AppRadius.arrondiLg,
            child: c,
          );
    Widget chiffre(
      Key cle,
      int n,
      String libelle,
      AppIcon icone,
      String adresse, {
      bool alerte = false,
      bool compacte = false,
      MotifDirection? motif,
    }) => lumiere(
      motif,
      CaseNombre(
        key: cle,
        nombre: n,
        libelle: libelle,
        icone: icone,
        paire: alerte ? palette.washAlert : palette.washWarning,
        filet: n == 0,
        compacte: compacte,
        onPress: () => _ouvrir(adresse),
      ),
    );
    final bool avecNoms =
        widget.nomsDossiers.isNotEmpty || widget.dossiersErreur != null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        // Un texte agrandi a besoin de cases plus larges : la largeur compte
        // a l'echelle du texte (x2 a 1440 : une colonne, comme avant).
        final double utile =
            c.maxWidth / MediaQuery.textScalerOf(context).scale(1);
        final bool quatre = utile >= BentoVivant.seuilQuatre;
        final bool deux = utile >= BentoVivant.seuilDeux;
        final bool paires = utile >= BentoVivant.seuilPaires;

        final Widget heros = HerosPraxis(
          key: BentoVivant.cleHeros,
          phrase: widget.phrase,
          maintenant: widget.maintenant,
          attentes: attentes,
          creneaux: widget.creneaux,
          regard: _regard,
          grand: deux,
          date: deux ? widget.date : null,
          hauteurMin: quatre ? BentoVivant.hauteurRang : (deux ? 288 : 0),
          gestes: <GestePraxis>[
            if (attentes != null && attentes.creneauxOuverts == 0)
              (
                libelle: v.ouvrirCreneaux,
                adresse: Routes.adminPersonnesCreneauxEntretien,
                principal: true,
              ),
            if (nbPieces > 0)
              (
                libelle: v.verifierPieces(n: nbPieces),
                adresse: adressePieces,
                principal: false,
              ),
            if (messages > 0)
              (
                libelle: v.repondreMessages(n: messages),
                adresse: Routes.adminCommunicationsMessages,
                principal: false,
              ),
          ],
          onOuvrir: _ouvrir,
        );
        final Widget? pieces = attentes == null
            ? null
            : CasePieces(
                key: BentoVivant.clePieces,
                attente: attentes.pieceAValider,
                maintenant: widget.maintenant,
                lignes: widget.pieces,
                plusAncienneDabord: widget.piecesPlusAncienneDabord,
                hauteurMin: deux ? BentoVivant.hauteurRang : 0,
                onOuvrirFile: () => _ouvrir(adressePieces),
                // Une personne ouvre SON dossier, dans la file des pieces.
                onOuvrirDossier: (LigneCandidature l) =>
                    _ouvrir(adresseDossierDansLesPieces(l.reference)),
              );
        final Widget? caseMessages = messages <= 0
            ? null
            : _CaseMessages(
                key: BentoVivant.cleMessages,
                nombre: messages,
                dernier: widget.dernierMessage,
                onPress: () => _ouvrir(Routes.adminCommunicationsMessages),
              );
        final Widget? caseCourriels = courriels == null
            ? null
            : _CaseCourriels(
                key: BentoVivant.cleCourriels,
                etat: courriels,
                etiree: deux,
                onPress: () => _ouvrir(Routes.adminOperationsCourriels),
              );
        final List<Widget> petites = <Widget>[?caseMessages, ?caseCourriels];
        final Widget? colonnePetites = petites.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: <Widget>[
                  for (final Widget p in petites) Expanded(child: p),
                ],
              );

        final Widget dossiers = lumiere(
          MotifDirection.dossiers,
          _CaseDossiers(
            key: BentoVivant.cleDossiers,
            nombre: widget.dossiers,
            noms: widget.nomsDossiers,
            erreur: widget.dossiersErreur,
            enLigne: deux,
            onPress: () => _ouvrir(Routes.adminPersonnesDossiers),
          ),
        );
        Widget demandes({bool compacte = false}) => chiffre(
          BentoVivant.cleDemandes,
          ind.demandesEnAttente,
          tb.demandes,
          AppIcons.attribution,
          Routes.adminOperationsDemandes,
          compacte: compacte,
          motif: MotifDirection.demandes,
        );
        Widget eleves({bool compacte = false}) => chiffre(
          BentoVivant.cleEleves,
          ind.foyersSansEnseignant,
          tb.foyers,
          AppIcons.classes,
          Routes.adminOperationsRegroupements,
          compacte: compacte,
        );
        Widget cahiers({bool compacte = false}) => chiffre(
          BentoVivant.cleCahiers,
          ind.rapportsManquants,
          tb.rapports,
          AppIcons.historique,
          Routes.adminPedagogieQualite,
          compacte: compacte,
        );
        Widget incidents({bool compacte = false}) => chiffre(
          BentoVivant.cleIncidents,
          ind.incidents24h,
          tb.incidents,
          AppIcons.oeil,
          Routes.adminSecuriteAuditIncidents,
          alerte: true,
          compacte: compacte,
          motif: MotifDirection.incidents,
        );
        Widget echus({bool compacte = false}) => chiffre(
          BentoVivant.cleEchus,
          ind.comptesEchus,
          tb.comptes,
          AppIcons.verrou,
          Routes.adminPersonnesComptesEchus,
          compacte: compacte,
        );
        Widget pile2(Widget a, Widget b) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: <Widget>[
            Expanded(child: a),
            Expanded(child: b),
          ],
        );
        _Rang paire(Widget a, Widget b) =>
            _Rang(cases: <(int, Widget)>[(1, a), (1, b)]);

        final List<Widget> blocs = <Widget>[
          // La place de Praxis, assis sur le bord de sa case.
          SizedBox(height: HerosPraxis.assise(grand: deux)),
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
          ] else ...<Widget>[heros, ?pieces],
          if (attentes != null)
            ParcoursCandidats(
              attentes: attentes,
              maintenant: widget.maintenant,
              visages: widget.visages,
              onOuvrir: _ouvrir,
            ),
          if (!deux) ...petites,
          if (quatre) ...<Widget>[
            if (avecNoms) ...<Widget>[
              _Rang(
                cases: <(int, Widget)>[
                  (2, dossiers),
                  (1, demandes()),
                  (1, eleves()),
                ],
              ),
              _Rang(
                cases: <(int, Widget)>[
                  (1, cahiers()),
                  (1, pile2(incidents(compacte: true), echus(compacte: true))),
                  (2, widget.activite(deuxColonnes: true)),
                ],
              ),
            ] else ...<Widget>[
              _Rang(
                cases: <(int, Widget)>[
                  (1, dossiers),
                  (1, demandes()),
                  (1, eleves()),
                  (1, cahiers()),
                ],
              ),
              _Rang(
                cases: <(int, Widget)>[
                  (1, incidents()),
                  (1, echus()),
                  (2, widget.activite(deuxColonnes: true)),
                ],
              ),
            ],
          ] else if (paires) ...<Widget>[
            if (avecNoms) ...<Widget>[
              dossiers,
              paire(demandes(), eleves()),
              paire(cahiers(), incidents()),
              echus(),
            ] else ...<Widget>[
              paire(dossiers, demandes()),
              paire(eleves(), cahiers()),
              paire(incidents(), echus()),
            ],
            widget.activite(deuxColonnes: deux),
          ] else ...<Widget>[
            dossiers,
            demandes(),
            eleves(),
            cahiers(),
            incidents(),
            echus(),
            widget.activite(deuxColonnes: false),
          ],
          ?widget.alertes,
          if (widget.outils.isNotEmpty)
            _CaseOutils(
              key: BentoVivant.cleOutils,
              outils: widget.outils,
              parDeux: paires,
              onOuvrir: _ouvrir,
            ),
        ];
        // Praxis suit le pointeur des yeux ; un toucher le reveille aussi.
        return Listener(
          onPointerDown: (PointerEvent e) => _regard.value = e.position,
          onPointerHover: (PointerEvent e) => _regard.value = e.position,
          behavior: HitTestBehavior.translucent,
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
    this.marge = const EdgeInsets.all(margeCase),
  });

  /// Le rayon d'une case.
  static const double rayon = AppRadius.lg;

  /// La marge interieure d'une case.
  static const double margeCase = AppSpacing.lg;

  /// La largeur de lecture d'un texte suivi dans une case : une ligne ne
  /// depasse jamais 800 points sur ordinateur (garde du bureau, B4).
  static const double largeurLecture = 640;

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

  /// Un filet au lieu d'un fond (case discrete : rien n'attend).
  final bool filet;

  /// La hauteur minimale.
  final double hauteurMin;

  /// La marge interieure ; nulle quand le contenu va jusqu'au bord (l'eau).
  final EdgeInsetsGeometry marge;

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
              child: Padding(padding: marge, child: child),
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

/// L'icone d'une case, dans un disque de la teinte de son encre.
class _DisqueIcone extends StatelessWidget {
  const _DisqueIcone({required this.icone, required this.encre});

  final AppIcon icone;
  final Color encre;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppSpacing.section,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: encre.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icone.repos, size: AppSpacing.xl, color: encre),
    ),
  );
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
    this.filet = false,
    this.compacte = false,
  });

  /// Le nombre.
  final int nombre;

  /// Ce qu'il compte.
  final String libelle;

  /// Une precision.
  final String? detail;

  /// L'icone, en haut au bord de fin.
  final AppIcon icone;

  /// Le fond et son encre.
  final AppColorPair paire;

  /// Le geste.
  final VoidCallback? onPress;

  /// Case discrete : un filet, pas de fond (rien n'attend).
  final bool filet;

  /// Case basse : le nombre et son libelle sur une ligne (deux cases
  /// empilees dans la hauteur d'une seule).
  final bool compacte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Sur un filet, la case est posee sur la page : l'encre de la page.
    final Color encre = filet
        ? palette.surfaceCanvas.onBackground
        : paire.onBackground;
    final TextStyle petit = (textes.bodySmall ?? const TextStyle()).copyWith(
      color: encre,
    );
    final Widget nombreVu = NombreRouleaux(
      nombre,
      style: (textes.displaySmall ?? const TextStyle()).copyWith(color: encre),
    );
    final Widget texte = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(libelle, style: AppTypography.graisse(petit, FontWeight.w600)),
        if (detail != null) Text(detail!, style: petit),
      ],
    );
    return CaseVivante(
      paire: paire,
      onPress: onPress,
      filet: filet,
      hauteurMin: compacte ? 0 : 128,
      // Le nombre et ce qu'il compte d'abord (« 3 Dossiers à valider »),
      // puis les precisions.
      libelleSemantique: <String>['$nombre $libelle', ?detail].join(', '),
      child: compacte
          ? Row(
              children: <Widget>[
                nombreVu,
                Ecart.hMd,
                Expanded(child: texte),
                _DisqueIcone(icone: icone, encre: encre),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: nombreVu),
                    _DisqueIcone(icone: icone, encre: encre),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: texte,
                ),
              ],
            ),
    );
  }
}

/// « Dossiers à valider » : le nombre ouvre la file ; chaque nom ouvre SON
/// dossier (contrat de navigation §2 : une personne ouvre son dossier, un
/// nombre ouvre sa liste).
class _CaseDossiers extends StatelessWidget {
  const _CaseDossiers({
    required this.nombre,
    required this.noms,
    required this.enLigne,
    required this.onPress,
    super.key,
    this.erreur,
  });

  final int nombre;
  final List<NomDossier> noms;
  final String? erreur;
  final bool enLigne;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String libelle = t.admin.tableau.dossiers;
    final String? phrase = erreur;
    if (noms.isEmpty && phrase == null) {
      return CaseNombre(
        nombre: nombre,
        libelle: libelle,
        icone: AppIcons.dossiers,
        paire: palette.washWarning,
        filet: nombre == 0,
        onPress: onPress,
      );
    }
    final AppColorPair paire = palette.washWarning;
    final Color encre = paire.onBackground;
    final TextStyle petit = (textes.bodySmall ?? const TextStyle()).copyWith(
      color: encre,
    );
    // L'en-tete (le nombre et ce qu'il compte) ouvre la file.
    final Widget entete = ToucherVivant(
      onPress: onPress,
      libelleSemantique: '$nombre $libelle',
      arrondiFocus: AppRadius.arrondiSm,
      enfoncement: 0.97,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              _DisqueIcone(icone: AppIcons.dossiers, encre: encre),
            ],
          ),
          Ecart.vSm,
          Text(libelle, style: AppTypography.graisse(petit, FontWeight.w600)),
        ],
      ),
    );
    // Les plus anciens : chaque nom ouvre SON dossier, cible entiere.
    final Widget lignes = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (phrase != null) Text(phrase, style: petit),
        for (final NomDossier n in noms)
          LienFleche(
            libelle: n.libelle,
            alignerEnDebut: true,
            legende: true,
            encre: (TextStyle base) => base.copyWith(color: encre),
            onPress: n.onOuvrir,
          ),
      ],
    );
    return CaseVivante(
      paire: paire,
      child: enLigne
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: entete),
                Ecart.hLg,
                Expanded(flex: 2, child: lignes),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[entete, Ecart.vSm, lignes],
            ),
    );
  }
}

/// Les conversations non lues : une case pleine, a la couleur d'accent
/// (violet en clair, lavande en sombre). Le dernier message y est cite.
class _CaseMessages extends StatelessWidget {
  const _CaseMessages({
    required this.nombre,
    required this.onPress,
    super.key,
    this.dernier,
  });

  final int nombre;
  final (String, String)? dernier;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = palette.surfacePrimary;
    final Color encre = paire.onBackground;
    final TextStyle petit = (textes.bodySmall ?? const TextStyle()).copyWith(
      color: encre,
    );
    final String libelle = t.admin.tableau.vivant.messagesNonLus;
    final (String, String)? d = dernier;
    final String? citation = d == null ? null : '${d.$1} · ${d.$2}';
    return CaseVivante(
      paire: paire,
      onPress: onPress,
      libelleSemantique: <String>['$nombre $libelle', ?citation].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              NombreRouleaux(
                nombre,
                style: (textes.displaySmall ?? const TextStyle()).copyWith(
                  color: encre,
                ),
              ),
              Ecart.hMd,
              Expanded(
                child: Text(
                  libelle,
                  style: AppTypography.graisse(petit, FontWeight.w600),
                ),
              ),
              Icon(
                AppIcons.flecheAction.repos,
                size: AppSpacing.xl,
                color: encre,
              ),
            ],
          ),
          if (d != null && citation != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: encre.withValues(alpha: 0.16),
                  // Rayon interieur = rayon de la case moins sa marge.
                  shape: AppRadius.coinContinu(
                    AppRadius.interieur(
                      CaseVivante.rayon,
                      CaseVivante.margeCase,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: <Widget>[
                      AvatarNom(
                        prenom: d.$1,
                        disposition: DispositionAvatar.vertical,
                        diametre: AppAvatar.petit,
                        afficherNom: false,
                      ),
                      Ecart.hSm,
                      Expanded(
                        child: Text(
                          citation,
                          style: petit,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Les courriels des 24 heures : la case est un reservoir, l'eau monte avec
/// la part du plafond deja envoyee. Le texte reste au-dessus de l'eau.
class _CaseCourriels extends StatelessWidget {
  const _CaseCourriels({
    required this.etat,
    required this.etiree,
    required this.onPress,
    super.key,
  });

  final EtatFileCourriels etat;
  final bool etiree;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.admin.tableau.vivant;
    final AppColorPair paire = palette.surfaceRaised;
    final Color encre = paire.onBackground;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final double part = etat.parJour <= 0
        ? 0
        : (etat.partis24h / etat.parJour).clamp(0, 1);
    final String sur = v.courrielsSur(max: etat.parJour);
    final Widget eau = part <= 0
        ? const SizedBox.shrink()
        : NiveauEau(
            niveau: 0.12 + 0.82 * part,
            couleur: palette.surfacePrimary.background,
          );
    return CaseVivante(
      paire: paire,
      onPress: onPress,
      marge: EdgeInsets.zero,
      libelleSemantique: '${etat.partis24h} ${v.courriels}, $sur',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: etiree ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CaseVivante.margeCase,
              CaseVivante.margeCase,
              CaseVivante.margeCase,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NombreRouleaux(
                  etat.partis24h,
                  style: (textes.displaySmall ?? const TextStyle()).copyWith(
                    color: encre,
                  ),
                ),
                Text(
                  v.courriels,
                  style: AppTypography.graisse(doux, FontWeight.w600),
                ),
                Text(sur, style: doux),
              ],
            ),
          ),
          if (etiree)
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.titreEcran,
                ),
                child: eau,
              ),
            )
          else
            SizedBox(height: AppSpacing.respiration, child: eau),
        ],
      ),
    );
  }
}

/// Les destinations sans autre entree au telephone (le menu n'y montre pas
/// les pages d'un domaine) : une case d'outils, une tuile par page.
class _CaseOutils extends StatelessWidget {
  const _CaseOutils({
    required this.outils,
    required this.parDeux,
    required this.onOuvrir,
    super.key,
  });

  final List<OutilAccueil> outils;
  final bool parDeux;
  final ValueChanged<String> onOuvrir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    Widget tuile(OutilAccueil o) => BoutonOutil(
      key: o.cle,
      icone: o.icone,
      libelle: o.libelle,
      forme: FormeBoutonOutil.tuile,
      avecLibelle: true,
      lignesLibelle: 3,
      onPress: () => onOuvrir(o.adresse),
    );
    final int parRang = parDeux ? 2 : 1;
    return CaseVivante(
      paire: palette.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(t.admin.tableau.outils, style: textes.titleMedium),
          ),
          for (int i = 0; i < outils.length; i += parRang)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (int k = i; k < i + parRang; k++)
                    Expanded(
                      child: k < outils.length
                          ? tuile(outils[k])
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
