/// REMPL-1 : l'ecran « Remplacements », commun a tous les enseignants.
///
/// Demande du directeur (REMPL-1, 01/10, precisee le 09/10) :
///
/// - **l'alerte est une urgence** : chaque offre ouverte est une carte
///   d'alerte en tete d'ecran, avant tout autre bloc (ALERTE-1). Elle se
///   distingue par trois signaux cumules, jamais la couleur seule : surface
///   douce d'alerte (`washAlert`) a contour fort, icone d'avertissement, et le
///   mot « urgent » dans le titre ;
/// - **titre explicite** : « Remplacement urgent : {jour} {heure} », puis la
///   ligne « Un enseignant est absent. Assurez cette seance a sa place : elle
///   vous sera payee apres validation en fin de mois. », puis la Classe, la
///   date, l'heure locale, la duree et les eleves avant le bouton
///   (`lignesRemplacement`, UX_REVIEW_04 ligne 15, a) ;
/// - **premier arrive, premier servi** : le serveur tranche
///   ([PortRemplacements.prendre]). Une acceptation arrivee trop tard le dit
///   (« Un collegue a accepte cette seance juste avant vous ») et l'offre
///   passe dans « Deja pris par un collegue », sans bouton ;
/// - **visibilite par genre** : decidee et filtree cote serveur (decision du
///   02/10). L'ecran ne lit aucun genre.
///
/// L'ecran lit des capacites, jamais un role : le bouton n'existe que sur une
/// offre que le serveur dit `ouverte` et quand le port est present.
///
/// C'est la destination de « Voir tout : les N remplacements confirmes » de la
/// Journee ([Routes.enseignantRemplacements]) : « Vos remplacements » y
/// reprend les cartes `CarteRemplacement` confirmees.
///
/// Etats : chargement (`Skeleton` dans `BlocAsynchrone`), contenu, vide
/// (`EmptyState`), erreur (`EtatSysteme`, « Reessayer »), hors ligne (le
/// bandeau de `PageShell` ; un bloc `EtatSansDonnees` seulement si rien n'a
/// pu etre lu, EA-HL-DOUBLE-1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/enseignant/absence_remplacement.dart';
import '../../core/enseignant/port_remplacements.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../journee/absence_remplacement_vue.dart';
import '../journee/journee_page.dart' show dateLisible, trierRemplacements;

/// « Remplacement urgent : mardi 29 septembre 18:00 ».
String titreRemplacementUrgent(DateTime debut) {
  final String date = dateLisible(debut);
  return t.enseignant.remplacements.urgentTitre(
    // Au milieu d'une phrase, le jour s'ecrit en minuscule.
    jour: date.isEmpty ? date : date[0].toLowerCase() + date.substring(1),
    heure: hhmmAbsence(debut),
  );
}

/// « Remplacement en préparation : mardi 29 septembre 18:00 » (A3).
String titreRemplacementPreparation(DateTime debut) {
  final String date = dateLisible(debut);
  return t.enseignant.remplacements.preparationTitre(
    jour: date.isEmpty ? date : date[0].toLowerCase() + date.substring(1),
    heure: hhmmAbsence(debut),
  );
}

/// L'ecran « Remplacements ».
class RemplacementsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const RemplacementsPage({super.key});

  @override
  ConsumerState<RemplacementsPage> createState() => _RemplacementsPageEtat();
}

class _RemplacementsPageEtat extends ConsumerState<RemplacementsPage> {
  /// Les acceptations envoyees, sans reponse encore.
  final Set<String> _enCours = <String>{};

  /// Les acceptations restees sans reponse : rien n'est suppose (E7).
  final Set<String> _sansReponse = <String>{};

  /// Les offres qu'un collegue a prises avant l'enseignant, d'apres la
  /// reponse du serveur a SON acceptation.
  final Set<String> _priseAvantMoi = <String>{};

  /// La derniere acceptation confirmee, pour le dire une fois.
  String? _derniereAcceptee;

