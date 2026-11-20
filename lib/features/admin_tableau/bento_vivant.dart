// VIVANT (directeur, 20/11/2026) : l'accueil de la direction, une seule page
// et une seule grammaire. Une grande case sombre ou Praxis, assis sur le
// bord, dit le blocage du moment, montre les sept prochains jours de creneaux
// d'entretien et propose les gestes ; une case haute (les pieces a valider) ;
// deux petites (conversations non lues, courriels des 24 heures en niveau
// d'eau) ; le parcours des candidats, chaque case large comme son nombre ;
// les cases-chiffres de l'academie ; la case large « Ce qui a changé ».
//
// **Donnees reelles uniquement.** Chaque case lit une lecture serveur qui
// existe deja ; une case sans lecture (capacite indisponible, echec) ne
// s'affiche pas. Aucun nombre d'exemple, aucun nombre affiche deux fois.
//
// Contrat de navigation §2 : une case qui porte un nombre ouvre la liste deja
// filtree, empilee (`push`), le filtre dans l'adresse.
import 'dart:async';
import 'dart:math' as math;

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
import '../../core/vivant/praxis_vivant.dart';
import '../../core/vivant/surface_penchee.dart';
import '../../core/vivant/toucher_vivant.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/halo_lumiere.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/lumiere_autour.dart';
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

