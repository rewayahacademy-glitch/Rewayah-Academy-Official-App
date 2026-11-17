/// `ADM-20` : la file des candidatures de la direction, sous Personnes.
///
/// Elle remplace l'onglet Invitations de Personnes (`DEC:27` : pas de septieme
/// onglet) sans casser les invitations existantes : la page des invitations
/// reste atteignable par un lien (`CAND-F01`).
///
/// **Tout vient du serveur, rien n'est recalcule ici** : la portee de genre (une
/// candidature hors portee n'apparait ni dans la liste ni dans un compteur), le
/// filtre, le tri, la pagination de 50, le total reel du filtre, les compteurs
/// d'etapes et les quatre alertes. L'ecran lit ces champs. Les droits (gestes,
/// exception de lecture du super-admin) sont des capacites lues au serveur
/// (`capacites_candidatures`), jamais un role.
///
/// **Ce que le serveur sert aujourd'hui, et rien de plus** : le tri par derniere
/// activite et par date de reception ; les filtres etape (puces des salles), etat,
/// issue, pause, versement, pays de residence ; la recherche (nom, reference,
/// courriel entier). Ce que la fiche prevoit au-dela (tri « Besoin, niveau,
/// disponibilite », date d'entretien, filtres responsable, besoin ouvert,
/// provenance, alerte posee en filtre, etat du courriel, entretien de la ligne)
/// n'est pas rendu : un controle qui ne peut pas aboutir n'est pas affiche.
///
/// Etats : chargement (`Skeleton` dans `BlocAsynchrone`), contenu, vide, aucun
/// resultat (filtres rappeles, « Effacer les filtres »), erreur
/// (« Reessayer »), hors ligne (bandeau de `PageShell`, la derniere lecture
/// reste, `EtatSansDonnees` quand rien n'a pu etre lu), capacite indisponible,
/// acces refuse, genre du lecteur inconnu, exception du super-admin, mode
/// selection, alertes a zero, compteur non servi.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/admin_domaine.dart';
import '../../core/candidature/attentes_recrutement.dart';
import '../../core/candidature/creneaux_direction.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/modeles_lot_candidatures.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/candidature/port_invitations_personnelles.dart';
import '../../core/candidature/port_prevenir_candidats.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/recrutement/port_invitations_comptable.dart';
import '../../core/recrutement/port_invitations_enseignant.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/est_associe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/vus/vus_compte.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/barre_selection.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_candidature/entretiens_du_jour.dart';
import '../admin_candidature/feuille_geste.dart';
import '../admin_candidature/gestes_proposes.dart';
import '../admin_candidature/libelles_candidature.dart';
import '../admin_import_formulaires/routes_candidats_flux.dart';
import 'adresse_candidatures.dart';
import 'feuille_filtres.dart';
import 'files_candidatures.dart';
import 'invitations_personnelles.dart';
import 'libelles_candidatures.dart';
import 'ligne_candidature.dart';
import 'lot_candidatures.dart';
import 'menu_ligne_candidature.dart';
import 'prevenir_candidats.dart';

/// L'ecran « Candidatures ».
class CandidaturesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  ///
  /// [ouvrirCandidature] mene au detail d'une candidature (`ADM-21`) ; sans
  /// lui, la ligne n'est pas pressable hors selection.
  ///
  /// Le traitement groupe (LISTES-1, ex `ADM-22`, REPRISE-CAND-1 du
  /// 08/11/2026) vit dans la page : le mode selection est offert des que le
  /// serveur ouvre l'action en lot (`peutAgirEnLot`), et la barre propose les
  /// gestes du lot que les capacites ouvrent (mettre en pause, lever la pause,
  /// refuser), chacun dans la feuille `ouvrirFeuilleLot`.
  ///
  /// [requete] est la requete d'adresse (BE-LISTE) : filtre, tri, page et
  /// recherche y sont lus et reportes, comme Comptes.
  const CandidaturesPage({
    super.key,
    this.ouvrirCandidature,
    this.requete = const <String, String>{},
  });

  /// Les parametres de l'adresse de la liste.
  final Map<String, String> requete;

  /// Ouvre une candidature, ou `null` : la ligne ne s'ouvre pas.
  final void Function(LigneCandidature ligne)? ouvrirCandidature;

  /// La cle de la barre du traitement groupe.
  static const Key cleBarreLot = ValueKey<String>('candidatures-barre-lot');

  /// Le retour de la page apres un lot : le compte rendu par le serveur.
  static const Key cleRetourLot = ValueKey<String>('candidatures-retour-lot');

  /// La lecture du dossier avant un geste du menu d'une ligne.
  static const Key cleOuverture = ValueKey<String>('candidatures-ouverture');

  /// L'echec d'un geste du menu d'une ligne.
  static const Key cleEchecLigne = ValueKey<String>('candidatures-echec-ligne');

  /// La cle de l'operation de lot [geste] dans la barre.
  static Key cleOperationLot(GesteLot geste) =>
      ValueKey<String>('candidatures-lot-${geste.name}');

  /// BE-LISTE : le menu « Outils » de la liste.
  static const Key cleOutils = ValueKey<String>('candidatures-outils');

  /// BE-LISTE-2 : l'icone « Filtres ».
  static const Key cleFiltres = ValueKey<String>('candidatures-filtres');

  /// BE-LISTE-2 : le nombre de filtres poses, sur l'icone « Filtres ».
  static const Key cleNombreFiltres = ValueKey<String>(
    'candidatures-filtres-nombre',
  );

  /// BE-LISTE-2 : l'icone « Trier ».
  static const Key cleTri = ValueKey<String>('candidatures-tri');

  /// BE-LISTE-2 : la loupe, qui ouvre le champ de recherche.
  static const Key cleLoupe = ValueKey<String>('candidatures-loupe');

  /// BE-LISTE-2 : « J'ai compris », qui ferme le bandeau.
  static const Key cleJaiCompris = ValueKey<String>('candidatures-jai-compris');

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('candidatures-page');

  @override
  ConsumerState<CandidaturesPage> createState() => _CandidaturesPageEtat();
}