  /// A3 : les preparations ou un collegue s'est declare pret juste avant
  /// l'enseignant, d'apres la reponse du serveur a SON « Je suis pret ».
  final Set<String> _pretAvantMoi = <String>{};

  /// A3 : « Je suis pret » sur une preparation deja close.
  final Set<String> _preparationClose = <String>{};

  Future<void> _pret(PortPretRemplacement port, OffreRemplacement offre) async {
    final String id = offre.seanceId;
    setState(() {
      _enCours.add(id);
      _sansReponse.remove(id);
    });
    ResultatPret? reponse;
    try {
      reponse = await port.seDeclarerPret(id);
    } on Object {
      reponse = null;
    }
    if (!mounted) return;
    setState(() {
      _enCours.remove(id);
      switch (reponse) {
        case null:
          _sansReponse.add(id);
        case ResultatPret.dejaRetenu:
          _pretAvantMoi.add(id);
        case ResultatPret.fermee:
          _preparationClose.add(id);
        case ResultatPret.retenu:
          break;
      }
    });
    // Le serveur dit ce qui est retenu : le tableau se relit.
    if (reponse != null) ref.invalidate(offresCommunesProvider);
  }

  Future<void> _prendre(PortRemplacements port, OffreRemplacement offre) async {
    final String id = offre.seanceId;
    setState(() {
      _enCours.add(id);
      _sansReponse.remove(id);
    });
    ResultatPriseRemplacement? reponse;
    try {
      reponse = await port.prendre(id);
    } on Object {
      reponse = null;
    }
    if (!mounted) return;
    setState(() {
      _enCours.remove(id);
      switch (reponse) {
        case null:
          _sansReponse.add(id);
        case ResultatPriseRemplacement.dejaPrise:
          _priseAvantMoi.add(id);
        case ResultatPriseRemplacement.acceptee:
          _derniereAcceptee = id;
      }
    });
    // La carte « Remplacement » de la Journee n'apparait que sur la
    // confirmation du serveur (E7), comme depuis l'Alerte utile.
    if (reponse == ResultatPriseRemplacement.acceptee) {
      final List<OffreRemplacement> deja = ref.read(
        remplacementsConfirmesProvider,
      );
      if (!deja.any((OffreRemplacement o) => o.seanceId == id)) {
        ref.read(remplacementsConfirmesProvider.notifier).confirmer(offre);
      }
    }
  }