/// La requete de la file des pieces a valider (meme tri que la liste).
const RequeteCandidatures requetePieces = RequeteCandidatures(
  filtre: filtrePieces,
);

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
    this.dossierDetail,
    this.attentes,
    this.messagesNonLus,
    this.dernierMessage,
    this.courriels,
    this.creneaux,
    this.piece,
    this.date,
    this.lumieres = const <MotifDirection, NatureHalo?>{},
  });

  /// Ce que dit Praxis.
  final PhrasePraxis phrase;

  /// L'instant courant (salutation, anciennete, semaine).
  final DateTime maintenant;

  /// Les six compteurs de l'academie, lus au serveur.
  final IndicateursAdmin indicateurs;

  /// Les dossiers d'identite a valider (ceux de la file affichee).
  final int dossiers;

  /// Le plus ancien dossier d'identite (nom et anciennete), s'il est lu.
  final String? dossierDetail;

  /// La case large « Ce qui a changé ».
  final Widget activite;

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

  /// La premiere candidature de la file des pieces a valider, si elle est lue.
  final LigneCandidature? piece;

  /// La date du jour, sur grand ecran.
  final String? date;

  /// Les lumieres des cases (LUMIERE-ACCUEILS 4), par motif.
  final Map<MotifDirection, NatureHalo?> lumieres;

  /// La largeur a partir de laquelle la grille a quatre colonnes.
  static const double seuilQuatre = 960;

  /// La largeur a partir de laquelle la grille a deux colonnes.
  static const double seuilDeux = 600;

  /// En dessous (telephone etroit, ou texte tres agrandi), les cases-chiffres
  /// ne vont plus par deux : une par ligne, aucun mot coupe.
  static const double seuilPaires = 300;

  /// La case sombre de Praxis.
  static const Key cleHeros = ValueKey<String>('vivant-heros');

  /// La date du jour, dans la case de Praxis.
  static const Key cleDate = ValueKey<String>('adm01-date');

  /// Le jour [i] (0 : aujourd'hui) de la semaine des creneaux.
  static Key cleJour(int i) => ValueKey<String>('vivant-jour-$i');

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

  /// Le cadenas entre « Entretien à planifier » et « Entretien planifié ».
  static const Key cleCadenas = ValueKey<String>('vivant-cadenas');

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
    final IndicateursAdmin ind = widget.indicateurs;
    final LigneCandidature? piece = widget.piece;
    final (String, String)? dernier = widget.dernierMessage;
    final v = t.admin.tableau.vivant;
    final tb = t.admin.tableau;
    final String adressePieces = adresseCandidaturesFiltree(filtrePieces);
    final int nbPieces = attentes?.pieceAValider.nombre ?? 0;

    final Widget? pieces = attentes == null
        ? null
        : CaseNombre(
            key: BentoVivant.clePieces,
            nombre: nbPieces,
            libelle: t.admin.candidatures.attentes.pieceAValider,
            detail: depuisQuand(
              attentes.pieceAValider.plusAncien,
              widget.maintenant,
            ),
            icone: AppIcons.dossiers,
            paire: palette.washAccent,
            filet: nbPieces == 0,
            // Une personne : son nom en carte, et le toucher ouvre son
            // dossier complet, dans la file des pieces.
            personne: piece == null
                ? null
                : (piece.nomComplet, piece.paysResidence),
            onPress: () => _ouvrir(
              piece == null
                  ? adressePieces
                  : Routes.adminPersonnesCandidaturePour(
                      piece.reference,
                      fileDeLaListe: requeteEnAdresse(requetePieces),
                    ),
            ),
          );
    final Widget? caseMessages = messages <= 0
        ? null
        : CaseNombre(
            key: BentoVivant.cleMessages,
            nombre: messages,
            libelle: v.messagesNonLus,
            detail: dernier == null ? null : '${dernier.$1} · ${dernier.$2}',
            detailSurUneLigne: true,
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

    // Les cases-chiffres de l'academie. Discretes a zero (un filet), une
    // teinte seulement quand le nombre demande un geste ; l'alerte franche
    // est reservee aux incidents.
    Widget chiffre(
      Key cle,
      int n,
      String libelle,
      AppIcon icone,
      String adresse, {
      String? detail,
      bool alerte = false,
      MotifDirection? motif,
    }) {
      final Widget c = CaseNombre(
        key: cle,
        nombre: n,
        libelle: libelle,
        detail: detail,
        icone: icone,
        paire: alerte ? palette.washAlert : palette.washWarning,
        filet: n == 0,
        onPress: () => _ouvrir(adresse),
      );
      return motif == null
          ? c
          : LumiereAutour(
              nature: widget.lumieres[motif],
              arrondi: AppRadius.arrondiLg,
              child: c,
            );
    }

    final List<Widget> chiffres = <Widget>[
      chiffre(
        BentoVivant.cleDossiers,
        widget.dossiers,
        tb.dossiers,
        AppIcons.dossiers,
        Routes.adminPersonnesDossiers,
        detail: widget.dossierDetail,
        motif: MotifDirection.dossiers,
      ),
      chiffre(
        BentoVivant.cleDemandes,
        ind.demandesEnAttente,
        tb.demandes,
        AppIcons.attribution,
        Routes.adminOperationsDemandes,
        motif: MotifDirection.demandes,
      ),
      chiffre(
        BentoVivant.cleEleves,
        ind.foyersSansEnseignant,
        tb.foyers,
        AppIcons.classes,
        Routes.adminOperationsRegroupements,
      ),
      chiffre(
        BentoVivant.cleCahiers,
        ind.rapportsManquants,
        tb.rapports,
        AppIcons.historique,
        Routes.adminPedagogieQualite,
      ),
      chiffre(
        BentoVivant.cleIncidents,
        ind.incidents24h,
        tb.incidents,
        AppIcons.oeil,
        Routes.adminSecuriteAuditIncidents,
        alerte: true,
        motif: MotifDirection.incidents,
      ),
      chiffre(
        BentoVivant.cleEchus,
        ind.comptesEchus,
        tb.comptes,
        AppIcons.verrou,
        Routes.adminPersonnesComptesEchus,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        // Un texte agrandi a besoin de cases plus larges : la largeur compte
        // a l'echelle du texte (x2 a 1440 : une colonne, comme avant).
        final double utile =
            c.maxWidth / MediaQuery.textScalerOf(context).scale(1);
        final bool quatre = utile >= BentoVivant.seuilQuatre;
        final bool deux = utile >= BentoVivant.seuilDeux;
        final Widget heros = _Heros(
          key: BentoVivant.cleHeros,
          phrase: widget.phrase,
          maintenant: widget.maintenant,
          attentes: attentes,
          creneaux: widget.creneaux,
          regard: _regard,
          grand: deux,
          date: deux ? widget.date : null,
          gestes: <(String, String)>[
            if (attentes != null && attentes.creneauxOuverts == 0)
              (v.ouvrirCreneaux, Routes.adminPersonnesCreneauxEntretien),
            if (nbPieces > 0) (v.verifierPieces(n: nbPieces), adressePieces),
            if (messages > 0)
              (
                v.repondreMessages(n: messages),
                Routes.adminCommunicationsMessages,
              ),
          ],
          onOuvrir: _ouvrir,
        );
        final Widget? colonnePetites = petites.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: <Widget>[
                  for (final Widget p in petites) Expanded(child: p),
                ],
              );
        _Rang paire(int i) => _Rang(
          cases: <(int, Widget)>[(1, chiffres[i]), (1, chiffres[i + 1])],
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
          if (quatre) ...<Widget>[
            _Rang(
              cases: <(int, Widget)>[
                for (final Widget x in chiffres.take(4)) (1, x),
              ],
            ),
            _Rang(
              cases: <(int, Widget)>[
                (1, chiffres[4]),
                (1, chiffres[5]),
                (2, widget.activite),
              ],
            ),
          ] else if (utile >= BentoVivant.seuilPaires) ...<Widget>[
            paire(0),
            paire(2),
            paire(4),
            widget.activite,
          ] else ...<Widget>[...chiffres, widget.activite],
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

/// Un rang de cases de meme hauteur : celle de la plus haute. Une part de 0
/// garde la largeur de son contenu (le cadenas du parcours).
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
          if (flex == 0) enfant else Expanded(flex: flex, child: enfant),
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

  /// Un filet au lieu d'un fond (case discrete : rien n'attend).
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
    this.detailSurUneLigne = false,
    this.onPress,
    this.niveau,
    this.filet = false,
    this.alerte,
    this.personne,
  });

  /// Le nombre.
  final int nombre;

  /// Ce qu'il compte.
  final String libelle;

  /// Une precision (anciennete, plafond, dernier message).
  final String? detail;

  /// La precision tient sur une ligne, coupee au besoin.
  final bool detailSurUneLigne;

  /// L'icone, en haut au bord de fin.
  final AppIcon icone;

  /// Le fond et son encre.
  final AppColorPair paire;

  /// Le geste.
  final VoidCallback? onPress;

  /// Le niveau d'eau.
  final double? niveau;

  /// Case discrete : un filet, pas de fond (rien n'attend).
  final bool filet;

  /// Une phrase d'alerte, avec un cadenas (jamais la couleur seule).
  final String? alerte;

  /// Une personne en carte : son nom, et une ligne (son pays).
  final (String, String?)? personne;

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
    final String? precision = alerte ?? detail;
    final (String, String?)? qui = personne;
    return CaseVivante(
      paire: paire,
      onPress: onPress,
      niveau: niveau,
      filet: filet,
      libelleSemantique: <String>[
        '$nombre',
        libelle,
        ?precision,
        ?qui?.$1,
      ].join(', '),
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
                if (qui != null) ...<Widget>[
                  // La personne, en carte dans la case : rayon interieur =
                  // rayon de la case moins sa marge.
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: palette.surfaceRaised.background,
                      shape: AppRadius.coinContinu(
                        AppRadius.interieur(
                          CaseVivante.rayon,
                          CaseVivante.marge,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: AvatarNom(
                        prenom: qui.$1,
                        role: qui.$2,
                        disposition: DispositionAvatar.enLigne,
                        diametre: AppAvatar.petit,
                      ),
                    ),
                  ),
                  Ecart.vMd,
                ],
                Text(
                  libelle,
                  style: AppTypography.graisse(petit, FontWeight.w600),
                ),
                if (precision != null)
                  Text(
                    precision,
                    style: petit,
                    maxLines: detailSurUneLigne ? 1 : null,
                    overflow: detailSurUneLigne ? TextOverflow.ellipsis : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La grande case sombre : l'en-tete de la page. Praxis est assis sur son
/// bord et dit le blocage du moment ; dessous, les sept prochains jours de
/// creneaux d'entretien, puis les gestes. Sombre dans les deux themes ; le
/// texte d'accent y est la lavande, jamais le violet.
class _Heros extends StatelessWidget {
  const _Heros({
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
  });

  /// La largeur de Praxis.
  static const double taillePraxis = 96;

  /// La part de Praxis qui depasse au-dessus de la case.
  static const double assise = 48;

  /// La taille de « Bonjour. » sur tablette et ordinateur (maquette : 48).
  static const double tailleSalut = 44;

  final PhrasePraxis phrase;
  final DateTime maintenant;
  final ValueNotifier<Offset> regard;
  final bool grand;
  final List<(String, String)> gestes;
  final ValueChanged<String> onOuvrir;
  final AttentesRecrutement? attentes;
  final List<CreneauDirection>? creneaux;
  final String? date;

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
    final TextStyle petit = (textes.bodySmall ?? const TextStyle()).copyWith(
      color: lavande,
    );
    final String? texte = phrase.texte;
    final AttentesRecrutement? a = attentes;
    final List<CreneauDirection>? liste = creneaux;
    final String? jour = date;
    final int heure = maintenant.hour;
    final String salut = heure < 12
        ? v.bonjour
        : heure < 18
        ? v.bonApresMidi
        : v.bonsoir;
    // Praxis est assis au-dessus du coin de fin : le haut du texte lui laisse
    // sa place, rien ne passe sous lui.
    // Au telephone, Praxis est plus petit et la phrase passe sous lui, sur
    // toute la largeur : aucun mot coupe a 320 en texte x2.
    final double largeurPraxis = grand ? taillePraxis : 80;
    final EdgeInsetsDirectional placePraxis = EdgeInsetsDirectional.only(
      end: largeurPraxis + AppSpacing.lg,
    );
    final TextStyle styleSalut = paire.applyTo(
      (grand ? textes.headlineLarge : textes.headlineMedium) ??
          const TextStyle(),
    );
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: <Widget>[
        CaseVivante(
          paire: paire,
          hauteurMin: 160,
          child: Column(
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
                      child: Text(jour, key: BentoVivant.cleDate, style: petit),
                    ),
                  Padding(
                    padding: placePraxis,
                    child: Semantics(
                      header: true,
                      // Une seule ligne, reduite si la place manque a cote
                      // de Praxis : « Bon après-midi. » ne se coupe jamais.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          salut,
                          maxLines: 1,
                          style: grand
                              ? styleSalut.copyWith(
                                  fontSize: tailleSalut,
                                  height: 1.1,
                                )
                              : styleSalut,
                        ),
                      ),
                    ),
                  ),
                  if (texte != null) ...<Widget>[
                    Ecart.vSm,
                    Padding(
                      padding: grand ? placePraxis : EdgeInsets.zero,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (a != null || liste != null) Ecart.vXl,
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
                      maintenant: maintenant,
                      paire: paire,
                      lavande: lavande,
                    ),
                  ],
                  if (gestes.isNotEmpty) ...<Widget>[
                    Ecart.vSm,
                    Wrap(
                      spacing: AppSpacing.lg,
                      children: <Widget>[
                        for (final (String libelle, String adresse) in gestes)
                          LienFleche(
                            libelle: libelle,
                            encre: (TextStyle base) =>
                                base.copyWith(color: lavande),
                            onPress: () => onOuvrir(adresse),
                          ),
                      ],
                    ),
                  ],
                ],
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
              taille: largeurPraxis,
              regard: regard,
            ),
          ),
        ),
      ],
    );
  }
}