class _CandidaturesPageEtat extends ConsumerState<CandidaturesPage> {
  /// Le filtre courant : recherche, etape, etat, issue, pause, versement, pays.
  late FiltreCandidatures _filtre;

  /// Le tri, fait au serveur.
  late TriCandidatures _tri;

  /// La page courante, a partir de 1. Revient a 1 a chaque changement de
  /// filtre ou de tri.
  late int _page;

  /// La derniere page lue : ses compteurs (toute la portee, sans les autres
  /// filtres) restent affiches pendant qu'une autre page se charge.
  PageCandidatures? _derniere;

  /// Le nombre de « Toutes » : le total d'une page lue sans filtre, garde tant
  /// qu'on filtre (sinon la puce n'a pas de nombre).
  int? _totalToutes;

  /// La place que veut le titre-selecteur pour se lire entier (« Candidatures »
  /// avec son menu).
  static const double _largeurTitre = 176;

  late final TextEditingController _recherche;

  /// Vrai : le champ de recherche est ouvert (la loupe a ete touchee).
  bool _rechercheOuverte = false;

  /// Le champ se voit ouvert par la loupe, ou tant qu'un texte est cherche.
  bool get _rechercheVisible => _rechercheOuverte || _recherche.text.isNotEmpty;
  final GlobalKey _cleListe = GlobalKey(debugLabel: 'candidatures-liste');

  /// L'attente qui suit la derniere frappe : une page n'est demandee qu'une
  /// fois la saisie posee. Ce n'est pas un mouvement (aucune animation), donc
  /// pas un jeton d'`AppMouvement`.
  Timer? _attenteSaisie;

  static const Duration _delaiSaisie = Duration(
    microseconds: 300 * Duration.microsecondsPerMillisecond,
  );

  /// Le mode selection : la ligne coche sa case au lieu d'ouvrir.
  bool _enSelection = false;

  /// Le retour du dernier lot : dit seulement apres la reponse du serveur.
  String? _retour;

  /// Le nom de la candidature dont le dossier se lit avant un geste du menu,
  /// ou `null` (REPRISE-CAND-4).
  String? _ouverture;

  /// L'echec d'un geste du menu, dit en mots, ou `null` : rien n'a ete fait.
  String? _echecLigne;

  /// Les identifiants retenus, gardes d'une page a l'autre.
  final Set<String> _retenues = <String>{};

  @override
  void initState() {
    super.initState();
    final RequeteCandidatures r = requeteDepuisAdresse(widget.requete);
    _filtre = r.filtre;
    _tri = r.tri;
    _page = r.page;
    _recherche = TextEditingController();
  }

  /// L'adresse porte le filtre, le tri et la page, et go_router garde ce
  /// `State` d'une requete a l'autre : un lien ou un retour qui change
  /// l'adresse remet la liste dans l'etat qu'elle dit (entree « Candidatures »
  /// nue comprise). Une adresse deja celle de la liste ne fait rien.
  @override
  void didUpdateWidget(CandidaturesPage ancien) {
    super.didUpdateWidget(ancien);
    if (mapEquals(ancien.requete, widget.requete)) return;
    // Le texte cherche n'est pas dans l'adresse : il reste celui de la page.
    final RequeteCandidatures lue = requeteDepuisAdresse(widget.requete);
    final FiltreCandidatures filtreLu = lue.filtre.avec(
      recherche: _filtre.recherche,
    );
    final RequeteCandidatures ici = RequeteCandidatures(
      filtre: _filtre,
      tri: _tri,
      page: _page,
    );
    if (RequeteCandidatures(filtre: filtreLu, tri: lue.tri, page: lue.page) ==
        ici) {
      return;
    }
    _attenteSaisie?.cancel();
    setState(() {
      if (filtreLu != _filtre && _retenues.isNotEmpty) {
        _retenues.clear();
        _retour = t.admin.candidatures.lot.selectionRetiree;
      }
      _filtre = filtreLu;
      _tri = lue.tri;
      _page = lue.page;
    });
  }

