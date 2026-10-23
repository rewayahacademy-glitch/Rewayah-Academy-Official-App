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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/admin_domaine.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/recrutement/port_invitations_comptable.dart';
import '../../core/recrutement/port_invitations_enseignant.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/barre_selection.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/controle_segmente.dart' show Segment;
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import 'carte_alertes.dart';
import 'libelles_candidatures.dart';
import 'ligne_candidature.dart';

/// L'ecran « Candidatures ».
class CandidaturesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  ///
  /// [ouvrirCandidature] mene au detail d'une candidature (`ADM-21`) et
  /// [agirSurSelection] a l'action groupee (`ADM-22`). Ces deux ecrans ne sont
  /// pas construits : tant que leur destination n'est pas donnee, la ligne n'est
  /// pas pressable hors selection, et le mode selection n'est pas offert (ni le
  /// lien « Selectionner », ni la barre : une selection sans action possible
  /// n'a pas de sens). Aucune destination n'est inventee.
  const CandidaturesPage({
    super.key,
    this.ouvrirCandidature,
    this.agirSurSelection,
  });

  /// Ouvre une candidature, ou `null` : la ligne ne s'ouvre pas.
  final void Function(LigneCandidature ligne)? ouvrirCandidature;

  /// Mene a l'action groupee avec les identifiants retenus, ou `null`.
  final void Function(List<String> identifiants)? agirSurSelection;

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('candidatures-page');

  @override
  ConsumerState<CandidaturesPage> createState() => _CandidaturesPageEtat();
}

class _CandidaturesPageEtat extends ConsumerState<CandidaturesPage> {
  /// Le filtre courant : recherche, etape, etat, issue, pause, versement, pays.
  FiltreCandidatures _filtre = const FiltreCandidatures();

  /// Le tri, fait au serveur.
  TriCandidatures _tri = TriCandidatures.activite;

  /// La page courante, a partir de 1. Revient a 1 a chaque changement de
  /// filtre ou de tri.
  int _page = 1;

  /// La derniere page lue : ses compteurs (toute la portee, sans les autres
  /// filtres) restent affiches pendant qu'une autre page se charge.
  PageCandidatures? _derniere;

  final TextEditingController _recherche = TextEditingController();
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

  /// Les identifiants retenus, gardes d'une page a l'autre.
  final Set<String> _retenues = <String>{};

  @override
  void dispose() {
    _attenteSaisie?.cancel();
    _recherche.dispose();
    super.dispose();
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

  void _filtrer(FiltreCandidatures filtre) => setState(() {
    _filtre = filtre;
    _page = 1;
  });

  void _effacer() {
    _attenteSaisie?.cancel();
    _recherche.clear();
    _filtrer(_filtre.efface);
  }

  void _relire() => ref
    ..invalidate(pageCandidaturesProvider)
    ..invalidate(capacitesCandidaturesProvider);

  void _allerAPage(int numero) {
    setState(() => _page = numero);
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
    _enSelection = !_enSelection;
    if (!_enSelection) _retenues.clear();
  });

  // --- Filtres ------------------------------------------------------------