  void _retour() {
    final GoRouter routeur = GoRouter.of(context);
    if (routeur.canPop()) {
      routeur.pop();
    } else {
      routeur.go(Routes.enseignantJournee);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<OffreCommune>> offres = ref.watch(
      offresCommunesProvider,
    );
    final List<OffreRemplacement> confirmes = ref.watch(
      remplacementsConfirmesProvider,
    );
    final PortRemplacements? port = ref.watch(portRemplacementsProvider);
    final PortPretRemplacement? portPret = ref.watch(
      portPretRemplacementProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    void relire() => ref.invalidate(offresCommunesProvider);

    final Widget? mesConfirmes = confirmes.isEmpty
        ? null
        : _Section(
            titre: t.enseignant.remplacements.vosRemplacements,
            cartes: <Widget>[
              for (final OffreRemplacement o in trierRemplacements(confirmes))
                CarteRemplacement(offre: o, date: dateLisible(o.debut)),
            ],
          );

    return PageShell(
      titre: t.enseignant.remplacements.titre,
      sousTitre: t.enseignant.remplacements.contexte,
      onRetour: _retour,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: BlocAsynchrone<List<OffreCommune>>(
            key: const ValueKey<String>('remplacements-bloc'),
            valeur: offres,
            squelette: const Skeleton.liste(lignes: 3),
            onReessayer: relire,
            // Une source en echec n'emporte que ce qu'elle remplit (D11) :
            // les remplacements deja confirmes restent sous l'echec.
            piedEchec: mesConfirmes == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxl),
                    child: mesConfirmes,
                  ),
            erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
                ? EtatSansDonnees(
                    key: const ValueKey<String>('remplacements-sans-donnees'),
                    quoi: t.enseignant.remplacements.sansDonnees,
                    onAction: reessayer,
                  )
                : EtatSysteme(
                    key: const ValueKey<String>('remplacements-erreur'),
                    nature: NatureEtat.echecServeur,
                    phrase: t.enseignant.remplacements.erreur,
                    onAction: reessayer,
                  ),
            construire: (List<OffreCommune> lues) => _contenu(
              lues,
              confirmes: confirmes,
              port: port,
              portPret: portPret,
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenu(
    List<OffreCommune> lues, {
    required List<OffreRemplacement> confirmes,
    required PortRemplacements? port,
    required PortPretRemplacement? portPret,
  }) {
    final Set<String> miennes = <String>{
      for (final OffreRemplacement o in confirmes) o.seanceId,
    };
    final List<OffreRemplacement> ouvertes = <OffreRemplacement>[];
    final List<OffreRemplacement> prisesParMoi = <OffreRemplacement>[];
    final List<OffreRemplacement> prises = <OffreRemplacement>[];
    // A3 : la preparation d'un remplacement (titulaire pas encore entre).
    final List<OffreRemplacement> preparations = <OffreRemplacement>[];
    final List<OffreRemplacement> pretsMiens = <OffreRemplacement>[];
    final List<OffreRemplacement> pretsCollegues = <OffreRemplacement>[];
    for (final OffreCommune c in lues) {
      final String id = c.offre.seanceId;
      if (c.etat == EtatOffreCommune.preparation) {
        if (_pretAvantMoi.contains(id)) {
          pretsCollegues.add(c.offre);
        } else {
          preparations.add(c.offre);
        }
        continue;
      }
      if (c.etat == EtatOffreCommune.pretParMoi) {
        pretsMiens.add(c.offre);
        continue;
      }
      if (c.etat == EtatOffreCommune.pretParUnCollegue) {
        pretsCollegues.add(c.offre);
        continue;
      }
      if (c.etat == EtatOffreCommune.priseParMoi) {
        if (!miennes.contains(id)) prisesParMoi.add(c.offre);
      } else if (miennes.contains(id)) {
        continue;
      } else if (c.etat == EtatOffreCommune.priseParUnCollegue ||
          _priseAvantMoi.contains(id)) {
        prises.add(c.offre);
      } else {
        ouvertes.add(c.offre);
      }
    }

    // Rien a assurer, rien d'assure, rien de pris : une phrase.
    if (ouvertes.isEmpty &&
        prisesParMoi.isEmpty &&
        prises.isEmpty &&
        confirmes.isEmpty &&
        preparations.isEmpty &&
        pretsMiens.isEmpty &&
        pretsCollegues.isEmpty) {
      return EmptyState(
        key: const ValueKey<String>('remplacements-vide'),
        message: t.enseignant.journee.remplacementsVide,
        icone: AppIcons.cours,
      );
    }

    final List<OffreRemplacement> vosRemplacements = trierRemplacements(
      <OffreRemplacement>[...confirmes, ...prisesParMoi],
    );
    final List<Widget> sections = <Widget>[
      // ALERTE-1 : l'urgence en tete, avant tout autre bloc. Les plus proches
      // d'abord ; un seul bouton plein, sur la premiere (K-56).
      if (ouvertes.isNotEmpty)
        PileCartes(
          key: const ValueKey<String>('remplacements-urgents'),
          children: <Widget>[
            for (final (int i, OffreRemplacement o) in trierRemplacements(
              ouvertes,
            ).indexed)
              _CarteUrgente(
                offre: o,
                principale: i == 0,
                enCours: _enCours.contains(o.seanceId),
                sansReponse: _sansReponse.contains(o.seanceId),
                // Sans port, l'acceptation ne peut pas aboutir : pas de
                // bouton (jamais grise).
                onPrendre: port == null ? null : () => _prendre(port, o),
              ),
          ],
        ),
      // A3 : apres l'urgence, la preparation. Le bouton plein reste a la
      // premiere offre ouverte ; sans offre ouverte, a la premiere
      // preparation (K-56).
      if (preparations.isNotEmpty)
        PileCartes(
          key: const ValueKey<String>('remplacements-preparation'),
          children: <Widget>[
            for (final (int i, OffreRemplacement o) in trierRemplacements(
              preparations,
            ).indexed)
              _CarteUrgente(
                offre: o,
                preparation: true,
                principale: ouvertes.isEmpty && i == 0,
                enCours: _enCours.contains(o.seanceId),
                sansReponse: _sansReponse.contains(o.seanceId),
                close: _preparationClose.contains(o.seanceId),
                // Sans port, ou preparation close : pas de bouton (jamais
                // grise), la phrase dit pourquoi.
                onPrendre:
                    portPret == null || _preparationClose.contains(o.seanceId)
                    ? null
                    : () => _pret(portPret, o),
              ),
          ],
        ),
      if (pretsMiens.isNotEmpty)
        _Section(
          titre: t.enseignant.remplacements.pretTitre,
          cartes: <Widget>[
            for (final OffreRemplacement o in trierRemplacements(pretsMiens))
              _CartePrise(
                offre: o,
                avantMoi: false,
                pastille: t.enseignant.remplacements.pretPastille,
                phrase: t.enseignant.remplacements.pretPhrase,
              ),
          ],
        ),
      if (vosRemplacements.isNotEmpty)
        _Section(
          titre: t.enseignant.remplacements.vosRemplacements,
          annonce:
              _derniereAcceptee != null &&
                  vosRemplacements.any(
                    (OffreRemplacement o) => o.seanceId == _derniereAcceptee,
                  )
              ? t.enseignant.remplacements.acceptee
              : null,
          cartes: <Widget>[
            for (final OffreRemplacement o in vosRemplacements)
              CarteRemplacement(offre: o, date: dateLisible(o.debut)),
          ],
        ),
      if (prises.isNotEmpty || pretsCollegues.isNotEmpty)
        _Section(
          titre: t.enseignant.remplacements.prisTitre,
          cartes: <Widget>[
            for (final OffreRemplacement o in trierRemplacements(prises))
              _CartePrise(
                offre: o,
                avantMoi: _priseAvantMoi.contains(o.seanceId),
              ),
            for (final OffreRemplacement o in trierRemplacements(
              pretsCollegues,
            ))
              _CartePrise(
                offre: o,
                avantMoi: false,
                pastille: t.enseignant.remplacements.pretCollegue,
                phrase: _pretAvantMoi.contains(o.seanceId)
                    ? t.enseignant.remplacements.pretAvantVous
                    : null,
              ),
          ],
        ),
    ];
    return Column(
      key: const ValueKey<String>('remplacements-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < sections.length; i++) ...<Widget>[
          // Section vers section suivante, mobile : 24 (contrat A).
          if (i > 0) Ecart.vXxl,
          sections[i],
        ],
      ],
    );
  }
}

/// Une section : son titre, une annonce eventuelle, ses cartes detachees.
class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.cartes, this.annonce});