/// Les sept prochains jours de creneaux d'entretien : un jour sans creneau
/// libre reste vide (un filet) ; un jour ouvert est plein et porte son nombre
/// (jamais la couleur seule).
class _Semaine extends StatelessWidget {
  const _Semaine({
    required this.creneaux,
    required this.maintenant,
    required this.paire,
    required this.lavande,
  });

  final List<CreneauDirection> creneaux;
  final DateTime maintenant;
  final AppColorPair paire;
  final Color lavande;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
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
              return SizedBox(
                key: BentoVivant.cleJour(i),
                width: AppSpacing.section,
                height: AppSpacing.titreEcran,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: ouvert ? lavande : null,
                    shape: AppRadius.coinContinu(
                      AppRadius.sm,
                      bordure: ouvert
                          ? BorderSide.none
                          : BorderSide(color: lavande.withValues(alpha: 0.35)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        t.commun.dates.jours[jour.weekday - 1].characters.first,
                        style: style,
                      ),
                      if (ouvert) Text('$n', style: style),
                    ],
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

/// Le parcours des candidats : une case par etat, large comme son nombre,
/// remplie comme un niveau d'eau. La ou rien ne passe (des entretiens a
/// planifier, aucun creneau ouvert), la case le dit et un cadenas ferme le
/// passage vers « Entretien planifié ».
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
    final bool ferme =
        attentes.etat(EtatCandidature.entretienAPlanifier).nombre > 0 &&
        attentes.creneauxOuverts == 0;
    String nom(EtatCandidature x) => switch (x) {
      EtatCandidature.aCompleter => e.aCompleter,
      EtatCandidature.enExamen => e.enExamen,
      EtatCandidature.paiementNonDisponible => e.versementImpossible,
      EtatCandidature.entretienAPlanifier => e.entretienAPlanifier,
      EtatCandidature.entretienPlanifie => e.entretienPlanifie,
      EtatCandidature.decisionEnAttente => e.decisionEnAttente,
    };
    final Widget cadenas = Center(
      child: Icon(
        AppIcons.verrou.repos,
        key: BentoVivant.cleCadenas,
        size: AppSpacing.xxl,
        color: palette.inkAlert.applyTo(const TextStyle()).color,
        semanticLabel: t.admin.candidatures.attentes.aucunCreneau,
      ),
    );
    final List<(int, Widget)> cases = <(int, Widget)>[
      for (final EtatCandidature x in etats) ...<(int, Widget)>[
        if (ferme && x == EtatCandidature.entretienPlanifie) (0, cadenas),
        () {
          final Attente at = attentes.etat(x);
          final bool bloque = ferme && x == EtatCandidature.entretienAPlanifier;
          final double part = math.sqrt(at.nombre / plusGrand);
          return (
            // Large comme son nombre, sans jamais devenir illisible.
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
      ],
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