  Widget _filtres(PageCandidatures reference, CapacitesCandidatures caps) {
    final f = t.admin.candidatures.filtres;
    FilterPill pastille(
      EtapeCandidature? etape,
      String libelle,
      String cle,
    ) => FilterPill(
      key: ValueKey<String>(cle),
      libelle: libelle,
      compteur: etape == null ? null : reference.compteursEtapes[etape],
      retenue: _filtre.etape == etape,
      onPress: () => _filtrer(
        _filtre.avec(etape: () => _filtre.etape == etape ? null : etape),
      ),
    );

    EntreeFiltre<T> tous<T>() =>
        EntreeFiltre<T>(valeur: null, libelle: f.tous);

    final List<PaysIso> pays = <PaysIso>[...paysIso]
      ..sort((PaysIso a, PaysIso b) => formeDeRecherche(a.nom).compareTo(
        formeDeRecherche(b.nom),
      ));

    return RangeeFiltres(
      filtres: <Widget>[
        pastille(null, f.toutes, 'candidatures-filtre-toutes'),
        // « Garder pour suivi » attend la reponse du directeur (CONS 0.3) :
        // tant que le serveur ne l'ouvre pas, ni la puce ni le mot ne sont
        // rendus.
        if (caps.peutGarderPourSuivi)
          pastille(
            EtapeCandidature.recue,
            f.gardees,
            'candidatures-filtre-gardees',
          ),
        pastille(
          EtapeCandidature.invitee,
          f.invitees,
          'candidatures-filtre-invitees',
        ),
        pastille(
          EtapeCandidature.prequalification,
          t.recrutement.salles.examen,
          'candidatures-filtre-examen',
        ),
        pastille(
          EtapeCandidature.verifications,
          t.recrutement.salles.verification,
          'candidatures-filtre-verification',
        ),
        pastille(
          EtapeCandidature.confirmee,
          t.recrutement.salles.prets,
          'candidatures-filtre-prets',
        ),
        MenuFiltre<EtatCandidature>(
          key: const ValueKey<String>('candidatures-filtre-etat'),
          libelle: f.etat,
          valeur: _filtre.etat,
          entrees: <EntreeFiltre<EtatCandidature>>[
            tous<EtatCandidature>(),
            for (final EtatCandidature e in EtatCandidature.values)
              EntreeFiltre<EtatCandidature>(valeur: e, libelle: libelleEtat(e)),
          ],
          onChoix: (EtatCandidature? e) => _filtrer(_filtre.avec(etat: () => e)),
        ),
        MenuFiltre<IssueCandidature>(
          key: const ValueKey<String>('candidatures-filtre-issue'),
          libelle: f.issue,
          valeur: _filtre.issue,
          entrees: <EntreeFiltre<IssueCandidature>>[
            tous<IssueCandidature>(),
            for (final IssueCandidature i in IssueCandidature.values)
              EntreeFiltre<IssueCandidature>(
                valeur: i,
                libelle: libelleIssue(i),
              ),
          ],
          onChoix: (IssueCandidature? i) =>
              _filtrer(_filtre.avec(issue: () => i)),
        ),
        MenuFiltre<bool>(
          key: const ValueKey<String>('candidatures-filtre-pause'),
          libelle: f.pause,
          valeur: _filtre.enPause,
          entrees: <EntreeFiltre<bool>>[
            tous<bool>(),
            EntreeFiltre<bool>(
              valeur: true,
              libelle: t.admin.candidatures.etats.enPause,
            ),
            EntreeFiltre<bool>(valeur: false, libelle: f.sansPause),
          ],
          onChoix: (bool? p) => _filtrer(_filtre.avec(enPause: () => p)),
        ),
        MenuFiltre<EtatVersement>(
          key: const ValueKey<String>('candidatures-filtre-versement'),
          libelle: f.versement,
          valeur: _filtre.paiement,
          entrees: <EntreeFiltre<EtatVersement>>[
            tous<EtatVersement>(),
            for (final EtatVersement v in EtatVersement.values)
              EntreeFiltre<EtatVersement>(
                valeur: v,
                libelle: libelleVersement(v),
              ),
          ],
          onChoix: (EtatVersement? v) =>
              _filtrer(_filtre.avec(paiement: () => v)),
        ),
        MenuFiltre<String>(
          key: const ValueKey<String>('candidatures-filtre-pays'),
          libelle: f.pays,
          valeur: _filtre.paysResidence,
          entrees: <EntreeFiltre<String>>[
            tous<String>(),
            for (final PaysIso p in pays)
              EntreeFiltre<String>(valeur: p.code, libelle: p.nom),
          ],
          onChoix: (String? p) => _filtrer(_filtre.avec(paysResidence: () => p)),
        ),
      ],
    );
  }

  // --- Liste --------------------------------------------------------------

