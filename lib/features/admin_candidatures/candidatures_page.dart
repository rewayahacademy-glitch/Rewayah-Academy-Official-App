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
import '../../core/candidature/creneaux_direction.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/modeles_lot_candidatures.dart';
import '../../core/candidature/port_autres_competences.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/candidature/port_invitations_personnelles.dart';
import '../../core/candidature/port_prevenir_candidats.dart';
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
import '../../core/widgets/action_principale.dart';
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
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../admin_candidature/feuille_geste.dart';
import '../admin_candidature/gestes_proposes.dart';
import '../admin_candidature/libelles_candidature.dart';
import '../admin_import_formulaires/routes_candidats_flux.dart';
import '../talents/libelles_talents.dart';
import 'carte_alertes.dart';
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
  const CandidaturesPage({super.key, this.ouvrirCandidature});

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
  }

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

  // --- Filtres ------------------------------------------------------------

  Widget _filtres(PageCandidatures reference, CapacitesCandidatures caps) {
    final f = t.admin.candidatures.filtres;
    FilterPill pastille(EtapeCandidature? etape, String libelle, String cle) =>
        FilterPill(
          key: ValueKey<String>(cle),
          libelle: libelle,
          compteur: etape == null ? null : reference.compteursEtapes[etape],
          retenue: _filtre.etape == etape,
          onPress: () => _filtrer(
            _filtre.avec(etape: () => _filtre.etape == etape ? null : etape),
          ),
        );

    EntreeFiltre<T> tous<T>() => EntreeFiltre<T>(valeur: null, libelle: f.tous);

    final List<PaysIso> pays = <PaysIso>[...paysIso]
      ..sort(
        (PaysIso a, PaysIso b) =>
            formeDeRecherche(a.nom).compareTo(formeDeRecherche(b.nom)),
      );

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
          onChoix: (EtatCandidature? e) =>
              _filtrer(_filtre.avec(etat: () => e)),
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
          onChoix: (String? p) =>
              _filtrer(_filtre.avec(paysResidence: () => p)),
        ),
        ..._filtresCompetences(tous),
      ],
    );
  }

  /// Les quatre axes des autres competences (CAND-07, « Vos autres talents ») :
  /// le domaine (une famille, ou une competence du catalogue), le niveau minimum,
  /// la disponibilite et l'accord d'etre contacte. Le serveur ne rend ces
  /// personnes que si elles ont repondu ; aucune note, aucun classement.
  ///
  /// Les familles sont une liste fermee que l'application nomme : le menu du
  /// domaine marche sans le catalogue. Les competences s'y ajoutent des que la
  /// direction lit le catalogue (le sien, complet, desactivees comprises).
  List<Widget> _filtresCompetences(EntreeFiltre<T> Function<T>() tous) {
    final f = t.admin.candidatures.filtres.talents;
    final CatalogueCompetences? catalogue = ref
        .watch(catalogueCompetencesProvider)
        .value;
    final List<EntreeFiltre<String>> domaines = <EntreeFiltre<String>>[
      tous<String>(),
      for (final FamilleCompetence famille
          in FamilleCompetence.values) ...<EntreeFiltre<String>>[
        // La famille « autre » n'a qu'une competence, du meme nom : une seule
        // entree.
        if (famille != FamilleCompetence.autre)
          EntreeFiltre<String>(
            valeur: famille.valeurSql,
            libelle: f.familleToutes(famille: titreFamille(famille)),
          ),
        for (final EntreeCatalogue e
            in catalogue?.competences ?? const <EntreeCatalogue>[])
          if (e.familleCode == famille.valeurSql)
            EntreeFiltre<String>(
              valeur: e.code,
              libelle: nomDomaineFiltre(e.code, catalogue: catalogue),
            ),
      ],
    ];
    return <Widget>[
      MenuFiltre<String>(
        key: const ValueKey<String>('candidatures-filtre-competence'),
        libelle: f.domaine,
        valeur: _filtre.competenceDomaine,
        entrees: domaines,
        onChoix: (String? d) =>
            _filtrer(_filtre.avec(competenceDomaine: () => d)),
      ),
      MenuFiltre<NiveauCompetence>(
        key: const ValueKey<String>('candidatures-filtre-competence-niveau'),
        libelle: f.niveau,
        valeur: _filtre.competenceNiveauMin,
        entrees: <EntreeFiltre<NiveauCompetence>>[
          tous<NiveauCompetence>(),
          EntreeFiltre<NiveauCompetence>(
            valeur: NiveauCompetence.experience,
            libelle: f.niveauExperience,
          ),
          EntreeFiltre<NiveauCompetence>(
            valeur: NiveauCompetence.metier,
            libelle: f.niveauMetier,
          ),
        ],
        onChoix: (NiveauCompetence? n) =>
            _filtrer(_filtre.avec(competenceNiveauMin: () => n)),
      ),
      MenuFiltre<DisponibiliteMission>(
        key: const ValueKey<String>(
          'candidatures-filtre-competence-disponibilite',
        ),
        libelle: f.disponibilite,
        valeur: _filtre.competenceDisponibilite,
        entrees: <EntreeFiltre<DisponibiliteMission>>[
          tous<DisponibiliteMission>(),
          for (final DisponibiliteMission d in DisponibiliteMission.values)
            EntreeFiltre<DisponibiliteMission>(
              valeur: d,
              libelle: libelleDisponibilite(d),
            ),
        ],
        onChoix: (DisponibiliteMission? d) =>
            _filtrer(_filtre.avec(competenceDisponibilite: () => d)),
      ),
      MenuFiltre<bool>(
        key: const ValueKey<String>('candidatures-filtre-competence-accord'),
        libelle: f.accord,
        valeur: _filtre.competenceAccord,
        entrees: <EntreeFiltre<bool>>[
          tous<bool>(),
          EntreeFiltre<bool>(valeur: true, libelle: f.accordDonne),
          EntreeFiltre<bool>(valeur: false, libelle: f.accordAbsent),
        ],
        onChoix: (bool? a) => _filtrer(_filtre.avec(competenceAccord: () => a)),
      ),
    ];
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
          if (prevenir) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LienFleche(
                key: const ValueKey<String>('candidatures-prevenir'),
                libelle: t.candidatsFlux.prevenir.lien,
                alignerEnFin: true,
                onPress: () => ouvrirFeuillePrevenir(context),
              ),
            ),
            Ecart.vSm,
          ],
          if (creneaux) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LienFleche(
                key: const ValueKey<String>('candidatures-creneaux'),
                libelle: t.admin.candidatures.creneaux.lien,
                alignerEnFin: true,
                onPress: () =>
                    context.go(Routes.adminPersonnesCreneauxEntretien),
              ),
            ),
            Ecart.vSm,
          ],
          // INVITATIONS-PERSONNELLES (lot 7, 07/11/2026) : les codes
          // personnels des candidats importes, pour le meme lecteur que
          // l'import (super administrateur, double verification au geste).
          if (importer &&
              ref.watch(portInvitationsPersonnellesProvider) !=
                  null) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LienFleche(
                key: const ValueKey<String>('candidatures-codes-personnels'),
                libelle: t.candidatsFlux.invitationsPersonnelles.lien,
                alignerEnFin: true,
                onPress: () => ouvrirFeuilleInvitationsPersonnelles(context),
              ),
            ),
            Ecart.vSm,
          ],
          if (importer) ...<Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LienFleche(
                key: const ValueKey<String>('candidatures-importer'),
                libelle: t.candidatsFlux.importFormulaires.lienEntree,
                alignerEnFin: true,
                onPress: () =>
                    context.push<void>(RoutesCandidatsFlux.importFormulaires),
              ),
            ),
            Ecart.vSm,
          ],
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