  @override
  void dispose() {
    _attenteSaisie?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  /// Reporte filtre, tri et page dans l'adresse (lien partage, retour,
  /// rechargement) ; jamais le texte cherche. `replace` : la pile ne change pas, le retour ramene
  /// d'ou l'on vient, pas a l'etat precedent du filtre. Hors routeur (tests
  /// montes sans GoRouter), rien a faire.
  void _ecrireAdresse() {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur == null) return;
    final Uri actuelle = routeur.routerDelegate.currentConfiguration.uri;
    final Map<String, String> requete = <String, String>{
      for (final MapEntry<String, String> e in actuelle.queryParameters.entries)
        if (!clesAdresseCandidatures.contains(e.key)) e.key: e.value,
      ...requeteEnAdresse(
        RequeteCandidatures(filtre: _filtre, tri: _tri, page: _page),
      ),
    };
    if (mapEquals(requete, actuelle.queryParameters)) return;
    unawaited(
      routeur.replace<void>(
        Uri(
          path: actuelle.path,
          queryParameters: requete.isEmpty ? null : requete,
        ).toString(),
      ),
    );
  }

  void _chercher(String texte) {
    _attenteSaisie?.cancel();
    _attenteSaisie = Timer(_delaiSaisie, () {
      if (mounted) _filtrer(_filtre.avec(recherche: texte));
    });
  }

  void _chercherTout(String texte) {
    _attenteSaisie?.cancel();
    _filtrer(_filtre.avec(recherche: texte));
  }

  /// Pose un filtre (recherche comprise). Une selection faite sous l'ancien
  /// filtre ne dit plus ce qu'elle retient : elle est retiree, et la page le
  /// dit (`lot.selectionRetiree`), jamais en silence. Un filtre egal a
  /// l'actuel ne fait rien : ni selection retiree, ni retour a la premiere page.
  /// Le tri ne change pas les candidatures retenues : il garde la selection.
  void _filtrer(FiltreCandidatures filtre) {
    if (filtre == _filtre) return;
    setState(() {
      if (_retenues.isNotEmpty) {
        _retenues.clear();
        _retour = t.admin.candidatures.lot.selectionRetiree;
      }
      _filtre = filtre;
      _page = 1;
    });
    _ecrireAdresse();
  }

  void _effacer() {
    _attenteSaisie?.cancel();
    _recherche.clear();
    _filtrer(_filtre.efface);
  }

  void _relire() => ref
    ..invalidate(pageCandidaturesProvider)
    ..invalidate(capacitesCandidaturesProvider)
    ..invalidate(attentesRecrutementProvider);