  Widget _barreListe(PageCandidatures page, {required bool selectionPossible}) {
    final r = t.admin.candidatures;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      key: _cleListe,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Semantics(
              header: true,
              liveRegion: true,
              child: TexteSansCoupure(
                r.total(n: page.total),
                key: const ValueKey<String>('candidatures-total'),
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
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
                onPress: _basculerSelection,
              ),
          ],
        ),
        Ecart.vMd,
        // Le tri est un choix ferme de deux valeurs, rendu par le composant
        // unique des choix segmentes (menu quand le texte agrandi ne tient
        // plus) : tout est visible, rien n'est tronque. Il part au serveur.
        SelecteurSection<TriCandidatures>(
          key: const ValueKey<String>('candidatures-tri'),
          libelle: r.tri.titre,
          valeur: _tri,
          sections: <Segment<TriCandidatures>>[
            Segment<TriCandidatures>(
              valeur: TriCandidatures.activite,
              libelle: r.tri.activite,
            ),
            Segment<TriCandidatures>(
              valeur: TriCandidatures.recente,
              libelle: r.tri.reception,
            ),
          ],
          onChange: (TriCandidatures choisi) => setState(() {
            _tri = choisi;
            _page = 1;
          }),
        ),
      ],
    );
  }

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
            onPrecedent: page.page > 1 ? () => _allerAPage(page.page - 1) : null,
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
    if (valeur.hasValue) _derniere = valeur.requireValue;
    final PageCandidatures? reference = valeur.value ?? _derniere;
    final CapacitesCandidatures caps =
        ref.watch(capacitesCandidaturesProvider).value ??
        CapacitesCandidatures.aucune;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final r = t.admin.candidatures;

    // Rien du tout dans la portee du lecteur (aucun filtre, zero candidature) :
    // ni alertes, ni recherche, ni filtres, seulement le constat.
    final bool porteeVide =
        valeur.hasValue && valeur.requireValue.total == 0 && _filtre.estVide;
    final bool commandes = reference != null && !porteeVide;

    // Le mode selection n'existe que s'il peut aboutir : le serveur ouvre
    // l'action en lot (capacite lue) ET `ADM-22` donne une destination. Sans
    // l'un des deux, ni le lien « Selectionner » ni la barre ne sont rendus :
    // une selection sur laquelle on ne peut rien faire n'est pas offerte.
    final void Function(List<String> identifiants)? destination =
        widget.agirSurSelection;
    final bool selectionPossible = caps.peutAgirEnLot && destination != null;

    final GestesLigne gestes = GestesLigne(
      enSelection: _enSelection && selectionPossible,
      retenues: _retenues,
      basculer: _basculerLigne,
      ouvrir: widget.ouvrirCandidature,
    );

    final bool invitations =
        ref.watch(portInvitationsEnseignantProvider) != null ||
        ref.watch(portInvitationsComptableProvider) != null;

    final VoidCallback? agir = destination == null || horsLigne
        ? null
        : () => destination(_retenues.toList());

    return PageShell(
      key: CandidaturesPage.clePage,
      titre: r.titre,
      sousTitre: r.sousTitre,
      entete: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 2),
          // L'exception de lecture du super-admin se dit en tete, quand le
          // serveur la rend active (jamais deduite du role).
          if (caps.peutLireHorsGenre)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: BandeauAttention(
                key: const ValueKey<String>('candidatures-exception'),
                titre: r.exception.titre,
                message: r.exception.message,
              ),
            ),
        ],
      ),
      // Une seule zone pleine, et seulement avec une selection : la barre
      // collee en bas. Sans selection, aucun bouton plein.
      actions: gestes.enSelection && _retenues.isNotEmpty
          ? BarreSelection(
              titre: r.selection.retenues(n: _retenues.length),
              phrase: horsLigne ? r.selection.horsLigne : r.selection.phrase,
              libelleRelacher: r.selection.relacher,
              onRelacher: _relacherTout,
              libelleAction: r.selection.agir,
              // Hors ligne : l'action n'est pas rendue, la phrase dit pourquoi
              // (jamais un bouton grise).
              onAction: agir,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // CAND-F01 : la page des invitations (l'invitation d'un enseignant
          // ou d'un comptable, la revocation) a perdu son onglet. Le lien est
          // en tete, rendu dans tous les etats (file vide, en erreur, serveur
          // pas encore branche) : c'est le seul chemin vers elle. Il n'existe
          // que si l'un de ses deux ports est servi.
          if (invitations) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LienFleche(
                key: const ValueKey<String>('candidatures-invitations'),
                libelle: t.recrutement.invitations.onglet,
                alignerEnFin: true,
                onPress: () => context.go(Routes.adminPersonnesInvitations),
              ),
            ),
            Ecart.vSm,
          ],
          if (commandes) ...<Widget>[
            CarteAlertes(compteurs: reference.compteursAlertes),
            Ecart.vXxl,
            ChampRecherche(
              cleChamp: const ValueKey<String>('candidatures-recherche'),
              cleEffacer: const ValueKey<String>(
                'candidatures-recherche-effacer',
              ),
              controleur: _recherche,
              libelle: r.recherche,
              aide: r.rechercheAide,
              onChange: _chercher,
              onValider: _chercherTout,
            ),
            Ecart.vMd,
            _filtres(reference, caps),
            Ecart.vLg,
            _barreListe(reference, selectionPossible: selectionPossible),
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