  final String titre;
  final String? annonce;
  final List<Widget> cartes;

  @override
  Widget build(BuildContext context) {
    final String? texte = annonce;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: titre),
        Ecart.vSm,
        if (texte != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              texte,
              key: const ValueKey<String>('remplacements-acceptee'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Ecart.vLg,
        ],
        PileCartes(children: cartes),
      ],
    );
  }
}

/// La carte d'alerte d'une offre ouverte (ALERTE-1, REMPL-1).
class _CarteUrgente extends StatelessWidget {
  const _CarteUrgente({
    required this.offre,
    this.preparation = false,
    this.close = false,
    required this.principale,
    required this.enCours,
    required this.sansReponse,
    required this.onPrendre,
  });

  final OffreRemplacement offre;

  /// A3 : vrai pour une preparation (« Je suis prêt ») au lieu d'une offre
  /// ouverte (« Assurer ce remplacement »).
  final bool preparation;

  /// A3 : la preparation est close (reponse du serveur) : une phrase le dit.
  final bool close;

  /// Vrai pour la plus proche : son bouton est le seul plein de l'ecran.
  final bool principale;
  final bool enCours;
  final bool sansReponse;
  final VoidCallback? onPrendre;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.washAlert;
    final List<LigneCleValeur> lignes = lignesRemplacement(
      offre,
      date: dateLisible(offre.debut),
      heureLocale: true,
    );
    final VoidCallback? prendre = onPrendre;
    return AppCard(
      key: ValueKey<String>('remplacement-urgent-${offre.seanceId}'),
      surface: paire,
      contourFort: true,
      entete: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconTheme(
            data: IconThemeData(
              color: paire.onBackground,
              size: AppSpacing.xxl,
            ),
            child: ExcludeSemantics(child: Icon(AppIcons.avertissement.repos)),
          ),
          Ecart.hMd,
          Expanded(
            child: Semantics(
              header: true,
              child: TexteSansCoupure(
                preparation
                    ? titreRemplacementPreparation(offre.debut)
                    : titreRemplacementUrgent(offre.debut),
                style: paire.applyTo(textes.titleMedium ?? const TextStyle()),
              ),
            ),
          ),
        ],
      ),
      actions: prendre == null
          ? null
          : ActionPrincipale(
              key: ValueKey<String>(
                preparation
                    ? 'remplacement-pret-${offre.seanceId}'
                    : 'remplacement-prendre-${offre.seanceId}',
              ),
              libelle: preparation
                  ? t.enseignant.remplacements.jeSuisPret
                  : t.enseignant.journee.remplacement.assurer,
              niveau: principale
                  ? NiveauAction.principale
                  : NiveauAction.secondaire,
              enCours: enCours,
              onPress: prendre,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            preparation
                ? t.enseignant.remplacements.preparationPhrase
                : t.enseignant.remplacements.urgentPhrase,
            style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
          ),
          Ecart.vLg,
          for (int i = 0; i < lignes.length; i++) ...<Widget>[
            if (i > 0) Ecart.vSm,
            lignes[i],
          ],
          if (sansReponse || close) ...<Widget>[
            Ecart.vLg,
            Semantics(
              liveRegion: true,
              child: Text(
                close
                    ? t.enseignant.remplacements.preparationClose
                    : t.enseignant.journee.absence.echec,
                key: ValueKey<String>(
                  'remplacement-sans-reponse-${offre.seanceId}',
                ),
                style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une offre qu'un collegue a prise : la pastille le dit, sans bouton.
class _CartePrise extends StatelessWidget {
  const _CartePrise({
    required this.offre,
    required this.avantMoi,
    this.pastille,
    this.phrase,
  });

  /// A3 : la pastille a la place de « Pris par un collègue ».
  final String? pastille;

  /// A3 : une phrase sous le titre (pret retenu, collegue pret avant).
  final String? phrase;

  final OffreRemplacement offre;

  /// Vrai quand l'enseignant venait de l'accepter : la carte dit que rien
  /// n'a change pour lui.
  final bool avantMoi;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final List<LigneCleValeur> lignes = lignesRemplacement(
      offre,
      date: dateLisible(offre.debut),
    );
    return AppCard(
      key: ValueKey<String>('remplacement-pris-${offre.seanceId}'),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(
              offre.classeDistincte,
              style: textes.titleMedium ?? const TextStyle(),
            ),
          ),
          StatusPill(
            libelle: pastille ?? t.enseignant.remplacements.prisPastille,
            ton: TonEtat.neutre,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (avantMoi || phrase != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                phrase ?? t.enseignant.remplacements.prisAvantVous,
                key: ValueKey<String>(
                  'remplacement-pris-avant-vous-${offre.seanceId}',
                ),
                style: palette.inkStrong.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vLg,
          ],
          // Le nom est deja le titre de la carte.
          for (int i = 1; i < lignes.length; i++) ...<Widget>[
            if (i > 1) Ecart.vSm,
            lignes[i],
          ],
        ],
      ),
    );
  }
}