  void _allerAPage(int numero) {
    setState(() => _page = numero);
    _ecrireAdresse();
    // Une nouvelle page commence en haut de la liste, pas au pied de la
    // precedente.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final BuildContext? c = _cleListe.currentContext;
      if (mounted && c != null && c.mounted) {
        unawaited(Scrollable.ensureVisible(c));
      }
    });
  }

  void _basculerLigne(LigneCandidature ligne) => setState(() {
    if (!_retenues.remove(ligne.id)) {
      _retenues.add(ligne.id);
    }
  });

  void _relacherTout() => setState(() {
    _retenues.clear();
    _enSelection = false;
  });

  void _basculerSelection() => setState(() {
    _retour = null;
    _enSelection = !_enSelection;
    if (!_enSelection) _retenues.clear();
  });

  // --- Un geste depuis le menu d'une ligne (REPRISE-CAND-4) --------------

  /// Le geste d'une ligne : lire le dossier (la ligne n'en porte ni la version
  /// ni les reponses), rappeler la table des gestes sur ce qu'on vient de lire,
  /// puis ouvrir **la meme feuille** que la fiche. Rien n'est fait si le geste
  /// n'est plus permis.
  Future<void> _gesteDeLigne(
    LigneCandidature ligne,
    GesteCandidature geste,
    CapacitesCandidatures capacites,
  ) async {
    if (_ouverture != null) return;
    final DemandeDossier demande = DemandeDossier(
      ligne.reference,
      id: ligne.id,
    );
    setState(() {
      _ouverture = nomAffiche(ligne);
      _echecLigne = null;
      _retour = null;
    });
    // Une lecture neuve : la version lue est celle d'aujourd'hui, jamais celle
    // d'un dossier garde en memoire.
    ref.invalidate(detailCandidatureProvider(demande));
    final ProviderSubscription<AsyncValue<DetailCandidature>> garde = ref
        .listenManual(
          detailCandidatureProvider(demande),
          (
            AsyncValue<DetailCandidature>? _,
            AsyncValue<DetailCandidature> _,
          ) {},
        );
    DetailCandidature? detail;
    try {
      detail = await ref.read(detailCandidatureProvider(demande).future);
    } on Object {
      detail = null;
    } finally {
      garde.close();
    }
    if (!mounted) return;
    final r = t.admin.candidatures.liste;
    if (detail == null) {
      setState(() {
        _ouverture = null;
        _echecLigne = r.dossierIllisible;
      });
      return;
    }
    setState(() => _ouverture = null);
    if (!gestePermis(geste, detail)) {
      final LigneCandidature lu = detail.ligne;
      setState(
        () => _echecLigne = r.gestePlusPossible(
          etat: libelleEtatCourant(
            issue: lu.issue,
            enPause: lu.enPause,
            etape: lu.etape,
            etat: lu.etat,
          ),
        ),
      );
      // La ligne a change depuis la derniere lecture : la liste se relit.
      _relire();
      return;
    }
    final SortieFeuille? sortie = await ouvrirFeuilleGeste(
      context,
      geste: geste,
      detail: detail,
      capacites: capacites,
    );
    if (!mounted || sortie == null) return;
    // Recherche, filtres, tri et page sont dans l'etat de cette page : la
    // relecture les garde.
    _relire();
    setState(
      () => _retour = sortie.issue == IssueFeuille.fait
          ? r.retourLigne(
              nom: nomAffiche(ligne),
              retour: sortie.rejoue
                  ? t.admin.candidatures.retours.rejoue
                  : libelleRetour(geste),
            )
          : null,
    );
  }

  // --- Le traitement groupe ----------------------------------------------

  Future<void> _lancerLot(GesteLot geste, CapacitesCandidatures caps) async {
    await ouvrirFeuilleLot(
      context,
      geste: geste,
      ids: _retenues.toList(),
      capacites: caps,
      onRapport: _apresLot,
    );
  }

  /// Le serveur a rendu son rapport : la liste se relit (filtres, tri et page
  /// gardes) et la selection est videe, que la feuille soit encore ouverte ou
  /// non. Le rapport ligne par ligne reste dans la feuille ; la page dit le
  /// compte, seulement apres la reponse du serveur (DECISION-FLUIDITE).
  void _apresLot(RapportLot rapport) {
    if (!mounted) return;
    _relire();
    setState(() {
      _retenues.clear();
      _enSelection = false;
      _retour = rapport.rejoue
          ? t.admin.candidatures.lot.feuille.rapport.rejoue
          : t.admin.candidatures.lot.feuille.rapport.reussies(
              n: rapport.reussies,
            );
    });
  }

  /// La barre du lot : le compte (« dont N sur cette page » quand une partie
  /// de la selection est sur d'autres pages), une operation par geste du lot
  /// que les capacites ouvrent, jamais grisee. Hors ligne ou au-dela du
  /// plafond du serveur, aucune operation : la phrase dit pourquoi.
  Widget _barreLot(
    PageCandidatures? page,
    CapacitesCandidatures caps,
    bool horsLigne,
  ) {
    final l = t.admin.candidatures.lot;
    final int n = _retenues.length;
    final int surLaPage =
        page?.lignes
            .where((LigneCandidature x) => _retenues.contains(x.id))
            .length ??
        n;
    final String titre = surLaPage < n
        ? l.avecDont(
            selection: l.selectionnees(n: n),
            dont: l.dontPage(n: surLaPage),
          )
        : l.selectionnees(n: n);
    final bool tropNombreuses = n > plafondLotCandidatures;
    return BarreSelection.compacte(
      key: CandidaturesPage.cleBarreLot,
      titre: titre,
      phrase: horsLigne
          ? t.admin.candidatures.selection.horsLigne
          : tropNombreuses
          ? l.plafond(n: plafondLotCandidatures)
          : l.autresGestes,
      onRelacher: _relacherTout,
      operations: <Widget>[
        if (!horsLigne && !tropNombreuses)
          for (final GesteLot g in GesteLot.values)
            if (caps.geste(g.geste.capacite))
              ActionPrincipale(
                key: CandidaturesPage.cleOperationLot(g),
                libelle: libelleGesteLot(g),
                niveau: g == GesteLot.refuser
                    ? NiveauAction.destructive
                    : NiveauAction.secondaire,
                compacte: true,
                pleineLargeur: false,
                onPress: () => _lancerLot(g, caps),
              ),
      ],
    );
  }

  // --- Rangees -------------------------------------------------------------

  /// BE-LISTE-2 : la ligne de texte sous les files, « 383 candidatures » a
  /// gauche, « Selectionner » a droite, alignes sur la meme ligne. Plus de
  /// bouton « Trier » ici : le tri est l'icone de la rangee de la recherche.
  Widget _ligneNombre(
    PageCandidatures page, {
    required bool selectionPossible,
  }) {
    final r = t.admin.candidatures;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    // Une seule ligne tant qu'elle tient (le nombre a gauche, « Selectionner » a
    // droite) ; a texte agrandi elle passe a la ligne plutot que de deborder.
    return Wrap(
      key: _cleListe,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        Semantics(
          header: true,
          liveRegion: true,
          child: TexteSansCoupure(
            r.total(n: page.total),
            key: const ValueKey<String>('candidatures-total'),
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        if (selectionPossible)
          LienFleche(
            key: const ValueKey<String>('candidatures-selectionner'),
            libelle: _enSelection
                ? r.selection.quitter
                : r.selection.selectionner,
            fleche: false,
            legende: true,
            alignerEnFin: true,
            onPress: _basculerSelection,
          ),
      ],
    );
  }

  /// Les files : **un seul menu deroulant « File »** (revision du 16/11,
  /// directeur : « cinq lignes pour ces filtres ? pourquoi pas un menu
  /// deroulant ? »). Il dit la file choisie et son nombre (« En examen · 176 »)
  /// et s'ouvre sur toutes les files avec leurs nombres. Les alertes que le
  /// serveur compte sans savoir les filtrer restent des pastilles d'etat, sous
  /// le menu, seulement quand leur nombre n'est pas zero.
  Widget _zoneFiles(List<FileCandidatures> files) {
    final List<FileCandidatures> choix = <FileCandidatures>[
      for (final FileCandidatures x in files)
        if (x.appliquer != null) x,
    ];
    final List<FileCandidatures> alertes = <FileCandidatures>[
      for (final FileCandidatures x in files)
        if (x.appliquer == null) x,
    ];
    final FileCandidatures? courante = choix
        .where((FileCandidatures x) => x.estChoisie(_filtre))
        .firstOrNull;
    final String texte = courante == null
        ? t.recrutement.file.fileMenu
        : '${courante.libelle} · ${courante.nombre ?? ''}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MenuFiltre<String>(
          key: const ValueKey<String>('candidatures-file-menu'),
          libelle: texte,
          valeur: courante?.cle,
          entrees: <EntreeFiltre<String>>[
            for (final FileCandidatures x in choix)
              EntreeFiltre<String>(
                valeur: x.cle,
                libelle: '${x.libelle} · ${x.nombre ?? ''}'.trim(),
              ),
          ],
          onChoix: (String? cle) {
            if (cle == null) return;
            final FileCandidatures x = choix.firstWhere(
              (FileCandidatures f) => f.cle == cle,
            );
            _attenteSaisie?.cancel();
            _filtrer(x.appliquer!(_filtre));
          },
        ),
        if (alertes.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final FileCandidatures x in alertes)
                StatusPill(
                  key: ValueKey<String>('candidatures-file-${x.cle}'),
                  libelle: '${x.libelle} ${x.nombre ?? ''}'.trim(),
                  ton: TonEtat.avertissement,
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// L'icone « Filtres » : le nombre de filtres poses se lit dessus et se dit.
  Widget _boutonFiltres(
    List<FileCandidatures> Function() files,
    CapacitesCandidatures caps,
  ) {
    final int n = nombreFiltresPoses(_filtre, files());
    final AppPalette palette = AppPalette.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        BoutonIcone(
          key: CandidaturesPage.cleFiltres,
          icone: AppIcons.filtrer,
          libelle: n == 0
              ? t.recrutement.file.filtres
              : t.recrutement.file.filtresPoses(n: n),
          selectionne: n > 0,
          onPress: () => unawaited(
            ouvrirFeuilleFiltres(
              context,
              lire: () => _filtre,
              poser: _filtrer,
              files: files,
              garderPourSuivi: caps.peutGarderPourSuivi,
            ),
          ),
        ),
        if (n > 0)
          PositionedDirectional(
            top: AppSpacing.xs,
            end: AppSpacing.xs,
            child: ExcludeSemantics(
              child: DecoratedBox(
                key: CandidaturesPage.cleNombreFiltres,
                decoration: palette.washAccent.decoration(
                  borderRadius: AppRadius.arrondiFull,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    '$n',
                    style: TextStyle(
                      color: palette.washAccent.onBackground,
                      fontSize: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// La loupe : le champ de recherche ne s'ouvre qu'au toucher.
  Widget _boutonRecherche() => BoutonIcone(
    key: CandidaturesPage.cleLoupe,
    icone: AppIcons.recherche,
    libelle: t.recrutement.file.rechercher,
    selectionne: _rechercheVisible,
    onPress: () => setState(() {
      // Ouverte et vide : on la referme ; avec un texte, le champ reste.
      _rechercheOuverte = _recherche.text.isNotEmpty || !_rechercheOuverte;
    }),
  );

  /// L'icone « Trier ».
  Widget _boutonTri() => BoutonIcone(
    key: CandidaturesPage.cleTri,
    icone: AppIcons.triNeutre,
    libelle: t.admin.candidatures.tri.titre,
    onPress: () => unawaited(
      ouvrirFeuilleTri(
        context,
        lire: () => _tri,
        poser: (TriCandidatures tri) {
          setState(() {
            _tri = tri;
            _page = 1;
          });
          _ecrireAdresse();
        },
      ),
    ),
  );

  // --- Liste --------------------------------------------------------------

  Widget _liste(PageCandidatures page, GestesLigne gestes) {
    final bool bureau =
        DataCollection.enTableau(context) &&
        MediaQuery.textScalerOf(context).scale(1) <= 1;
    if (bureau) {
      return DataCollection<LigneCandidature>(
        colonnes: colonnesCandidatures(gestes),
        lignes: page.lignes,
        defileAvecLaPage: true,
        cle: (LigneCandidature l) => cleCandidature(l.id),
        onSelectionner: gestes.auToucher,
        estSelectionnee: gestes.enSelection ? gestes.estRetenue : null,
        actionsLigne: gestes.menuRendu,
      );
    }
    return PileCartes(
      children: <Widget>[
        for (final LigneCandidature l in page.lignes)
          CarteCandidature(ligne: l, gestes: gestes),
      ],
    );
  }

  Widget _contenu(PageCandidatures page, GestesLigne gestes) {
    final r = t.admin.candidatures;
    if (page.lignes.isEmpty) {
      final String? rappel = rappelFiltres(_filtre);
      return EmptyState(
        key: const ValueKey<String>('candidatures-aucun-resultat'),
        message: r.aucunResultat,
        invitation: rappel,
        icone: AppIcons.rienAAfficher,
        libelleAction: t.admin.journal.effacerFiltres,
        onAction: _effacer,
      );
    }
    return Column(
      key: const ValueKey<String>('candidatures-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _liste(page, gestes),
        Ecart.vLg,
        TexteSansCoupure(
          r.resume(
            debut: '${page.debut}',
            fin: '${page.fin}',
            total: '${page.total}',
          ),
          key: const ValueKey<String>('candidatures-resume'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (page.pages > 1) ...<Widget>[
          Ecart.vSm,
          BarrePrecedentSuivant(
            key: const ValueKey<String>('candidatures-pagination'),
            position: t.commun.formats.pageSur(
              page: '${page.page}',
              total: '${page.pages}',
            ),
            positionSemantique: r.pagination.positionSemantique(
              page: '${page.page}',
              total: '${page.pages}',
            ),
            libellePrecedent: r.pagination.precedente,
            libelleSuivant: r.pagination.suivante,
            onPrecedent: page.page > 1
                ? () => _allerAPage(page.page - 1)
                : null,
            onSuivant: page.page < page.pages
                ? () => _allerAPage(page.page + 1)
                : null,
          ),
        ],
      ],
    );
  }

  /// Les etats propres a la file, avant le cas par defaut de [BlocAsynchrone].
  Widget? _etatErreur(Object erreur, VoidCallback? reessayer, bool horsLigne) {
    final r = t.admin.candidatures;
    if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        key: const ValueKey<String>('candidatures-indisponible'),
        nature: NatureEtat.indisponible,
        titre: t.commun.etats.branchementServeur,
        phrase: '',
        dependance: erreur.dependance,
      );
    }
    if (erreur is GenreLecteurInconnu) {
      return EtatSysteme(
        key: const ValueKey<String>('candidatures-genre-inconnu'),
        nature: NatureEtat.accesRefuse,
        titre: r.genreInconnuTitre,
        phrase: r.genreInconnu,
      );
    }
    if (erreur is PermissionInsuffisante) {
      return EtatSysteme(
        key: const ValueKey<String>('candidatures-acces-refuse'),
        nature: NatureEtat.accesRefuse,
        titre: r.accesRefuse,
        phrase: '',
      );
    }
    if (horsLigne) {
      return EtatSansDonnees(
        key: const ValueKey<String>('candidatures-sans-donnees'),
        quoi: r.sansDonnees,
        onAction: reessayer,
      );
    }
    return EtatSysteme(
      key: const ValueKey<String>('candidatures-erreur'),
      nature: NatureEtat.echecServeur,
      titre: r.lectureEchec,
      // Les essais epuises : la phrase le dit a la place du bouton.
      phrase: reessayer == null ? t.commun.etats.reessaisEpuises : '',
      onAction: reessayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RequeteCandidatures requete = RequeteCandidatures(
      filtre: _filtre,
      tri: _tri,
      page: _page,
    );
    final AsyncValue<PageCandidatures> valeur = ref.watch(
      pageCandidaturesProvider(requete),
    );
    // BE-2b : l'associe ne voit que la page des candidatures (le serveur filtre
    // ses dossiers sur ses missions).
    final bool associe = ref.watch(estAssocieProvider);
    if (valeur.hasValue) _derniere = valeur.requireValue;
    if (valeur.hasValue && _filtre.estVide) {
      _totalToutes = valeur.requireValue.total;
    }
    final PageCandidatures? reference = valeur.value ?? _derniere;
    final CapacitesCandidatures caps =
        ref.watch(capacitesCandidaturesProvider).value ??
        CapacitesCandidatures.aucune;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    // VISION-RECRUTEMENT : sans la lecture serveur (migration non installee,
    // erreur), la carte ne s'affiche pas ; la derniere lecture reste.
    final AttentesRecrutement? attentes = ref
        .watch(attentesRecrutementProvider)
        .value;
    final r = t.admin.candidatures;

    // Rien du tout dans la portee du lecteur (aucun filtre, zero candidature) :
    // ni alertes, ni recherche, ni filtres, seulement le constat.
    final bool porteeVide =
        valeur.hasValue && valeur.requireValue.total == 0 && _filtre.estVide;
    final bool commandes = reference != null && !porteeVide;

    // Le mode selection n'existe que s'il peut aboutir : le serveur ouvre
    // l'action en lot (capacite lue). Sans elle, ni le lien « Selectionner »
    // ni la barre ne sont rendus : une selection sur laquelle on ne peut rien
    // faire n'est pas offerte.
    final bool selectionPossible = caps.peutAgirEnLot;

    final void Function(LigneCandidature)? ouvrir = widget.ouvrirCandidature;
    // Hors ligne : seul le dossier s'ouvre, aucun geste n'est propose.
    final CapacitesCandidatures capsMenu = horsLigne
        ? CapacitesCandidatures.aucune
        : caps;
    final GestesLigne gestes = GestesLigne(
      enSelection: _enSelection && selectionPossible,
      retenues: _retenues,
      basculer: _basculerLigne,
      ouvrir: ouvrir,
      menu: (BuildContext _, LigneCandidature l) => MenuLigneCandidature(
        ligne: l,
        capacites: capsMenu,
        onOuvrir: ouvrir == null ? null : () => ouvrir(l),
        onGeste: (GesteCandidature g) => unawaited(_gesteDeLigne(l, g, caps)),
      ),
    );

    final bool invitations =
        ref.watch(portInvitationsEnseignantProvider) != null ||
        ref.watch(portInvitationsComptableProvider) != null;

    // CANDIDATS-FLUX (06/11/2026, porte de la PR 50) : « Prevenir par e-mail »
    // les personnes des formulaires importes, et l'import des formulaires.
    // Chaque lien n'est rendu que si le serveur ouvre le geste a ce lecteur et
    // que le port est servi, jamais grise.
    final bool prevenir =
        caps.geste('consignerPrevenu') &&
        ref.watch(portPrevenirCandidatsProvider) != null;
    // L'import : pour le super administrateur, que sa session soit deja en
    // double verification (`peutImporter`) ou qu'elle doive y monter au geste
    // (`doubleVerificationRequise`, la page d'import demande alors le code).
    final CapacitesImportCandidatures? capsImport = ref
        .watch(capacitesImportCandidaturesProvider)
        .value;
    final bool importer =
        ref.watch(portImportCandidaturesProvider) != null &&
        capsImport != null &&
        (capsImport.peutImporter || capsImport.doubleVerificationRequise);
    // SALLE-2-ENTRETIEN (07/11/2026) : les creneaux d'entretien, pour qui
    // decide d'une candidature, quand le port est servi.
    final bool creneaux =
        caps.peutDecider && ref.watch(portCreneauxDirectionProvider) != null;

    final List<EntreeAction> outils = <EntreeAction>[
      if (invitations)
        EntreeAction(
          libelle: t.recrutement.invitations.onglet,
          onChoix: () =>
              unawaited(context.push<void>(Routes.adminPersonnesInvitations)),
        ),
      if (prevenir)
        EntreeAction(
          libelle: t.candidatsFlux.prevenir.lien,
          onChoix: () => ouvrirFeuillePrevenir(context),
        ),
      if (creneaux)
        EntreeAction(
          libelle: t.admin.candidatures.creneaux.lien,
          onChoix: () => unawaited(
            context.push<void>(Routes.adminPersonnesCreneauxEntretien),
          ),
        ),
      // INVITATIONS-PERSONNELLES (lot 7, 07/11/2026) : les codes personnels
      // des candidats importes, pour le meme lecteur que l'import.
      if (importer && ref.watch(portInvitationsPersonnellesProvider) != null)
        EntreeAction(
          libelle: t.candidatsFlux.invitationsPersonnelles.lien,
          onChoix: () => ouvrirFeuilleInvitationsPersonnelles(context),
        ),
      if (importer)
        EntreeAction(
          libelle: t.candidatsFlux.importFormulaires.lienEntree,
          onChoix: () => unawaited(
            context.push<void>(RoutesCandidatsFlux.importFormulaires),
          ),
        ),
    ];

    // BE-LISTE-2 : trois rangees au plus avant le premier nom. Le titre EST le
    // selecteur de section (le mot n'apparait qu'une fois), plus « Outils » ;
    // la recherche et deux icones, « Filtres » et « Trier » ; les files.
    final List<FileCandidatures> files = filesDe(
      attentes: attentes,
      alertes: reference?.compteursAlertes ?? const CompteursAlertes(),
      totalToutes: _totalToutes,
      maintenant: DateTime.now(),
      compteurNouveaux: reference?.compteurNouveaux ?? 0,
    );
    // VU-UNE-FOIS : le bandeau se voit une seule fois dans la vie du compte
    // (serveur, aucune memoire d'appareil). Cache tant que le serveur n'a pas
    // repondu : il ne clignote jamais pour un compte qui l'a deja ferme.
    final bool lectureComprise = ref
        .watch(vusProvider)
        .maybeWhen(
          data: (Set<String> vus) => vus.contains(ClesVu.deuxCotes),
          orElse: () => true,
        );
    final Widget? menuOutils = outils.isEmpty
        ? null
        : MenuActions(
            key: CandidaturesPage.cleOutils,
            libelle: t.recrutement.file.outilsDe,
            icone: AppIcons.reglages,
            actions: outils,
          );

    return PageShell(
      key: CandidaturesPage.clePage,
      // La page n'a pas de grand titre : le selecteur de section en tient lieu
      // (sur ordinateur, le panneau porte deja les sections).
      // La barre du lot, seulement avec une selection, collee en bas. Ses
      // operations sont compactes et non pleines (K-56) : sans selection,
      // aucun bouton plein.
      actions: gestes.enSelection && _retenues.isNotEmpty
          ? _barreLot(_derniere, caps, horsLigne)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Rangee 1 (revision du 16/11, directeur : « libere cette place ») :
          // le titre-selecteur, la loupe, « Filtres », « Trier » et « Outils »
          // sur une seule rangee. Le champ de recherche ne s'ouvre qu'au toucher
          // de la loupe. A texte agrandi (au-dela de 130 %), les icones passent
          // sous le titre pour que rien ne soit coupe.
          LayoutBuilder(
            builder: (BuildContext contexte, BoxConstraints contraintes) {
              final Widget titre = Semantics(
                header: true,
                label: r.titre,
                // BE-2b : l'associe ne voit que cette page ; les autres
                // pages de Personnes ne lui sont pas proposees.
                child: associe
                    ? SousNavigationDomaine(
                        onglets: <({String libelle, String chemin})>[
                          (
                            libelle: r.titre,
                            chemin: Routes.adminPersonnesCandidatures,
                          ),
                        ],
                        indexActif: 0,
                      )
                    : SousNavigationDomaine(
                        onglets: ongletsPersonnes(),
                        indexActif: 2,
                      ),
              );
              final List<Widget> icones = <Widget>[
                if (commandes) _boutonRecherche(),
                if (commandes) _boutonFiltres(() => files, caps),
                if (commandes) _boutonTri(),
              ];
              // Les icones de 48 et le titre entier ne tiennent sur une rangee
              // que si la place suffit (le mot « Candidatures » veut environ
              // 176 : en dessous, il serait coupe au milieu d'un mot). Plus
              // etroit, ou a texte agrandi (au-dela de 130 %), le titre garde
              // sa rangee avec « Outils », et les trois icones passent juste
              // dessous.
              final double besoin =
                  _largeurTitre +
                  AppTouchTarget.standard *
                      (icones.length + (menuOutils == null ? 0 : 1));
              final bool uneRangee =
                  contraintes.maxWidth >= besoin &&
                  MediaQuery.textScalerOf(contexte).scale(1) <= 1.3;
              if (uneRangee) {
                return Row(
                  children: <Widget>[
                    Expanded(child: titre),
                    ...icones,
                    ?menuOutils,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: titre),
                      ?menuOutils,
                    ],
                  ),
                  if (icones.isNotEmpty) ...<Widget>[
                    Ecart.vXs,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: icones,
                    ),
                  ],
                ],
              );
            },
          ),
          Ecart.vSm,
          if (commandes && _rechercheVisible) ...<Widget>[
            Semantics(
              label: r.recherche,
              child: ChampRecherche(
                cleChamp: const ValueKey<String>('candidatures-recherche'),
                cleEffacer: const ValueKey<String>(
                  'candidatures-recherche-effacer',
                ),
                controleur: _recherche,
                autofocus: true,
                // Un mot court dans le champ : le libelle complet reste dit aux
                // lecteurs d'ecran (`Semantics` ci-dessus).
                libelle: t.recrutement.file.rechercher,
                compact: true,
                aide: r.rechercheAide,
                onChange: _chercher,
                onValider: _chercherTout,
              ),
            ),
            Ecart.vSm,
          ],
          // L'exception de lecture du super-admin se dit en tete, quand le
          // serveur la rend active (jamais deduite du role) ; « J'ai compris »
          // la fait disparaitre pour de bon (aucune icone de rappel).
          if (caps.peutLireHorsGenre && !lectureComprise) ...<Widget>[
            BandeauAttention(
              key: const ValueKey<String>('candidatures-exception'),
              titre: r.exception.titre,
              message: r.exception.message,
              action: LienFleche(
                key: CandidaturesPage.cleJaiCompris,
                libelle: t.recrutement.file.jaiCompris,
                fleche: false,
                legende: true,
                onPress: () => unawaited(
                  ref.read(vusProvider.notifier).marquer(ClesVu.deuxCotes),
                ),
              ),
            ),
            Ecart.vSm,
          ],
          // SALLE2-ENTRETIEN (directeur, 14/11/2026) : les entretiens du jour
          // et leur porte, en tete de la file.
          const EntretiensDuJour(ficheOuverte: true),
          if (_ouverture != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Row(
                key: CandidaturesPage.cleOuverture,
                children: <Widget>[
                  const SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Ecart.hSm,
                  Flexible(
                    child: TexteSansCoupure(
                      r.liste.ouverture(nom: _ouverture!),
                      style: AppPalette.of(context).inkMuted.applyTo(
                        Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Ecart.vSm,
          ],
          if (_echecLigne != null) ...<Widget>[
            BandeauAttention(
              key: CandidaturesPage.cleEchecLigne,
              titre: r.liste.titreGesteNonFait,
              message: _echecLigne!,
            ),
            Ecart.vSm,
          ],
          if (_retour != null) ...<Widget>[
            LocalFeedback(key: CandidaturesPage.cleRetourLot, message: _retour),
            Ecart.vSm,
          ],
          if (commandes) ...<Widget>[
            // Rangee 2 : le menu « File ».
            _zoneFiles(files),
            Ecart.vMd,
            _ligneNombre(reference, selectionPossible: selectionPossible),
            Ecart.vMd,
          ],
          BlocAsynchrone<PageCandidatures>(
            key: const ValueKey<String>('candidatures-bloc'),
            valeur: valeur,
            squelette: const Skeleton.liste(lignes: 4),
            onReessayer: _relire,
            estVide: (PageCandidatures p) => p.total == 0 && _filtre.estVide,
            vide: EmptyState(
              key: const ValueKey<String>('candidatures-vide'),
              message: r.vide,
              invitation: r.videDetail,
              // Rien a faire pour la direction : le constat et la raison,
              // sans bouton.
              registre: RegistreVide.subi,
              icone: AppIcons.dossiers,
            ),
            erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
                _etatErreur(erreur, reessayer, horsLigne),
            construire: (PageCandidatures page) => _contenu(page, gestes),
          ),
        ],
      ),
    );
  }
}
